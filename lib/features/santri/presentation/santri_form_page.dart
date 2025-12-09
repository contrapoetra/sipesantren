import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // New import
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/santri_repository.dart';

class SantriFormPage extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  final SantriModel? santri; // Optional: if provided, it's an edit operation

  const SantriFormPage({super.key, this.santri});

  @override
  ConsumerState<SantriFormPage> createState() => _SantriFormPageState(); // Changed to ConsumerState
}

class _SantriFormPageState extends ConsumerState<SantriFormPage> { // Changed to ConsumerState
  final _formKey = GlobalKey<FormState>();
  final _nisController = TextEditingController();
  final _namaController = TextEditingController();
  final _angkatanController = TextEditingController();
  String _selectedBuilding = 'A'; // New state for building dropdown
  final _roomNumberController = TextEditingController(); // New controller for room number

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.santri != null) {
      _nisController.text = widget.santri!.nis;
      _namaController.text = widget.santri!.nama;
      _selectedBuilding = widget.santri!.kamarGedung;
      _roomNumberController.text = widget.santri!.kamarNomor.toString();
      _angkatanController.text = widget.santri!.angkatan.toString();
    }
  }

  @override
  void dispose() {
    _nisController.dispose();
    _namaController.dispose();
    _angkatanController.dispose();
    _roomNumberController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _saveSantri() async {
    final _repository = ref.read(santriRepositoryProvider); // Get from provider
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.santri == null) {
          // Add new santri
          final newSantri = SantriModel(
            id: '', // Firestore auto-id
            nis: _nisController.text,
            nama: _namaController.text,
            kamarGedung: _selectedBuilding,
            kamarNomor: int.tryParse(_roomNumberController.text) ?? 0,
            angkatan: int.tryParse(_angkatanController.text) ?? DateTime.now().year,
          );
          await _repository.addSantri(newSantri);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Santri berhasil ditambahkan')),
            );
          }
        } else {
          // Update existing santri
          final updatedSantri = SantriModel(
            id: widget.santri!.id,
            nis: _nisController.text,
            nama: _namaController.text,
            kamarGedung: _selectedBuilding,
            kamarNomor: int.tryParse(_roomNumberController.text) ?? 0,
            angkatan: int.tryParse(_angkatanController.text) ?? DateTime.now().year,
          );
          await _repository.updateSantri(updatedSantri);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Santri berhasil diperbarui')),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context); // Go back to SantriListPage
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _nisController,
                  decoration: const InputDecoration(
                    labelText: 'NIS',
                    border: InputBorder.none, // Remove border from TextFormField itself
                    contentPadding: EdgeInsets.zero, // Remove default padding
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'NIS tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: InputBorder.none, // Remove border from TextFormField itself
                    contentPadding: EdgeInsets.zero, // Remove default padding
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedBuilding,
                          icon: const Icon(Icons.arrow_drop_down),
                          elevation: 16,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBuilding = newValue!;
                            });
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
                          border: InputBorder.none, // Remove border
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nomor kamar tidak boleh kosong';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Nomor kamar harus angka';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _angkatanController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Angkatan (Tahun)',
                    border: InputBorder.none, // Remove border from TextFormField itself
                    contentPadding: EdgeInsets.zero, // Remove default padding
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Angkatan tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Angkatan harus berupa angka';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSantri,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5), // Disabled style
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Consistent with dialog buttons
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(widget.santri == null ? 'SIMPAN' : 'PERBARUI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
