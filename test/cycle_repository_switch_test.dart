import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_journey/features/cycle/data/cycle_repository.dart';
import 'package:period_journey/features/cycle/data/mock_cycle_repository.dart';
import 'package:period_journey/features/cycle/data/models.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('Cycle repository switching', () {
    test('falls back to mock repository when firestore not available', () {
      final container = ProviderContainer(
        overrides: [
          firestoreCycleRepositoryProvider.overrideWith((ref) => null),
        ],
      );

      final repo = container.read(cycleRepositoryProvider);
      expect(repo, isA<MockCycleRepository>());
    });

    test('uses firestore repository when provided', () {
      final fakeRepository = _FakeRepository();
      final container = ProviderContainer(
        overrides: [
          firestoreCycleRepositoryProvider.overrideWith((ref) => fakeRepository),
          mockCycleRepositoryProvider.overrideWith((ref) => MockCycleRepository()),
        ],
      );

      final repo = container.read(cycleRepositoryProvider);
      expect(repo, same(fakeRepository));
    });
  });
}

class _FakeRepository implements CycleRepository {
  @override
  Future<void> deleteCycle(String id) async {}

  @override
  Future<void> deleteLog(String id) async {}

  @override
  Future<List<CyclePeriod>> fetchCycles() async => const [];

  @override
  Future<List<CycleLog>> fetchLogs() async => const [];

  @override
  Stream<List<CyclePeriod>> watchCycles() => const Stream.empty();

  @override
  Stream<List<CycleLog>> watchLogs() => const Stream.empty();

  @override
  Future<void> saveCycle(CyclePeriod cycle) async {}

  @override
  Future<void> saveLog(CycleLog log) async {}

  @override
  Future<CycleSettings?> loadSettings() async => null;

  @override
  Future<void> saveSettings(CycleSettings settings) async {}
}
