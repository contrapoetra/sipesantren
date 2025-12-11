import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/db_helper.dart';
import 'package:sipesantren/core/models/aktivitas_kelas_model.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class AktivitasKelasRepository {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final String _collection = 'aktivitas_kelas';
  final Uuid _uuid = const Uuid();

  AktivitasKelasRepository(this._dbHelper, this._firestore);

  // Get Activities by Kelas
  Future<List<AktivitasKelasModel>> getActivitiesByKelas(String kelasId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'aktivitas_kelas',
      where: 'kelasId = ? AND syncStatus != ?',
      whereArgs: [kelasId, 2],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => AktivitasKelasModel.fromMap(maps[i]));
  }

  // Add Activity
  Future<void> addActivity(AktivitasKelasModel activity) async {
    final db = await _dbHelper.database;
    final newActivity = activity.copyWith(
      id: activity.id.isEmpty ? _uuid.v4() : activity.id,
      syncStatus: 1,
    );
    await db.insert(
      'aktivitas_kelas',
      newActivity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  // Delete Activity
  Future<void> deleteActivity(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'aktivitas_kelas',
      {'syncStatus': 2},
      where: 'id = ?',
      whereArgs: [id],
    );
    syncPendingChanges();
  }

  // Sync
  Future<void> syncPendingChanges() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> dirtyRecords = await db.query(
      'aktivitas_kelas',
      where: 'syncStatus != ?',
      whereArgs: [0],
    );

    if (dirtyRecords.isEmpty) return;

    final batch = _firestore.batch();
    List<String> idsToUpdate = [];
    List<String> idsToDelete = [];

    for (var record in dirtyRecords) {
      final activity = AktivitasKelasModel.fromMap(record);
      final docRef = _firestore.collection(_collection).doc(activity.id);

      if (activity.syncStatus == 2) {
        batch.delete(docRef);
        idsToDelete.add(activity.id);
      } else {
        final data = activity.toFirestore();
        batch.set(docRef, data, SetOptions(merge: true));
        idsToUpdate.add(activity.id);
      }
    }

    try {
      await batch.commit();
      final batchUpdate = db.batch();
      for (var id in idsToUpdate) {
        batchUpdate.update('aktivitas_kelas', {'syncStatus': 0}, where: 'id = ?', whereArgs: [id]);
      }
      for (var id in idsToDelete) {
        batchUpdate.delete('aktivitas_kelas', where: 'id = ?', whereArgs: [id]);
      }
      await batchUpdate.commit(noResult: true);
    } catch (e) {
      // Ignore
    }
  }

  // Fetch from Firestore
  Future<void> fetchFromFirestore(String kelasId) async {
    try {
      final snapshot = await _firestore.collection(_collection).where('kelasId', isEqualTo: kelasId).get();
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (var doc in snapshot.docs) {
        final activity = AktivitasKelasModel.fromFirestore(doc);
        final localCopy = await db.query('aktivitas_kelas', where: 'id = ?', whereArgs: [activity.id]);
        if (localCopy.isNotEmpty) {
           final localActivity = AktivitasKelasModel.fromMap(localCopy.first);
           if (localActivity.syncStatus != 0) continue;
        }
        batch.insert('aktivitas_kelas', activity.copyWith(syncStatus: 0).toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Ignore
    }
  }
}

final aktivitasKelasRepositoryProvider = Provider((ref) {
  return AktivitasKelasRepository(
    DatabaseHelper(),
    ref.watch(firestoreProvider),
  );
});
