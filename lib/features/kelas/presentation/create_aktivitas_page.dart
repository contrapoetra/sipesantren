import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/aktivitas_kelas_model.dart';
import 'package:sipesantren/core/providers/aktivitas_kelas_provider.dart';
import 'package:sipesantren/core/providers/user_provider.dart';

class CreateAktivitasPage extends ConsumerStatefulWidget {
  final String kelasId;

  const CreateAktivitasPage({super.key, required this.kelasId});

  @override
  ConsumerState<CreateAktivitasPage> createState() => _CreateAktivitasPageState();
}

class _CreateAktivitasPageState extends ConsumerState<CreateAktivitasPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'announcement'; // 'announcement' or 'assignment'

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(userProvider);
      final activity = AktivitasKelasModel(
        id: '',
        kelasId: widget.kelasId,
        type: _type,
        title: _titleController.text,
        description: _descController.text,
        authorId: user.userId ?? '',
        createdAt: DateTime.now(),
      );

      ref.read(aktivitasKelasProvider(widget.kelasId).notifier).addActivity(activity);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Aktivitas Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(value: 'announcement', child: Text('Pengumuman')),
                  DropdownMenuItem(value: 'assignment', child: Text('Tugas')),
                ],
                onChanged: (val) => setState(() => _type = val!),
                decoration: const InputDecoration(labelText: 'Tipe'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                maxLines: 5,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
