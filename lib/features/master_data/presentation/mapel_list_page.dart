import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/mapel_model.dart';
import 'package:sipesantren/core/providers/mapel_provider.dart';

class MapelListPage extends ConsumerWidget {
  const MapelListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapelAsyncValue = ref.watch(mapelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Mata Pelajaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(mapelProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: mapelAsyncValue.when(
        data: (mapels) {
          if (mapels.isEmpty) {
            return const Center(child: Text('Belum ada data mata pelajaran.'));
          }
          return ListView.builder(
            itemCount: mapels.length,
            itemBuilder: (context, index) {
              final mapel = mapels[index];
              return ListTile(
                title: Text(mapel.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteDialog(context, ref, mapel);
                  },
                ),
                onTap: () {
                  _showAddEditDialog(context, ref, mapel: mapel);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, {MapelModel? mapel}) {
    final nameController = TextEditingController(text: mapel?.name);
    final isEditing = mapel != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Mapel' : 'Tambah Mapel'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nama Mata Pelajaran'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                if (isEditing) {
                  ref.read(mapelProvider.notifier).updateMapel(
                        mapel.copyWith(name: name),
                      );
                } else {
                  ref.read(mapelProvider.notifier).addMapel(
                        MapelModel(id: '', name: name),
                      );
                }
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, MapelModel mapel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Mapel'),
          content: Text('Hapus ${mapel.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(mapelProvider.notifier).deleteMapel(mapel.id);
                Navigator.pop(context);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}