import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/santri_repository.dart';
import 'package:sipesantren/core/repositories/weight_config_repository.dart';
import 'package:sipesantren/core/providers/kelas_provider.dart'; 
import 'package:sipesantren/core/providers/user_list_provider.dart'; 

class SantriFormPage extends ConsumerStatefulWidget {
  final SantriModel? santri;

  const SantriFormPage({super.key, this.santri});

  @override
  ConsumerState<SantriFormPage> createState() => _SantriFormPageState();
}

class _SantriFormPageState extends ConsumerState<SantriFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nisController = TextEditingController();
  final _namaController = TextEditingController();
  final _angkatanController = TextEditingController();
  String _selectedBuilding = 'A';
  final _roomNumberController = TextEditingController();

  String? _selectedKelasId; // Added
  String? _selectedWaliId; // Added

  bool _isLoading = false;
  
  // Validation state
  String? _roomErrorText;
  bool _isRoomFull = false;
  int _maxCapacity = 6;

  @override
  void initState() {
    super.initState();
    if (widget.santri != null) {
      _nisController.text = widget.santri!.nis;
      _namaController.text = widget.santri!.nama;
      _selectedBuilding = widget.santri!.kamarGedung;
      _roomNumberController.text = widget.santri!.kamarNomor.toString();
      _angkatanController.text = widget.santri!.angkatan.toString();
      _selectedKelasId = widget.santri!.kelasId; // Added
      _selectedWaliId = widget.santri!.waliSantriId; // Added
    }
    _loadConfig();
    
    // Add listeners for dynamic validation
    _roomNumberController.addListener(_checkRoomCapacity);
  }

  Future<void> _loadConfig() async {
    final weightRepo = ref.read(weightConfigRepositoryProvider);
    await weightRepo.initializeWeightConfig(); // Ensure default
    final config = await weightRepo.getWeightConfig().first;
    if (mounted) {
      setState(() {
        _maxCapacity = config.maxSantriPerRoom;
      });
      // Check initial state if editing
      _checkRoomCapacity();
    }
  }

  @override
  void dispose() {
    _nisController.dispose();
    _namaController.dispose();
    _angkatanController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkRoomCapacity() async {
    if (_roomNumberController.text.isEmpty) {
      setState(() {
        _roomErrorText = null;
        _isRoomFull = false;
      });
      return;
    }

    final int? roomNum = int.tryParse(_roomNumberController.text);
    if (roomNum == null) return;

    final repository = ref.read(santriRepositoryProvider);
    final count = await repository.getSantriCountInRoom(_selectedBuilding, roomNum);

    bool isMovingOrNew = true;
    if (widget.santri != null) {
      // If editing and staying in same room
      if (widget.santri!.kamarGedung == _selectedBuilding && 
          widget.santri!.kamarNomor == roomNum) {
        isMovingOrNew = false;
      }
    }

    if (mounted) {
      setState(() {
        if (isMovingOrNew) {
          // Checking against capacity for a new entry in this room
          if (count >= _maxCapacity) {
            _isRoomFull = true;
            _roomErrorText = 'Kamar penuh ($count/$_maxCapacity)';
          } else {
            _isRoomFull = false;
            _roomErrorText = null; 
          }
        } else {
          if (count > _maxCapacity) {
             _isRoomFull = true; 
             _roomErrorText = 'Over kapasitas ($count/$_maxCapacity)';
          } else {
             _isRoomFull = false;
             _roomErrorText = null;
          }
        }
      });
    }
  }

    Future<void> _saveSantri() async {
      await _checkRoomCapacity();
      if (_isRoomFull) return;

      final repository = ref.read(santriRepositoryProvider);

      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });

        try {
          if (widget.santri == null) {
            // Add new santri
            final newSantri = SantriModel(
              id: '',
              nis: _nisController.text,
              nama: _namaController.text,
              kamarGedung: _selectedBuilding,
              kamarNomor: int.tryParse(_roomNumberController.text) ?? 0,
              angkatan: int.tryParse(_angkatanController.text) ?? DateTime.now().year,
              kelasId: _selectedKelasId, // Added
              waliSantriId: _selectedWaliId, // Added
            );
            await repository.addSantri(newSantri);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Santri berhasil ditambahkan')),
              );
            }
          } else {
            // Update existing santri
            final updatedSantri = widget.santri!.copyWith(
              nis: _nisController.text,
              nama: _namaController.text,
              kamarGedung: _selectedBuilding,
              kamarNomor: int.tryParse(_roomNumberController.text) ?? 0,
              angkatan: int.tryParse(_angkatanController.text) ?? DateTime.now().year,
              kelasId: _selectedKelasId, // Added
              waliSantriId: _selectedWaliId, // Added
            );
            await repository.updateSantri(updatedSantri);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Santri berhasil diperbarui')),
              );
            }
          }
          if (mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      final kelasAsync = ref.watch(kelasProvider);
      final usersAsync = ref.watch(usersStreamProvider);

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.santri == null ? 'Tambah Santri' : 'Edit Santri'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            onChanged: () {
              setState(() {}); 
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NIS Input
                  _buildInputCard(
                    child: TextFormField(
                      controller: _nisController,
                      decoration: const InputDecoration(labelText: 'NIS', border: InputBorder.none),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Name Input
                  _buildInputCard(
                    child: TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap', border: InputBorder.none),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Kelas Dropdown
                  _buildInputCard(
                    child: kelasAsync.when(
                      data: (data) => DropdownButtonFormField<String>(
                        initialValue: _selectedKelasId,
                        decoration: const InputDecoration(labelText: 'Kelas', border: InputBorder.none),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Pilih Kelas')),
                          ...data.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedKelasId = val),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Error loading kelas'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Wali Santri Dropdown
                  _buildInputCard(
                    child: usersAsync.when(
                      data: (data) {
                        final walis = data.where((u) => u.role == 'Wali' || u.role == 'Wali Santri').toList();
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedWaliId,
                          decoration: const InputDecoration(labelText: 'Wali Santri', border: InputBorder.none),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Pilih Wali Santri')),
                            ...walis.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.email})'))),
                          ],
                          onChanged: (val) => setState(() => _selectedWaliId = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => const Text('Error loading users'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Room Selection
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedBuilding,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedBuilding = newValue!;
                                    });
                                    _checkRoomCapacity();
                                  },
                                  items: <String>['A', 'B', 'C', 'D', 'E']
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text('Gedung $value'),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _roomNumberController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor Kamar',
                                  border: InputBorder.none,
                                ),
                                validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Invalid' : null,
                              ),
                            ),
                          ],
                        ),
                        if (_roomErrorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _roomErrorText!,
                              style: TextStyle(
                                color: _isRoomFull ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Angkatan Input
                  _buildInputCard(
                    child: TextFormField(
                      controller: _angkatanController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Angkatan (Tahun)', border: InputBorder.none),
                      validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: (_isLoading || _isRoomFull) ? null : _saveSantri,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(widget.santri == null ? 'SIMPAN' : 'PERBARUI'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildInputCard({required Widget child}) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
             BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
    }
}


  