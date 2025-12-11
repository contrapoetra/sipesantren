import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // New import
import 'package:sipesantren/core/models/mapel_model.dart';
import 'package:sipesantren/core/repositories/mapel_repository.dart';

class MapelFormPage extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
  final MapelModel? mapel; // Optional: if provided, it's an edit operation

  const MapelFormPage({super.key, this.mapel});

  @override
  ConsumerState<MapelFormPage> createState() => _MapelFormPageState(); // Changed to ConsumerState
}

class _MapelFormPageState extends ConsumerState<MapelFormPage> { // Changed to ConsumerState
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // Removed direct instantiation, now obtained from provider
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mapel != null) {
      _nameController.text = widget.mapel!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveMapel() async {
    final repository = ref.read(mapelRepositoryProvider); // Get from provider
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.mapel == null) {
          // Add new mapel
          final newMapel = MapelModel(id: '', name: _nameController.text);
          await repository.addMapel(newMapel);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mata pelajaran berhasil ditambahkan')),
            );
          }
        } else {
          // Update existing mapel
          final updatedMapel = MapelModel(id: widget.mapel!.id, name: _nameController.text);
          await repository.updateMapel(updatedMapel);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mata pelajaran berhasil diperbarui')),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context); // Go back to MapelListPage
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
        title: Text(widget.mapel == null ? 'Tambah Mata Pelajaran' : 'Edit Mata Pelajaran'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Mata Pelajaran',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama mata pelajaran tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMapel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(widget.mapel == null ? 'SIMPAN' : 'PERBARUI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
