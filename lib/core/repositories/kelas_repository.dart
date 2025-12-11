import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/db_helper.dart';
import 'package:sipesantren/core/models/kelas_model.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class KelasRepository {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final String _collection = 'kelas';
  final Uuid _uuid = const Uuid();

  KelasRepository(this._dbHelper, this._firestore);

  Future<List<KelasModel>> getKelasList() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kelas',
      where: 'syncStatus != ?',
      whereArgs: [2],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => KelasModel.fromMap(maps[i]));
  }
  
  Future<KelasModel?> getKelasById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kelas',
      where: 'id = ? AND syncStatus != ?',
      whereArgs: [id, 2],
    );
    if (maps.isNotEmpty) {
      return KelasModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addKelas(KelasModel kelas) async {
    final db = await _dbHelper.database;
    final newKelas = kelas.copyWith(
      id: kelas.id.isEmpty ? _uuid.v4() : kelas.id,
      syncStatus: 1,
    );
    
    await db.insert(
      'kelas',
      newKelas.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  Future<void> updateKelas(KelasModel kelas) async {
    final db = await _dbHelper.database;
    final updatedKelas = kelas.copyWith(syncStatus: 1);

    await db.update(
      'kelas',
      updatedKelas.toMap(),
      where: 'id = ?',
      whereArgs: [kelas.id],
    );
    syncPendingChanges();
  }

  Future<void> deleteKelas(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'kelas',
      {'syncStatus': 2},
      where: 'id = ?',
      whereArgs: [id],
    );
    syncPendingChanges();
  }

  Future<void> syncPendingChanges() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> dirtyRecords = await db.query(
      'kelas',
      where: 'syncStatus != ?',
      whereArgs: [0],
    );

    if (dirtyRecords.isEmpty) return;

    final batch = _firestore.batch();
    List<String> idsToUpdate = [];
    List<String> idsToDelete = [];

    for (var record in dirtyRecords) {
      final kelas = KelasModel.fromMap(record);
      final docRef = _firestore.collection(_collection).doc(kelas.id);
      
      if (kelas.syncStatus == 2) {
        batch.delete(docRef);
        idsToDelete.add(kelas.id);
      } else {
        final data = kelas.toFirestore();
        batch.set(docRef, data, SetOptions(merge: true));
        idsToUpdate.add(kelas.id);
      }
    }

    try {
      await batch.commit();
      final batchUpdate = await _dbHelper.database;
      final batchSql = batchUpdate.batch();

      for (var id in idsToUpdate) {
        batchSql.update('kelas', {'syncStatus': 0}, where: 'id = ?', whereArgs: [id]);
      }
      for (var id in idsToDelete) {
        batchSql.delete('kelas', where: 'id = ?', whereArgs: [id]);
      }
      await batchSql.commit(noResult: true);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> fetchFromFirestore() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (var doc in snapshot.docs) {
        final kelas = KelasModel.fromFirestore(doc);
        final localCopy = await db.query('kelas', where: 'id = ?', whereArgs: [kelas.id]);
        if (localCopy.isNotEmpty) {
           final localKelas = KelasModel.fromMap(localCopy.first);
           if (localKelas.syncStatus != 0) continue;
        }
        batch.insert('kelas', kelas.copyWith(syncStatus: 0).toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Ignore
    }
  }
}

final kelasRepositoryProvider = Provider((ref) {
  return KelasRepository(
    DatabaseHelper(),
    ref.watch(firestoreProvider),
  );
});
