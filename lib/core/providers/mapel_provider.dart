import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/mapel_model.dart';
import 'package:sipesantren/core/repositories/mapel_repository.dart';

class MapelNotifier extends StateNotifier<AsyncValue<List<MapelModel>>> {
  final MapelRepository _repository;

  MapelNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      await _repository.fetchFromFirestore();
      final data = await _repository.getMapelList();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMapel(MapelModel mapel) async {
    await _repository.addMapel(mapel);
    await refresh();
  }

  Future<void> updateMapel(MapelModel mapel) async {
    await _repository.updateMapel(mapel);
    await refresh();
  }

  Future<void> deleteMapel(String id) async {
    await _repository.deleteMapel(id);
    await refresh();
  }
}

final mapelProvider = StateNotifierProvider<MapelNotifier, AsyncValue<List<MapelModel>>>((ref) {
  return MapelNotifier(ref.watch(mapelRepositoryProvider));
});
