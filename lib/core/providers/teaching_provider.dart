import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/teaching_assignment_model.dart';
import 'package:sipesantren/core/repositories/teaching_repository.dart';

class TeachingNotifier extends StateNotifier<AsyncValue<List<TeachingAssignmentModel>>> {
  final TeachingRepository _repository;

  TeachingNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      await _repository.fetchFromFirestore();
      final data = await _repository.getAssignments();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAssignment(TeachingAssignmentModel assignment) async {
    await _repository.addAssignment(assignment);
    await refresh();
  }

  Future<void> deleteAssignment(String id) async {
    await _repository.deleteAssignment(id);
    await refresh();
  }
}

// Global list of all assignments
final teachingProvider = StateNotifierProvider<TeachingNotifier, AsyncValue<List<TeachingAssignmentModel>>>((ref) {
  return TeachingNotifier(ref.watch(teachingRepositoryProvider));
});

// Family provider to get assignments for a specific class
final assignmentsByKelasProvider = Provider.family<List<TeachingAssignmentModel>, String>((ref, kelasId) {
  final allAssignments = ref.watch(teachingProvider).asData?.value ?? [];
  return allAssignments.where((a) => a.kelasId == kelasId).toList();
});
