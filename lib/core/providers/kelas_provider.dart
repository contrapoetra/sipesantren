import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/kelas_model.dart';
import 'package:sipesantren/core/repositories/kelas_repository.dart';

// Helper to refresh the list
class KelasNotifier extends StateNotifier<AsyncValue<List<KelasModel>>> {
  final KelasRepository _repository;
  
  KelasNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      await _repository.fetchFromFirestore(); // Try to sync first
      final data = await _repository.getKelasList();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addKelas(KelasModel kelas) async {
    await _repository.addKelas(kelas);
    await refresh();
  }

  Future<void> updateKelas(KelasModel kelas) async {
    await _repository.updateKelas(kelas);
    await refresh();
  }

  Future<void> deleteKelas(String id) async {
    await _repository.deleteKelas(id);
    await refresh();
  }
}

final kelasProvider = StateNotifierProvider<KelasNotifier, AsyncValue<List<KelasModel>>>((ref) {
  return KelasNotifier(ref.watch(kelasRepositoryProvider));
});
