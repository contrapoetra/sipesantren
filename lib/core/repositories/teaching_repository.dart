import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/db_helper.dart';
import 'package:sipesantren/core/models/teaching_assignment_model.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class TeachingRepository {
  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final String _collection = 'teaching_assignments';
  final Uuid _uuid = const Uuid();

  TeachingRepository(this._dbHelper, this._firestore);

  Future<List<TeachingAssignmentModel>> getAssignments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'teaching_assignments',
      where: 'syncStatus != ?',
      whereArgs: [2],
    );
    return List.generate(maps.length, (i) => TeachingAssignmentModel.fromMap(maps[i]));
  }

  Future<List<TeachingAssignmentModel>> getAssignmentsForUstad(String ustadId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'teaching_assignments',
      where: 'ustadId = ? AND syncStatus != ?',
      whereArgs: [ustadId, 2],
    );
    return List.generate(maps.length, (i) => TeachingAssignmentModel.fromMap(maps[i]));
  }
  
  Future<List<TeachingAssignmentModel>> getAssignmentsForKelas(String kelasId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'teaching_assignments',
      where: 'kelasId = ? AND syncStatus != ?',
      whereArgs: [kelasId, 2],
    );
    return List.generate(maps.length, (i) => TeachingAssignmentModel.fromMap(maps[i]));
  }

  Future<void> addAssignment(TeachingAssignmentModel assignment) async {
    final db = await _dbHelper.database;
    
    final id = assignment.id.isEmpty ? _uuid.v4() : assignment.id;
    final map = assignment.toMap();
    map['id'] = id;
    map['syncStatus'] = 1;

    await db.insert(
      'teaching_assignments',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    syncPendingChanges();
  }

  Future<void> deleteAssignment(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'teaching_assignments',
      {'syncStatus': 2},
      where: 'id = ?',
      whereArgs: [id],
    );
    syncPendingChanges();
  }

  Future<void> syncPendingChanges() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> dirtyRecords = await db.query(
      'teaching_assignments',
      where: 'syncStatus != ?',
      whereArgs: [0],
    );

    if (dirtyRecords.isEmpty) return;

    final batch = _firestore.batch();
    List<String> idsToUpdate = [];
    List<String> idsToDelete = [];

    for (var record in dirtyRecords) {
      final assignment = TeachingAssignmentModel.fromMap(record);
      final docRef = _firestore.collection(_collection).doc(assignment.id);
      
      if (assignment.syncStatus == 2) {
        batch.delete(docRef);
        idsToDelete.add(assignment.id);
      } else {
        final data = assignment.toFirestore();
        batch.set(docRef, data, SetOptions(merge: true));
        idsToUpdate.add(assignment.id);
      }
    }

    try {
      await batch.commit();
      final batchUpdate = await _dbHelper.database;
      final batchSql = batchUpdate.batch();
      for (var id in idsToUpdate) {
        batchSql.update('teaching_assignments', {'syncStatus': 0}, where: 'id = ?', whereArgs: [id]);
      }
      for (var id in idsToDelete) {
        batchSql.delete('teaching_assignments', where: 'id = ?', whereArgs: [id]);
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
        final assignment = TeachingAssignmentModel.fromFirestore(doc);
        // We need to inject the ID from doc since toFirestore/fromFirestore might not carry it cleanly
        // Actually fromFirestore sets ID.
        
        final localCopy = await db.query('teaching_assignments', where: 'id = ?', whereArgs: [assignment.id]);
        if (localCopy.isNotEmpty) {
           final localAssignment = TeachingAssignmentModel.fromMap(localCopy.first);
           if (localAssignment.syncStatus != 0) continue;
        }
        
        // Manual copyWith for syncStatus since I didn't add copyWith to the model yet (my bad)
        final map = assignment.toMap();
        map['syncStatus'] = 0;
        // Ensure ID is correct
        map['id'] = doc.id; 
        
        batch.insert('teaching_assignments', map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Ignore
    }
  }
}

final teachingRepositoryProvider = Provider((ref) {
  return TeachingRepository(
    DatabaseHelper(),
    ref.watch(firestoreProvider),
  );
});
