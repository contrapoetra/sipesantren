import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/aktivitas_kelas_model.dart';
import 'package:sipesantren/core/repositories/aktivitas_kelas_repository.dart';

class AktivitasKelasNotifier extends StateNotifier<AsyncValue<List<AktivitasKelasModel>>> {
  final AktivitasKelasRepository _repository;
  final String kelasId;

  AktivitasKelasNotifier(this._repository, this.kelasId) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      await _repository.fetchFromFirestore(kelasId);
      final data = await _repository.getActivitiesByKelas(kelasId);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addActivity(AktivitasKelasModel activity) async {
    await _repository.addActivity(activity);
    await refresh();
  }

  Future<void> deleteActivity(String id) async {
    await _repository.deleteActivity(id);
    await refresh();
  }
}

final aktivitasKelasProvider = StateNotifierProvider.family<AktivitasKelasNotifier, AsyncValue<List<AktivitasKelasModel>>, String>((ref, kelasId) {
  return AktivitasKelasNotifier(ref.watch(aktivitasKelasRepositoryProvider), kelasId);
});
