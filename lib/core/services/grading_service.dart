import '../models/penilaian_model.dart';
import '../models/weight_config_model.dart'; // New import

class GradingService {
  double calculateTahfidz(List<PenilaianTahfidz> list) {
    if (list.isEmpty) return 0;
    // Assuming we take the latest or average? PDF says "tahfidz = round(0.5*capaian + 0.5*tajwid)"
    // It implies per assessment or overall?
    // "Nilai Tahfidz (0–100): Komponen: ... Gabungan"
    // Usually Rapor is cumulative or average of the term.
    // Let's average the final scores of all entries for the period.
    double total = 0;
    for (var p in list) {
      total += p.nilaiAkhir;
    }
    return (total / list.length).roundToDouble();
  }

  double calculateMapel(List<PenilaianMapel> list, String mapelName) {
    final mapelList = list.where((m) => m.mapel == mapelName).toList();
    if (mapelList.isEmpty) return 0;
    double total = 0;
    for (var p in mapelList) {
      total += p.nilaiAkhir;
    }
    return (total / mapelList.length).roundToDouble();
  }

  double calculateAkhlak(List<PenilaianAkhlak> list) {
    if (list.isEmpty) return 0;
    double total = 0;
    for (var p in list) {
      total += p.nilaiAkhir;
    }
    return (total / list.length).roundToDouble();
  }

  double calculateKehadiran(List<Kehadiran> list) {
    if (list.isEmpty) return 100; // Default full attendance if no records? Or 0? Let's say 100 or 0 based on policy. Let's start with 0 if no data, but usually 100 if no absence recorded.
    // Actually, "hadir% = (H / (H+S+I+A)) * 100".
    // If list is empty, H=0, total=0. 0/0.
    if (list.isEmpty) return 0;

    int hadir = list.where((k) => k.status == 'H').length;
    int total = list.length;
    return ((hadir / total) * 100).roundToDouble();
  }

  Map<String, dynamic> calculateFinalGrade({
    required double tahfidz,
    required double akhlak,
    required double kehadiran,
    required Map<String, double> mapelScores, // Mapel Name/ID -> Score
    required WeightConfigModel weights, 
  }) {
    double weightedSum = (weights.tahfidz * tahfidz) +
        (weights.akhlak * akhlak) +
        (weights.kehadiran * kehadiran);

    // Dynamic Mapel Calculation
    // We match keys. Mapel weights are keyed by ID (e.g., 'mapel_fiqh').
    // mapelScores should ideally be keyed by ID too.
    // However, the caller might be passing Names if they don't have IDs handy?
    // Let's assume mapelScores keys match weights keys (IDs).
    
    weights.mapelWeights.forEach((key, weight) {
      double score = mapelScores[key] ?? 0.0;
      weightedSum += (weight * score);
    });
    
    double finalScore = weightedSum.roundToDouble();

    String predikat = 'D';
    if (finalScore >= 85) {
      predikat = 'A';
    } else if (finalScore >= 75) {
      predikat = 'B';
    } else if (finalScore >= 65) {
      predikat = 'C';
    }

    return {
      'score': finalScore,
      'predikat': predikat,
    };
  }
}
