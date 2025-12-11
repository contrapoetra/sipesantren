import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/kelas_model.dart';
import 'package:sipesantren/core/models/penilaian_model.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/penilaian_repository.dart';
import 'package:sipesantren/core/repositories/santri_repository.dart';

class KelasGradingPage extends ConsumerStatefulWidget {
  final KelasModel kelas;
  final String mapelName;

  const KelasGradingPage({super.key, required this.kelas, required this.mapelName});

  @override
  ConsumerState<KelasGradingPage> createState() => _KelasGradingPageState();
}

class _KelasGradingPageState extends ConsumerState<KelasGradingPage> {
  List<SantriModel> _students = [];
  bool _isLoading = true;
  
  // State for inputs
  final Map<String, TextEditingController> _formatifControllers = {};
  final Map<String, TextEditingController> _sumatifControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final santriRepo = ref.read(santriRepositoryProvider);
    try {
      final students = await santriRepo.getSantriByKelas(widget.kelas.id);
      
      // Initialize controllers
      for (var s in students) {
        // Ideally fetch existing grades here to pre-fill
        // For now, we leave empty to imply new input or overwrite
        _formatifControllers[s.id] = TextEditingController();
        _sumatifControllers[s.id] = TextEditingController();
      }

      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _formatifControllers.values.forEach((c) => c.dispose());
    _sumatifControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveGrades() async {
    setState(() => _isLoading = true);
    final repo = ref.read(penilaianRepositoryProvider);
    int count = 0;
    try {
      for (var s in _students) {
        final fText = _formatifControllers[s.id]?.text.trim();
        final sText = _sumatifControllers[s.id]?.text.trim();

        // If both empty, skip (don't overwrite with 0 if user intended to skip)
        if ((fText == null || fText.isEmpty) && (sText == null || sText.isEmpty)) continue;

        final formatif = int.tryParse(fText ?? '0') ?? 0;
        final sumatif = int.tryParse(sText ?? '0') ?? 0;

        final data = PenilaianMapel(
          id: '',
          santriId: s.id,
          mapel: widget.mapelName,
          formatif: formatif,
          sumatif: sumatif,
        );
        await repo.addPenilaianMapel(data);
        count++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nilai $count siswa tersimpan.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nilai ${widget.mapelName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveGrades,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final s = _students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _formatifControllers[s.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Formatif (0-100)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _sumatifControllers[s.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Sumatif (0-100)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
