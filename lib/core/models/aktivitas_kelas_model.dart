import 'package:cloud_firestore/cloud_firestore.dart';

class AktivitasKelasModel {
  final String id;
  final String kelasId;
  final String type; // 'announcement', 'assignment'
  final String title;
  final String description;
  final String authorId;
  final DateTime createdAt;
  final int? syncStatus;

  AktivitasKelasModel({
    required this.id,
    required this.kelasId,
    required this.type,
    required this.title,
    required this.description,
    required this.authorId,
    required this.createdAt,
    this.syncStatus,
  });

  factory AktivitasKelasModel.fromMap(Map<String, dynamic> map) {
    return AktivitasKelasModel(
      id: map['id'],
      kelasId: map['kelasId'],
      type: map['type'],
      title: map['title'],
      description: map['description'],
      authorId: map['authorId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kelasId': kelasId,
      'type': type,
      'title': title,
      'description': description,
      'authorId': authorId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  factory AktivitasKelasModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AktivitasKelasModel(
      id: doc.id,
      kelasId: data['kelasId'] ?? '',
      type: data['type'] ?? 'announcement',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      authorId: data['authorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kelasId': kelasId,
      'type': type,
      'title': title,
      'description': description,
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AktivitasKelasModel copyWith({
    String? id,
    String? kelasId,
    String? type,
    String? title,
    String? description,
    String? authorId,
    DateTime? createdAt,
    int? syncStatus,
  }) {
    return AktivitasKelasModel(
      id: id ?? this.id,
      kelasId: kelasId ?? this.kelasId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
