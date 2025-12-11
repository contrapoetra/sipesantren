import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // New import
import 'package:sipesantren/core/models/penilaian_model.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/penilaian_repository.dart';
import 'package:sipesantren/core/models/mapel_model.dart'; // New import
import 'package:sipesantren/core/repositories/mapel_repository.dart'; // New import

class InputPenilaianPage extends ConsumerStatefulWidget {
  final SantriModel? santri;
  final String initialType; // Added parameter

  const InputPenilaianPage({
    super.key, 
    this.santri,
    this.initialType = 'Tahfidz',
  });

  @override
  ConsumerState<InputPenilaianPage> createState() => _InputPenilaianPageState();
}

class _InputPenilaianPageState extends ConsumerState<InputPenilaianPage> {
  // Removed SingleTickerProviderStateMixin since no animation needed here anymore
  int _selectedIndex = 0;
  List<MapelModel> _mapelList = [];
  List<String> _jenisPenilaian = ['Tahfidz', 'Akhlak', 'Kehadiran'];
  int _mapelStartIndex = 0;

  // Controllers - Tahfidz
  final _tahfidzSurahController = TextEditingController();
  final _tahfidzAyatSetorController = TextEditingController();
  final _tahfidzTargetAyatController = TextEditingController(text: "50");
  final _tahfidzTajwidController = TextEditingController();

  // Controllers - Mapel
  final _mapelFormatifController = TextEditingController();
  final _mapelSumatifController = TextEditingController();

  // State - Akhlak
  int _akhlakDisiplin = 3;
  int _akhlakAdab = 3;
  int _akhlakKebersihan = 3;
  int _akhlakKerjasama = 3;
  final _akhlakCatatanController = TextEditingController();

  // State - Kehadiran
  DateTime _kehadiranTanggal = DateTime.now();
  String _kehadiranStatus = 'H';

  @override
  void initState() {
    super.initState();
    _loadMapelList();
  }

  Future<void> _loadMapelList() async {
    final _mapelRepository = ref.read(mapelRepositoryProvider);
    final mapel = await _mapelRepository.getMapelList();
    if (mounted) {
      setState(() {
        _mapelList = mapel;
        _jenisPenilaian = ['Tahfidz'];
        for (var m in _mapelList) {
          _jenisPenilaian.add(m.name);
        }
        _mapelStartIndex = 1;
        _jenisPenilaian.addAll(['Akhlak', 'Kehadiran']);
        
        // Set initial selection
        final index = _jenisPenilaian.indexOf(widget.initialType);
        if (index != -1) {
          _selectedIndex = index;
        }
      });
    }
  }

