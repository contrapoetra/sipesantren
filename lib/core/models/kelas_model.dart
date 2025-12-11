import 'package:cloud_firestore/cloud_firestore.dart';

class KelasModel {
  final String id;
  final String name;
  final String? waliKelasId;
  final int? syncStatus;

  KelasModel({
    required this.id,
    required this.name,
    this.waliKelasId,
    this.syncStatus,
  });

  factory KelasModel.fromMap(Map<String, dynamic> map) {
    return KelasModel(
      id: map['id'],
      name: map['name'],
      waliKelasId: map['waliKelasId'],
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'waliKelasId': waliKelasId,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  factory KelasModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return KelasModel(
      id: doc.id,
      name: data['name'] ?? '',
      waliKelasId: data['waliKelasId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'waliKelasId': waliKelasId,
    };
  }

  KelasModel copyWith({
    String? id,
    String? name,
    String? waliKelasId,
    int? syncStatus,
  }) {
    return KelasModel(
      id: id ?? this.id,
      name: name ?? this.name,
      waliKelasId: waliKelasId ?? this.waliKelasId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
