import 'package:cloud_firestore/cloud_firestore.dart';

class SantriModel {
  final String id;
  final String nis;
  final String nama;
  final String kamarGedung; // New field for building
  final int kamarNomor;    // New field for room number
  final int angkatan;

  SantriModel({
    required this.id,
    required this.nis,
    required this.nama,
    required this.kamarGedung,
    required this.kamarNomor,
    required this.angkatan,
  });

  factory SantriModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SantriModel(
      id: doc.id,
      nis: data['nis'] ?? '',
      nama: data['nama'] ?? '',
      kamarGedung: data['kamarGedung'] ?? '', // Updated field
      kamarNomor: data['kamarNomor'] ?? 0,    // Updated field
      angkatan: data['angkatan'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nis': nis,
      'nama': nama,
      'kamarGedung': kamarGedung, // Updated field
      'kamarNomor': kamarNomor,    // Updated field
      'angkatan': angkatan,
    };
  }
}
