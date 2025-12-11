import 'package:cloud_firestore/cloud_firestore.dart';

class TeachingAssignmentModel {
  final String id;
  final String kelasId;
  final String mapelId;
  final String ustadId;
  final int? syncStatus;

  TeachingAssignmentModel({
    required this.id,
    required this.kelasId,
    required this.mapelId,
    required this.ustadId,
    this.syncStatus,
  });

  factory TeachingAssignmentModel.fromMap(Map<String, dynamic> map) {
    return TeachingAssignmentModel(
      id: map['id'],
      kelasId: map['kelasId'],
      mapelId: map['mapelId'],
      ustadId: map['ustadId'],
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kelasId': kelasId,
      'mapelId': mapelId,
      'ustadId': ustadId,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  factory TeachingAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeachingAssignmentModel(
      id: doc.id,
      kelasId: data['kelasId'] ?? '',
      mapelId: data['mapelId'] ?? '',
      ustadId: data['ustadId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kelasId': kelasId,
      'mapelId': mapelId,
      'ustadId': ustadId,
    };
  }
}
