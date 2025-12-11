import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/db_helper.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sqflite/sqflite.dart'; // Added import
import 'package:uuid/uuid.dart';

class SantriRepository {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final String _collection = 'santri';
  final Uuid _uuid = const Uuid();

  SantriRepository(this._dbHelper, this._firestore);

  // 1. Get List from SQLite
  Future<List<SantriModel>> getSantriList() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'santri',
      where: 'syncStatus != ?',
      whereArgs: [2],
      orderBy: 'nama ASC',
    );
    return List.generate(maps.length, (i) => SantriModel.fromMap(maps[i]));
  }

  Future<List<SantriModel>> getSantriByKelas(String kelasId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'santri',
      where: 'kelasId = ? AND syncStatus != ?',
      whereArgs: [kelasId, 2],
      orderBy: 'nama ASC',
    );
    return List.generate(maps.length, (i) => SantriModel.fromMap(maps[i]));
  }

  Future<List<SantriModel>> getSantriByWali(String waliId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'santri',
      where: 'waliSantriId = ? AND syncStatus != ?',
      whereArgs: [waliId, 2],
      orderBy: 'nama ASC',
    );
    return List.generate(maps.length, (i) => SantriModel.fromMap(maps[i]));
  }

  // 2. Add Santri (Offline First)
  Future<void> addSantri(SantriModel santri) async {
    final db = await _dbHelper.database;
    final newSantri = santri.copyWith(
      id: santri.id.isEmpty ? _uuid.v4() : santri.id,
      syncStatus: 1, // 1 = created/updated
    );
    
    await db.insert(
      'santri',
      newSantri.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Attempt sync
    syncPendingChanges();
  }

  // 3. Update Santri (Offline First)
  Future<void> updateSantri(SantriModel santri) async {
    final db = await _dbHelper.database;
    final updatedSantri = santri.copyWith(
      syncStatus: 1, // 1 = updated
    );

    await db.update(
      'santri',
      updatedSantri.toMap(),
      where: 'id = ?',
      whereArgs: [santri.id],
    );

    // Attempt sync
    syncPendingChanges();
  }

  // 4. Delete Santri (Offline First)
  Future<void> deleteSantri(String id) async {
    final db = await _dbHelper.database;
    // Mark as deleted (status 2)
    await db.update(
      'santri',
      {'syncStatus': 2},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Attempt sync
    syncPendingChanges();
  }

  // 5. Sync Pending Changes
  Future<void> syncPendingChanges() async {
    final db = await _dbHelper.database;
    
    // Find dirty records
    final List<Map<String, dynamic>> dirtyRecords = await db.query(
      'santri',
      where: 'syncStatus != ?',
      whereArgs: [0],
    );

    if (dirtyRecords.isEmpty) return;

    final batch = _firestore.batch();
    List<String> idsToUpdate = [];
    List<String> idsToDelete = [];

    for (var record in dirtyRecords) {
      final santri = SantriModel.fromMap(record);
      final docRef = _firestore.collection(_collection).doc(santri.id);
      
      if (santri.syncStatus == 2) {
        // Delete
        batch.delete(docRef);
        idsToDelete.add(santri.id);
      } else {
        // Create or Update
        // Remove syncStatus before sending to Firestore
        final data = santri.toFirestore();
        batch.set(docRef, data, SetOptions(merge: true));
        idsToUpdate.add(santri.id);
      }
    }

    try {
      await batch.commit();

      // Update local status to 0 (synced) or delete physically if it was a delete
      final batchUpdate = await _dbHelper.database; // Re-get db just in case
      final batchSql = batchUpdate.batch();

      for (var id in idsToUpdate) {
        batchSql.update('santri', {'syncStatus': 0}, where: 'id = ?', whereArgs: [id]);
      }

      for (var id in idsToDelete) {
        batchSql.delete('santri', where: 'id = ?', whereArgs: [id]);
      }

      await batchSql.commit(noResult: true);
    } catch (e) {
      // Keep status as dirty, will retry next time
    }
  }

  // 6. Pull from Firestore (Initial Sync / Pull to Refresh)
  Future<void> fetchFromFirestore() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final db = await _dbHelper.database;
      final batch = db.batch();

      // We might want to clear local DB or merge. 
      // Strategy: Overwrite local with server data if server has it.
      // But we shouldn't overwrite unsynced local changes (status != 0).
      // For simplicity, let's assume server is truth for existing IDs.
      
      for (var doc in snapshot.docs) {
        final santri = SantriModel.fromFirestore(doc);
        // Check if we have a local dirty copy
        final localCopy = await db.query('santri', where: 'id = ?', whereArgs: [santri.id]);
        if (localCopy.isNotEmpty) {
           final localSantri = SantriModel.fromMap(localCopy.first);
           if (localSantri.syncStatus != 0) {
             // Conflict! Local has changes. Keep local changes? 
             // Or User Last Write Wins? 
             // Requirement says "antrian perubahan" (queue changes).
             // We'll skip overwriting if local is dirty.
             continue;
           }
        }
        
        batch.insert(
          'santri', 
          santri.copyWith(syncStatus: 0).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Fetch failed
    }
  }
  // 7. Get Count in Room
  Future<int> getSantriCountInRoom(String gedung, int nomor) async {
    final db = await _dbHelper.database;
    // Exclude deleted (syncStatus 2)
    final count = await db.query(
      'santri',
      columns: ['COUNT(*)'],
      where: 'kamarGedung = ? AND kamarNomor = ? AND syncStatus != 2',
      whereArgs: [gedung, nomor],
    );
    return Sqflite.firstIntValue(count) ?? 0;
  }
}

final santriRepositoryProvider = Provider((ref) {
  return SantriRepository(
    DatabaseHelper(),
    ref.watch(firestoreProvider),
  );
});