  @override
  void dispose() {
    _tahfidzSurahController.dispose();
    _tahfidzAyatSetorController.dispose();
    _tahfidzTargetAyatController.dispose();
    _tahfidzTajwidController.dispose();
    _mapelFormatifController.dispose();
    _mapelSumatifController.dispose();
    _akhlakCatatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.santri == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Data Santri tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Input: ${widget.initialType}'), // Specific title
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormByType(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormByType() {
    final _repository = ref.read(penilaianRepositoryProvider); // Get from provider

    // Check for Tahfidz (always at index 0)
    if (_selectedIndex == 0) {
      return _buildTahfidzForm(_repository);
    }
    // Check for dynamic Mapel
    if (_selectedIndex >= _mapelStartIndex && _selectedIndex < _mapelStartIndex + _mapelList.length) {
      final mapelName = _jenisPenilaian[_selectedIndex];
      return _buildMapelForm(mapelName, _repository);
    }
    // Check for Akhlak (second to last)
    if (_selectedIndex == _jenisPenilaian.length - 2) {
      return _buildAkhlakForm(_repository);
    }
    // Check for Kehadiran (last)
    if (_selectedIndex == _jenisPenilaian.length - 1) {
      return _buildKehadiranForm(_repository);
    }
    return Container();
  }

  Widget _buildTahfidzForm(PenilaianRepository _repository) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Input Nilai Tahfidz',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tahfidzSurahController,
          decoration: const InputDecoration(
            labelText: 'Surah',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tahfidzTargetAyatController,
          decoration: const InputDecoration(
            labelText: 'Target Ayat (Mingguan)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tahfidzAyatSetorController,
          decoration: const InputDecoration(
            labelText: 'Ayat Setoran',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tahfidzTajwidController,
          decoration: const InputDecoration(
            labelText: 'Nilai Tajwid (0-100)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final data = PenilaianTahfidz(
                  id: '',
                  santriId: widget.santri!.id,
                  minggu: DateTime.now(),
                  surah: _tahfidzSurahController.text,
                  ayatSetor: int.tryParse(_tahfidzAyatSetorController.text) ?? 0,
                  targetAyat: int.tryParse(_tahfidzTargetAyatController.text) ?? 50,
                  tajwid: int.tryParse(_tahfidzTajwidController.text) ?? 0,
                );
                await _repository.addPenilaianTahfidz(data);
                _showSuccess('Data Tahfidz berhasil disimpan');
                _tahfidzSurahController.clear();
                _tahfidzAyatSetorController.clear();
                _tahfidzTajwidController.clear();
              } catch (e) {
                _showError('Gagal menyimpan: $e');
              }
            },
            child: const Text('SIMPAN NILAI TAHFIDZ'),
          ),
        ),
      ],
    );
  }

  Widget _buildMapelForm(String mapel, PenilaianRepository _repository) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input Nilai $mapel',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _mapelFormatifController,
          decoration: const InputDecoration(
            labelText: 'Nilai Formatif (0-100)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mapelSumatifController,
          decoration: const InputDecoration(
            labelText: 'Nilai Sumatif (0-100)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final data = PenilaianMapel(
                  id: '',
                  santriId: widget.santri!.id,
                  mapel: mapel,
                  formatif: int.tryParse(_mapelFormatifController.text) ?? 0,
                  sumatif: int.tryParse(_mapelSumatifController.text) ?? 0,
                );
                await _repository.addPenilaianMapel(data);
                _showSuccess('Data $mapel berhasil disimpan');
                _mapelFormatifController.clear();
                _mapelSumatifController.clear();
              } catch (e) {
                _showError('Gagal menyimpan: $e');
              }
            },
            child: Text('SIMPAN NILAI $mapel'),
          ),
        ),
      ],
    );
  }

  Widget _buildAkhlakForm(PenilaianRepository _repository) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Input Nilai Akhlak',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAkhlakSlider('Disiplin', _akhlakDisiplin, (value) {
          setState(() {
            _akhlakDisiplin = value.toInt();
          });
        }),
        _buildAkhlakSlider('Adab pada Guru', _akhlakAdab, (value) {
          setState(() {
            _akhlakAdab = value.toInt();
          });
        }),
        _buildAkhlakSlider('Kebersihan', _akhlakKebersihan, (value) {
          setState(() {
            _akhlakKebersihan = value.toInt();
          });
        }),
        _buildAkhlakSlider('Kerja Sama', _akhlakKerjasama, (value) {
          setState(() {
            _akhlakKerjasama = value.toInt();
          });
        }),
        const SizedBox(height: 16),
        TextField(
          controller: _akhlakCatatanController,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final data = PenilaianAkhlak(
                  id: '',
                  santriId: widget.santri!.id,
                  disiplin: _akhlakDisiplin,
                  adab: _akhlakAdab,
                  kebersihan: _akhlakKebersihan,
                  kerjasama: _akhlakKerjasama,
                  catatan: _akhlakCatatanController.text,
                );
                await _repository.addPenilaianAkhlak(data);
                _showSuccess('Data Akhlak berhasil disimpan');
                _akhlakCatatanController.clear();
              } catch (e) {
                _showError('Gagal menyimpan: $e');
              }
            },
            child: const Text('SIMPAN NILAI AKHLAK'),
          ),
        ),
      ],
    );
  }

  Widget _buildAkhlakSlider(String label, int value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 4,
          divisions: 3,
          label: _getAkhlakLabel(value),
          onChanged: onChanged,
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kurang (1)'),
            Text('Cukup (2)'),
            Text('Baik (3)'),
            Text('Sangat Baik (4)'),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getAkhlakLabel(int value) {
    switch (value) {
      case 1: return 'Kurang';
      case 2: return 'Cukup';
      case 3: return 'Baik';
      case 4: return 'Sangat Baik';
      default: return '';
    }
  }

  Widget _buildKehadiranForm(PenilaianRepository _repository) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Input Kehadiran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _kehadiranTanggal,
              firstDate: DateTime(2020),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              setState(() {
                _kehadiranTanggal = picked;
              });
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tanggal',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(DateFormat('yyyy-MM-dd').format(_kehadiranTanggal)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Status Kehadiran:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildStatusChip('H', 'Hadir', _kehadiranStatus == 'H', () {
              setState(() {
                _kehadiranStatus = 'H';
              });
            }),
            _buildStatusChip('S', 'Sakit', _kehadiranStatus == 'S', () {
              setState(() {
                _kehadiranStatus = 'S';
              });
            }),
            _buildStatusChip('I', 'Izin', _kehadiranStatus == 'I', () {
              setState(() {
                _kehadiranStatus = 'I';
              });
            }),
            _buildStatusChip('A', 'Alpa', _kehadiranStatus == 'A', () {
              setState(() {
                _kehadiranStatus = 'A';
              });
            }),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final data = Kehadiran(
                  id: '',
                  santriId: widget.santri!.id,
                  tanggal: _kehadiranTanggal,
                  status: _kehadiranStatus,
                );
                await _repository.addKehadiran(data);
                _showSuccess('Data Kehadiran berhasil disimpan');
              } catch (e) {
                _showError('Gagal menyimpan: $e');
              }
            },
            child: const Text('SIMPAN KEHADIRAN'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool selected) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
      ),
    );
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}