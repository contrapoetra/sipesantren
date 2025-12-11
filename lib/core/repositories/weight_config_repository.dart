import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // New import
import 'package:sipesantren/firebase_services.dart'; // New import for firestoreProvider
import 'package:sipesantren/core/models/weight_config_model.dart';

class WeightConfigRepository {
  final FirebaseFirestore _db;
  static const String _documentId = 'grading_weights'; // Fixed ID for the weights configuration document

  WeightConfigRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  // Get a stream of the WeightConfigModel
  Stream<WeightConfigModel> getWeightConfig() {
    return _db.collection(WeightConfigModel.collectionName)
        .doc(_documentId)
        .snapshots()
        .map((snapshot) => WeightConfigModel.fromFirestore(snapshot));
  }

  // Update the WeightConfigModel
  Future<void> updateWeightConfig(WeightConfigModel config) async {
    await _db.collection(WeightConfigModel.collectionName)
        .doc(_documentId)
        .set(config.toFirestore(), SetOptions(merge: true)); // Use merge to avoid overwriting other fields
  }

  // Initialize with default weights if document does not exist
  Future<void> initializeWeightConfig() async {
    final doc = await _db.collection(WeightConfigModel.collectionName).doc(_documentId).get();
    if (!doc.exists) {
      final defaultConfig = WeightConfigModel(
        id: _documentId,
        tahfidz: 0.30,
        akhlak: 0.20,
        kehadiran: 0.10,
        mapelWeights: {
          'mapel_fiqh': 0.20,
          'mapel_ba': 0.20,
        },
        maxSantriPerRoom: 6,
      );
      await _db.collection(WeightConfigModel.collectionName).doc(_documentId).set(defaultConfig.toFirestore());
    }
  }
}

final weightConfigRepositoryProvider = Provider((ref) => WeightConfigRepository(firestore: ref.watch(firestoreProvider)));
