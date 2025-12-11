import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/kelas_model.dart';
import 'package:sipesantren/core/providers/kelas_provider.dart';
import 'package:sipesantren/features/kelas/presentation/kelas_detail_page.dart';

class KelasListPage extends ConsumerWidget {
  const KelasListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelasAsyncValue = ref.watch(kelasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(kelasProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: kelasAsyncValue.when(
        data: (kelasList) {
          if (kelasList.isEmpty) {
            return const Center(child: Text('Belum ada data kelas.'));
          }
          return ListView.builder(
            itemCount: kelasList.length,
            itemBuilder: (context, index) {
              final kelas = kelasList[index];
              return ListTile(
                title: Text(kelas.name),
                subtitle: Text(kelas.waliKelasId != null ? 'Wali Kelas ID: ${kelas.waliKelasId}' : 'Belum ada Wali Kelas'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KelasDetailPage(kelas: kelas),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kelas'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nama Kelas (misal: 10A)'),
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

                ref.read(kelasProvider.notifier).addKelas(
                      KelasModel(id: '', name: name),
                    );
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}