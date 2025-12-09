import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/db_helper.dart';
import 'package:sipesantren/core/models/penilaian_model.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sqflite/sqflite.dart'; // Added import
import 'package:uuid/uuid.dart';

class PenilaianRepository {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  PenilaianRepository(this._dbHelper, this._firestore);

  // --- Tahfidz ---
  Future<List<PenilaianTahfidz>> getTahfidzBySantri(String santriId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penilaian_tahfidz',
      where: 'santriId = ? AND syncStatus != 2', // Exclude deleted
      whereArgs: [santriId],
      orderBy: 'minggu DESC',
    );
    return List.generate(maps.length, (i) => PenilaianTahfidz.fromMap(maps[i]));
  }

  Future<void> addPenilaianTahfidz(PenilaianTahfidz data) async {
    final db = await _dbHelper.database;
    final newData = PenilaianTahfidz(
      id: data.id.isEmpty ? _uuid.v4() : data.id,
      santriId: data.santriId,
      minggu: data.minggu,
      surah: data.surah,
      ayatSetor: data.ayatSetor,
      targetAyat: data.targetAyat,
      tajwid: data.tajwid,
      syncStatus: 1, // dirty
    );
    
    await db.insert(
      'penilaian_tahfidz',
      newData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  // --- Mapel ---
  Future<List<PenilaianMapel>> getMapelBySantri(String santriId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penilaian_mapel',
      where: 'santriId = ? AND syncStatus != 2',
      whereArgs: [santriId],
    );
    return List.generate(maps.length, (i) => PenilaianMapel.fromMap(maps[i]));
  }

  Future<void> addPenilaianMapel(PenilaianMapel data) async {
    final db = await _dbHelper.database;
    final newData = PenilaianMapel(
      id: data.id.isEmpty ? _uuid.v4() : data.id,
      santriId: data.santriId,
      mapel: data.mapel,
      formatif: data.formatif,
      sumatif: data.sumatif,
      syncStatus: 1,
    );
    await db.insert(
      'penilaian_mapel',
      newData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  // --- Akhlak ---
  Future<List<PenilaianAkhlak>> getAkhlakBySantri(String santriId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penilaian_akhlak',
      where: 'santriId = ? AND syncStatus != 2',
      whereArgs: [santriId],
    );
    return List.generate(maps.length, (i) => PenilaianAkhlak.fromMap(maps[i]));
  }

  Future<void> addPenilaianAkhlak(PenilaianAkhlak data) async {
    final db = await _dbHelper.database;
    final newData = PenilaianAkhlak(
      id: data.id.isEmpty ? _uuid.v4() : data.id,
      santriId: data.santriId,
      disiplin: data.disiplin,
      adab: data.adab,
      kebersihan: data.kebersihan,
      kerjasama: data.kerjasama,
      catatan: data.catatan,
      syncStatus: 1,
    );
    await db.insert(
      'penilaian_akhlak',
      newData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  // --- Kehadiran ---
  Future<List<Kehadiran>> getKehadiranBySantri(String santriId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kehadiran',
      where: 'santriId = ? AND syncStatus != 2',
      whereArgs: [santriId],
      orderBy: 'tanggal DESC',
    );
    return List.generate(maps.length, (i) => Kehadiran.fromMap(maps[i]));
  }

  Future<void> addKehadiran(Kehadiran data) async {
    final db = await _dbHelper.database;
    final newData = Kehadiran(
      id: data.id.isEmpty ? _uuid.v4() : data.id,
      santriId: data.santriId,
      tanggal: data.tanggal,
      status: data.status,
      syncStatus: 1,
    );
    await db.insert(
      'kehadiran',
      newData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  // --- Sync Logic ---
  Future<void> syncPendingChanges() async {
    final db = await _dbHelper.database;
    await _syncTable(db, 'penilaian_tahfidz', 'penilaian_tahfidz', (map) => PenilaianTahfidz.fromMap(map).toFirestore(), (map) => map['id']);
    await _syncTable(db, 'penilaian_mapel', 'penilaian_mapel', (map) => PenilaianMapel.fromMap(map).toFirestore(), (map) => map['id']);
    await _syncTable(db, 'penilaian_akhlak', 'penilaian_akhlak', (map) => PenilaianAkhlak.fromMap(map).toFirestore(), (map) => map['id']);
    await _syncTable(db, 'kehadiran', 'kehadiran', (map) => Kehadiran.fromMap(map).toFirestore(), (map) => map['id']);
  }

  Future<void> _syncTable(
    var db, 
    String tableName, 
    String collectionName, 
    Map<String, dynamic> Function(Map<String, dynamic>) toFirestore,
    String Function(Map<String, dynamic>) getId,
  ) async {
    final List<Map<String, dynamic>> dirtyRecords = await db.query(
      tableName,
      where: 'syncStatus != ?',
      whereArgs: [0],
    );

    if (dirtyRecords.isEmpty) return;

    final batch = _firestore.batch();
    List<String> idsToUpdate = [];
    List<String> idsToDelete = [];

    for (var record in dirtyRecords) {
      final id = getId(record);
      final syncStatus = record['syncStatus'];
      final docRef = _firestore.collection(collectionName).doc(id);

      if (syncStatus == 2) { // Deleted
        batch.delete(docRef);
        idsToDelete.add(id);
      } else { // Created/Updated
        batch.set(docRef, toFirestore(record), SetOptions(merge: true));
        idsToUpdate.add(id);
      }
    }

    try {
      await batch.commit();
      
      final batchUpdate = db.batch();
      for (var id in idsToUpdate) {
        batchUpdate.update(tableName, {'syncStatus': 0}, where: 'id = ?', whereArgs: [id]);
      }
      for (var id in idsToDelete) {
        batchUpdate.delete(tableName, where: 'id = ?', whereArgs: [id]);
      }
      await batchUpdate.commit(noResult: true);
    } catch (e) {
      // Sync failed
    }
  }

  // Optional: Fetch from Firestore (simplified)
  Future<void> fetchFromFirestore(String santriId) async {
    // Implementation would involve querying all collections for santriId and upserting locally
    // Skipping for brevity, but essential for multi-device sync
  }
}

final penilaianRepositoryProvider = Provider((ref) => PenilaianRepository(
  DatabaseHelper(),
  ref.watch(firestoreProvider),
));
