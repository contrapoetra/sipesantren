import 'package:cloud_firestore/cloud_firestore.dart';

class SantriModel {
  final String id;
  final String nis;
  final String nama;
  final String kamarGedung;
  final int kamarNomor;
  final int angkatan;
  final String? kelasId;
  final String? waliSantriId;
  // syncStatus is internal to DB, usually not part of the core domain model unless needed for UI indicators
  // We can add it as an optional field
  final int? syncStatus; 

  SantriModel({
    required this.id,
    required this.nis,
    required this.nama,
    required this.kamarGedung,
    required this.kamarNomor,
    required this.angkatan,
    this.kelasId,
    this.waliSantriId,
    this.syncStatus,
  });

  // SQLite methods
  factory SantriModel.fromMap(Map<String, dynamic> map) {
    return SantriModel(
      id: map['id'],
      nis: map['nis'],
      nama: map['nama'],
      kamarGedung: map['kamarGedung'],
      kamarNomor: map['kamarNomor'],
      angkatan: map['angkatan'],
      kelasId: map['kelasId'],
      waliSantriId: map['waliSantriId'],
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nis': nis,
      'nama': nama,
      'kamarGedung': kamarGedung,
      'kamarNomor': kamarNomor,
      'angkatan': angkatan,
      'kelasId': kelasId,
      'waliSantriId': waliSantriId,
      // syncStatus is managed by repository usually, but if we pass it:
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  // Firestore methods
  factory SantriModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SantriModel(
      id: doc.id,
      nis: data['nis'] ?? '',
      nama: data['nama'] ?? '',
      kamarGedung: data['kamarGedung'] ?? '',
      kamarNomor: data['kamarNomor'] ?? 0,
      angkatan: data['angkatan'] ?? 0,
      kelasId: data['kelasId'],
      waliSantriId: data['waliSantriId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nis': nis,
      'nama': nama,
      'kamarGedung': kamarGedung,
      'kamarNomor': kamarNomor,
      'angkatan': angkatan,
      'kelasId': kelasId,
      'waliSantriId': waliSantriId,
    };
  }
  
  SantriModel copyWith({
    String? id,
    String? nis,
    String? nama,
    String? kamarGedung,
    int? kamarNomor,
    int? angkatan,
    String? kelasId,
    String? waliSantriId,
    int? syncStatus,
  }) {
    return SantriModel(
      id: id ?? this.id,
      nis: nis ?? this.nis,
      nama: nama ?? this.nama,
      kamarGedung: kamarGedung ?? this.kamarGedung,
      kamarNomor: kamarNomor ?? this.kamarNomor,
      angkatan: angkatan ?? this.angkatan,
      kelasId: kelasId ?? this.kelasId,
      waliSantriId: waliSantriId ?? this.waliSantriId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
