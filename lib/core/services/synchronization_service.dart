// lib/core/services/synchronization_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // Added import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'package:sipesantren/core/repositories/santri_repository.dart';
import 'package:sipesantren/core/repositories/penilaian_repository.dart';

class SynchronizationService {
  final SantriRepository _santriRepository;
  final PenilaianRepository _penilaianRepository;
  final Connectivity _connectivity;
  StreamSubscription? _connectivitySubscription;
  Timer? _syncTimer;

  SynchronizationService(this._santriRepository, this._penilaianRepository, this._connectivity) {
    _startListeningToConnectivity();
  }

  void _startListeningToConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      if (isOnline) {
        debugPrint('SynchronizationService: Connectivity changed to online. Attempting sync...');
        _triggerSync();
        _startPeriodicSync();
      } else {
        debugPrint('SynchronizationService: Connectivity changed to offline. Stopping periodic sync.');
        _stopPeriodicSync();
      }
    });
  }

  void _triggerSync() async {
    debugPrint("Triggering sync...");
    await _santriRepository.syncPendingChanges();
    await _penilaianRepository.syncPendingChanges();
  }

  void _startPeriodicSync() {
    _stopPeriodicSync();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('SynchronizationService: Periodic sync triggered.');
      _triggerSync();
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _stopPeriodicSync();
  }
}

final connectivityProvider = Provider((ref) => Connectivity());

final synchronizationServiceProvider = Provider((ref) {
  final santriRepo = ref.watch(santriRepositoryProvider);
  final penilaianRepo = ref.watch(penilaianRepositoryProvider);
  final connectivity = ref.watch(connectivityProvider);
  final service = SynchronizationService(santriRepo, penilaianRepo, connectivity);
  ref.onDispose(() => service.dispose());
  return service;
});
