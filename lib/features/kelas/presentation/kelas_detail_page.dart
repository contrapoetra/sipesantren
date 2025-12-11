import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/kelas_model.dart';
import 'package:sipesantren/core/models/teaching_assignment_model.dart';
import 'package:sipesantren/core/models/user_model.dart';
import 'package:sipesantren/core/models/mapel_model.dart';
import 'package:sipesantren/core/providers/kelas_provider.dart';
import 'package:sipesantren/core/providers/teaching_provider.dart';
import 'package:sipesantren/core/providers/user_list_provider.dart';
import 'package:sipesantren/core/providers/mapel_provider.dart';

class KelasDetailPage extends ConsumerStatefulWidget {
  final KelasModel kelas;

  const KelasDetailPage({super.key, required this.kelas});

  @override
  ConsumerState<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends ConsumerState<KelasDetailPage> {
  late TextEditingController _nameController;
  String? _selectedWaliKelasId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kelas.name);
    _selectedWaliKelasId = widget.kelas.waliKelasId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final updatedKelas = widget.kelas.copyWith(
      name: newName,
      waliKelasId: _selectedWaliKelasId,
    );

    ref.read(kelasProvider.notifier).updateKelas(updatedKelas);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
    Navigator.pop(context);
  }

  void _deleteKelas() {
     showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kelas'),
          content: Text('Hapus kelas ${widget.kelas.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(kelasProvider.notifier).deleteKelas(widget.kelas.id);
                Navigator.pop(context); // Pop Dialog
                Navigator.pop(context); // Pop Page
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
    final assignments = ref.watch(assignmentsByKelasProvider(widget.kelas.id));
    final mapelsAsync = ref.watch(mapelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Kelas ${widget.kelas.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteKelas),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kelas Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama Kelas'),
                    ),
                    const SizedBox(height: 16),
                    usersAsync.when(
                      data: (users) {
                        final ustads = users.where((u) => u.role == 'Ustadz' || u.role == 'Admin').toList(); // Allow Admin to be Wali too
                        return DropdownButtonFormField<String>(
                          value: _selectedWaliKelasId,
                          decoration: const InputDecoration(labelText: 'Wali Kelas'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Pilih Wali Kelas')),
                            ...ustads.map((u) => DropdownMenuItem(
                                  value: u.id,
                                  child: Text('${u.name} (${u.role})'),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedWaliKelasId = value;
                            });
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => Text('Error loading users: $e'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Simpan Perubahan Kelas'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Teaching Assignments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pengajar Mata Pelajaran', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _showAddAssignmentDialog(context, ref, usersAsync.value ?? [], mapelsAsync.value ?? []),
                ),
              ],
            ),
            if (assignments.isEmpty)
              const Text('Belum ada pengajar ditugaskan.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  final mapelName = mapelsAsync.value?.firstWhere((m) => m.id == assignment.mapelId, orElse: () => MapelModel(id: '', name: 'Unknown')).name ?? 'Loading...';
                  final ustadName = usersAsync.value?.firstWhere((u) => u.id == assignment.ustadId, orElse: () => UserModel(id: '', name: 'Unknown', email: '', role: '', hashedPassword: '', createdAt: DateTime.now())).name ?? 'Loading...';
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(mapelName),
                      subtitle: Text('Pengajar: $ustadName'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref.read(teachingProvider.notifier).deleteAssignment(assignment.id);
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref, List<UserModel> users, List<MapelModel> mapels) {
    String? selectedMapelId;
    String? selectedUstadId;
    final ustads = users.where((u) => u.role == 'Ustadz' || u.role == 'Admin').toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Pengajar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
                    items: mapels.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                    onChanged: (val) => setState(() => selectedMapelId = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Ustadz Pengajar'),
                    items: ustads.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                    onChanged: (val) => setState(() => selectedUstadId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMapelId != null && selectedUstadId != null) {
                      ref.read(teachingProvider.notifier).addAssignment(
                        TeachingAssignmentModel(
                          id: '',
                          kelasId: widget.kelas.id,
                          mapelId: selectedMapelId!,
                          ustadId: selectedUstadId!,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}