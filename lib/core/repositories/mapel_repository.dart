import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/db_helper.dart';
import 'package:sipesantren/core/models/mapel_model.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class MapelRepository {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  MapelRepository(this._dbHelper, this._firestore);

  // Get list from SQLite
  Future<List<MapelModel>> getMapelList() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mapel',
      where: 'syncStatus != ?',
      whereArgs: [2],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => MapelModel.fromMap(maps[i]));
  }

  // Add (Offline)
  Future<void> addMapel(MapelModel mapel) async {
    final db = await _dbHelper.database;
    final newMapel = mapel.copyWith(
      id: mapel.id.isEmpty ? _uuid.v4() : mapel.id,
      syncStatus: 1,
    );
    await db.insert(
      'mapel',
      newMapel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  // Update (Offline)
  Future<void> updateMapel(MapelModel mapel) async {
    final db = await _dbHelper.database;
    final updatedMapel = mapel.copyWith(syncStatus: 1);
    await db.update(
      'mapel',
      updatedMapel.toMap(),
      where: 'id = ?',
      whereArgs: [mapel.id],
    );
    syncPendingChanges();
  }

  // Delete (Offline)
  Future<void> deleteMapel(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'mapel',
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
      'mapel',
      where: 'syncStatus != ?',
      whereArgs: [0],
    );

    if (dirtyRecords.isEmpty) return;

    final batch = _firestore.batch();
    List<String> idsToUpdate = [];
    List<String> idsToDelete = [];

    for (var record in dirtyRecords) {
      final mapel = MapelModel.fromMap(record);
      final docRef = _firestore.collection('mapel').doc(mapel.id);

      if (mapel.syncStatus == 2) {
        batch.delete(docRef);
        idsToDelete.add(mapel.id);
      } else {
        final data = mapel.toFirestore();
        batch.set(docRef, data, SetOptions(merge: true));
        idsToUpdate.add(mapel.id);
      }
    }

    try {
      await batch.commit();
      final batchUpdate = db.batch();
      for (var id in idsToUpdate) {
        batchUpdate.update('mapel', {'syncStatus': 0}, where: 'id = ?', whereArgs: [id]);
      }
      for (var id in idsToDelete) {
        batchUpdate.delete('mapel', where: 'id = ?', whereArgs: [id]);
      }
      await batchUpdate.commit(noResult: true);
    } catch (e) {
      // print('Mapel Sync failed: $e');
    }
  }

  // Pull from Firestore
  Future<void> fetchFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('mapel').get();
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (var doc in snapshot.docs) {
        final mapel = MapelModel.fromFirestore(doc);
        // Check if we have a local dirty copy
        final localCopy = await db.query('mapel', where: 'id = ?', whereArgs: [mapel.id]);
        if (localCopy.isNotEmpty) {
           final localMapel = MapelModel.fromMap(localCopy.first);
           if (localMapel.syncStatus != 0) {
             continue; // Don't overwrite local changes
           }
        }
        
        batch.insert(
          'mapel', 
          mapel.copyWith(syncStatus: 0).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // print('Mapel Fetch failed: $e');
    }
  }
}

final mapelRepositoryProvider = Provider((ref) => MapelRepository(
  DatabaseHelper(),
  ref.watch(firestoreProvider),
));
