import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers.dart';
import 'firestore_cycle_repository.dart';
import 'mock_cycle_repository.dart';
import 'models.dart';

abstract class CycleRepository {
  Stream<List<CycleLog>> watchLogs();

  Future<List<CycleLog>> fetchLogs();

  Future<void> saveLog(CycleLog log);

  Future<void> deleteLog(String id);

  Stream<List<CyclePeriod>> watchCycles();

  Future<List<CyclePeriod>> fetchCycles();

  Future<void> saveCycle(CyclePeriod cycle);

  Future<void> deleteCycle(String id);

  Future<CycleSettings?> loadSettings();

  Future<void> saveSettings(CycleSettings settings);
}

final mockCycleRepositoryProvider = Provider<MockCycleRepository>((ref) {
  final repo = MockCycleRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final firestoreCycleRepositoryProvider = Provider<CycleRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  final firebaseReady = ref.watch(firebaseAvailabilityProvider);
  if (!firebaseReady || user == null) {
    return null;
  }
  final repo = FirestoreCycleRepository(userId: user.uid);
  ref.onDispose(() {
    if (repo is FirestoreCycleRepository) {
      repo.dispose();
    }
  });
  return repo;
});

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final firestore = ref.watch(firestoreCycleRepositoryProvider);
  if (firestore != null) {
    return firestore;
  }
  return ref.watch(mockCycleRepositoryProvider);
});

class CycleRepositoryMigrator {
  const CycleRepositoryMigrator();

  Future<void> migrate({
    required CycleRepository from,
    required CycleRepository to,
    required String userId,
  }) async {
    final logs = await from.fetchLogs();
    final cycles = await from.fetchCycles();
    final settings = await from.loadSettings();

    for (final log in logs) {
      await to.saveLog(log.copyWith(userId: userId));
    }
    for (final cycle in cycles) {
      await to.saveCycle(cycle.copyWith(userId: userId));
    }
    if (settings != null) {
      await to.saveSettings(settings);
    }
  }
}

final cycleRepositoryMigratorProvider =
    Provider((_) => const CycleRepositoryMigrator());
