import 'package:cloud_firestore/cloud_firestore.dart';

class WeightConfigModel {
  static const String collectionName = 'settings'; 
  final String id; 
  final double tahfidz;
  final double akhlak;
  final double kehadiran;
  final Map<String, double> mapelWeights; // Mapel ID -> Weight (0.0 - 1.0)
  final int maxSantriPerRoom; 

  WeightConfigModel({
    required this.id,
    required this.tahfidz,
    required this.akhlak,
    required this.kehadiran,
    required this.mapelWeights,
    this.maxSantriPerRoom = 6, 
  });

  factory WeightConfigModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse mapelWeights
    Map<String, double> parsedWeights = {};
    if (data['mapelWeights'] != null) {
      (data['mapelWeights'] as Map<String, dynamic>).forEach((key, value) {
        parsedWeights[key] = (value as num).toDouble();
      });
    } else {
      // Fallback for legacy data if needed, or defaults
      // Assuming 'fiqh' and 'bahasaArab' might exist as flat fields in old data
      if (data.containsKey('fiqh')) parsedWeights['mapel_fiqh'] = (data['fiqh'] as num).toDouble();
      if (data.containsKey('bahasaArab')) parsedWeights['mapel_ba'] = (data['bahasaArab'] as num).toDouble();
    }

    return WeightConfigModel(
      id: doc.id,
      tahfidz: (data['tahfidz'] as num?)?.toDouble() ?? 0.30,
      akhlak: (data['akhlak'] as num?)?.toDouble() ?? 0.20,
      kehadiran: (data['kehadiran'] as num?)?.toDouble() ?? 0.10,
      mapelWeights: parsedWeights,
      maxSantriPerRoom: (data['maxSantriPerRoom'] as int?) ?? 6,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tahfidz': tahfidz,
      'akhlak': akhlak,
      'kehadiran': kehadiran,
      'mapelWeights': mapelWeights,
      'maxSantriPerRoom': maxSantriPerRoom,
    };
  }

  WeightConfigModel copyWith({
    String? id,
    double? tahfidz,
    double? akhlak,
    double? kehadiran,
    Map<String, double>? mapelWeights,
    int? maxSantriPerRoom,
  }) {
    return WeightConfigModel(
      id: id ?? this.id,
      tahfidz: tahfidz ?? this.tahfidz,
      akhlak: akhlak ?? this.akhlak,
      kehadiran: kehadiran ?? this.kehadiran,
      mapelWeights: mapelWeights ?? this.mapelWeights,
      maxSantriPerRoom: maxSantriPerRoom ?? this.maxSantriPerRoom,
    );
  }
}
