import 'package:flutter_test/flutter_test.dart';
import 'package:sipesantren/core/services/grading_service.dart';
import 'package:sipesantren/core/models/penilaian_model.dart';
import 'package:sipesantren/core/models/weight_config_model.dart'; // New import

void main() {
  group('GradingService Tests', () {
    final service = GradingService();

    // Create a default WeightConfigModel for testing
    final defaultWeights = WeightConfigModel(
      id: 'test_weights',
      tahfidz: 0.30,
      akhlak: 0.20,
      kehadiran: 0.10,
      mapelWeights: {
        'Fiqh': 0.20,
        'Bahasa Arab': 0.20,
      },
    );

    test('calculateTahfidz returns correct average', () {
      final list = [
        PenilaianTahfidz(id: '1', santriId: 's1', minggu: DateTime.now(), surah: 'A', ayatSetor: 50, targetAyat: 50, tajwid: 100), // Capaian 100, Tajwid 100 => 100
        PenilaianTahfidz(id: '2', santriId: 's1', minggu: DateTime.now(), surah: 'B', ayatSetor: 25, targetAyat: 50, tajwid: 80), // Capaian 50, Tajwid 80 => (25 + 40) = 65
      ];
      // (100 + 65) / 2 = 82.5 -> 83
      expect(service.calculateTahfidz(list), 83.0);
    });

    test('calculateMapel returns correct average', () {
      final list = [
        PenilaianMapel(id: '1', santriId: 's1', mapel: 'Fiqh', formatif: 80, sumatif: 90), // 0.4*80 + 0.6*90 = 32 + 54 = 86
        PenilaianMapel(id: '2', santriId: 's1', mapel: 'Fiqh', formatif: 70, sumatif: 75), // 0.4*70 + 0.6*75 = 28 + 45 = 73
      ];
      // (86 + 73) / 2 = 79.5 -> 80
      expect(service.calculateMapel(list, 'Fiqh'), 80.0);
    });

    test('calculateAkhlak returns correct score', () {
      final list = [
        PenilaianAkhlak(id: '1', santriId: 's1', disiplin: 4, adab: 4, kebersihan: 3, kerjasama: 4, catatan: ''), 
        // Avg (15/4) = 3.75. Score = (3.75/4)*100 = 93.75 -> 94
      ];
      expect(service.calculateAkhlak(list), 94.0);
    });

    test('calculateKehadiran returns percentage', () {
      final list = [
        Kehadiran(id: '1', santriId: 's1', tanggal: DateTime.now(), status: 'H'),
        Kehadiran(id: '2', santriId: 's1', tanggal: DateTime.now(), status: 'H'),
        Kehadiran(id: '3', santriId: 's1', tanggal: DateTime.now(), status: 'S'),
        Kehadiran(id: '4', santriId: 's1', tanggal: DateTime.now(), status: 'A'),
      ];
      // 2 Hadir out of 4 = 50%
      expect(service.calculateKehadiran(list), 50.0);
    });

    test('calculateFinalGrade returns correct final score and predikat', () {
      final result = service.calculateFinalGrade(
        tahfidz: 93,
        akhlak: 94,
        kehadiran: 90,
        mapelScores: {
          'Fiqh': 86,
          'Bahasa Arab': 78,
        },
        weights: defaultWeights, // Pass the default weights
      );
      // 0.3*93 = 27.9
      // 0.2*86 = 17.2
      // 0.2*78 = 15.6
      // 0.2*94 = 18.8
      // 0.1*90 = 9.0
      // Sum = 88.5 -> 89 (Round half up usually, or standard round)
      
      expect(result['score'], 89.0);
      expect(result['predikat'], 'A');
    });
  });
}
