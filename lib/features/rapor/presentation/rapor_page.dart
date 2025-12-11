import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/penilaian_repository.dart';
import 'package:sipesantren/core/services/grading_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sipesantren/core/models/weight_config_model.dart';
import 'package:sipesantren/core/repositories/weight_config_repository.dart';
import 'package:sipesantren/core/repositories/mapel_repository.dart'; // Added

class RaporPage extends ConsumerStatefulWidget {
  final SantriModel? santri;
  const RaporPage({super.key, this.santri});

  @override
  ConsumerState<RaporPage> createState() => _RaporPageState();
}

class _RaporPageState extends ConsumerState<RaporPage> {
  final GradingService _gradingService = GradingService();

  Map<String, double> _scores = {};
  Map<String, dynamic> _finalGrade = {};
  String _akhlakCatatan = '';
  WeightConfigModel? _weights;
  bool _loading = true;
  
  // Need to store mapel info for display (name) and calculation (id)
  Map<String, String> _mapelIdToName = {};

  @override
  void initState() {
    super.initState();
    if (widget.santri != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final santriId = widget.santri!.id;
    final _repository = ref.read(penilaianRepositoryProvider);
    final _weightRepository = ref.read(weightConfigRepositoryProvider);
    final _mapelRepository = ref.read(mapelRepositoryProvider);

    await _weightRepository.initializeWeightConfig(); 
    _weights = await _weightRepository.getWeightConfig().first;
    final mapels = await _mapelRepository.getMapelList();
    
    _mapelIdToName = {for (var m in mapels) m.id: m.name};

    final tahfidzList = await _repository.getTahfidzBySantri(santriId);
    final mapelList = await _repository.getMapelBySantri(santriId);
    final akhlakList = await _repository.getAkhlakBySantri(santriId);
    final kehadiranList = await _repository.getKehadiranBySantri(santriId);

    if (akhlakList.isNotEmpty) {
      _akhlakCatatan = akhlakList.last.catatan; 
    }

    final tahfidzScore = _gradingService.calculateTahfidz(tahfidzList);
    final akhlakScore = _gradingService.calculateAkhlak(akhlakList);
    final kehadiranScore = _gradingService.calculateKehadiran(kehadiranList);
    
    // Calculate Mapel Scores
    Map<String, double> mapelScoresById = {};
    Map<String, double> mapelScoresByName = {};
    
    for (var m in mapels) {
      // Assuming 'mapel' field in PenilaianMapel is Name
      double val = _gradingService.calculateMapel(mapelList, m.name);
      mapelScoresById[m.id] = val;
      mapelScoresByName[m.name] = val;
    }

    final finalResult = _gradingService.calculateFinalGrade(
      tahfidz: tahfidzScore,
      akhlak: akhlakScore,
      kehadiran: kehadiranScore,
      mapelScores: mapelScoresById,
      weights: _weights!, 
    );

    if (mounted) {
      setState(() {
        _scores = {
          'Tahfidz': tahfidzScore,
          'Akhlak': akhlakScore,
          'Kehadiran': kehadiranScore,
          ...mapelScoresByName,
        };
        _finalGrade = finalResult;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.santri == null) {
       return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Data Santri tidak ditemukan')),
      );
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rapor Santri')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor Santri'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'print') {
                await _generatePdfAndPrint();
              } else if (value == 'share') {
                await _generatePdfAndShare();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Cetak Rapor'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Bagikan Rapor'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Rapor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'RAPOR SANTRI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nama Santri', widget.santri!.nama),
                    _buildInfoRow('NIS', widget.santri!.nis),
                    _buildInfoRow('Kamar', '${widget.santri!.kamarGedung}-${widget.santri!.kamarNomor}'),
                    _buildInfoRow('Angkatan', widget.santri!.angkatan.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nilai Akhir
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'NILAI AKHIR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNilaiCircle('${_finalGrade['score']}', '${_finalGrade['predikat']}', _getColorForPredikat(_finalGrade['predikat'])),
                        _buildNilaiItem('Status', _finalGrade['predikat'] != 'D' ? 'Lulus' : 'Remidial'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detail Nilai
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DETAIL NILAI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNilaiDetailRow('Tahfidz (${(_weights!.tahfidz * 100).round()}%)', '${_scores['Tahfidz']}'),
                    
                    // Dynamic Mapels
                    ..._weights!.mapelWeights.entries.map((e) {
                      final name = _mapelIdToName[e.key] ?? e.key;
                      final score = _scores[name] ?? 0.0;
                      return _buildNilaiDetailRow('$name (${(e.value * 100).round()}%)', '$score');
                    }),
                    
                    _buildNilaiDetailRow('Akhlak (${(_weights!.akhlak * 100).round()}%)', '${_scores['Akhlak']}'),
                    _buildNilaiDetailRow('Kehadiran (${(_weights!.kehadiran * 100).round()}%)', '${_scores['Kehadiran']}'),
                    const Divider(),
                    _buildNilaiDetailRow('NILAI AKHIR', '${_finalGrade['score']}', isBold: true),
                    if (_akhlakCatatan.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Catatan Ustadz:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_akhlakCatatan),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPredikat(String predikat) {
    switch (predikat) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      default: return Colors.red;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildNilaiCircle(String nilai, String predikat, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              nilai,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          predikat,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNilaiItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNilaiDetailRow(String label, String nilai, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            nilai,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  // Common function to generate PDF document
  Future<Uint8List> _generatePdfDocument() async {
    final doc = pw.Document();
    
    // Prepare table data
    final List<List<String>> tableData = [
      ['Mata Pelajaran', 'Nilai', 'Bobot'],
      ['Tahfidz', '${_scores['Tahfidz']}', '${(_weights!.tahfidz * 100).toStringAsFixed(0)}%'],
    ];

    _weights!.mapelWeights.forEach((id, weight) {
      final name = _mapelIdToName[id] ?? id;
      final score = _scores[name] ?? 0.0;
      tableData.add([name, '$score', '${(weight * 100).toStringAsFixed(0)}%']);
    });

    tableData.add(['Akhlak', '${_scores['Akhlak']}', '${(_weights!.akhlak * 100).toStringAsFixed(0)}%']);
    tableData.add(['Kehadiran', '${_scores['Kehadiran']}', '${(_weights!.kehadiran * 100).toStringAsFixed(0)}%']);

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Laporan Hasil Belajar Santri', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Nama: ${widget.santri!.nama}'),
              pw.Text('NIS: ${widget.santri!.nis}'),
              pw.Text('Kamar: ${widget.santri!.kamarGedung}-${widget.santri!.kamarNomor}'),
              pw.SizedBox(height: 30),
              
              pw.TableHelper.fromTextArray(context: context, data: tableData),
              
pw.Divider(),
pw.SizedBox(height: 10),
pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                   pw.Text('Nilai Akhir: ${_finalGrade['score']} (Predikat: ${_finalGrade['predikat']})', 
                     style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              if (_akhlakCatatan.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Catatan Ustadz:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_akhlakCatatan),
              ],
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  Future<void> _generatePdfAndPrint() async {
    final Uint8List pdfBytes = await _generatePdfDocument();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  Future<void> _generatePdfAndShare() async {
    final Uint8List pdfBytes = await _generatePdfDocument();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${widget.santri!.nama}_Rapor.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Rapor ${widget.santri!.nama}');
  }
}
