import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cycle_repository.dart';
import 'models.dart';

final cycleSettingsProvider =
    AsyncNotifierProvider<CycleSettingsNotifier, CycleSettings?>(
  CycleSettingsNotifier.new,
);

class CycleSettingsNotifier extends AsyncNotifier<CycleSettings?> {
  static const _cycleLengthKey = 'cycle_length_days';
  static const _periodLengthKey = 'period_length_days';

  SharedPreferences? _prefs;

  @override
  Future<CycleSettings?> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final local = _readFromPrefs();
    final repository = ref.watch(cycleRepositoryProvider);
    try {
      final remote = await repository.loadSettings();
      if (remote != null) {
        await _writeToPrefs(remote);
        return remote;
      }
    } catch (_) {
      // Swallow to keep guest mode resilient.
    }
    return local;
  }

  Future<void> updateSettings(CycleSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _writeToPrefs(settings);
      try {
        await ref.read(cycleRepositoryProvider).saveSettings(settings);
      } catch (_) {
        // Ignore when remote storage is unavailable.
      }
      return settings;
    });
  }

  CycleSettings? _readFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      return null;
    }
    final cycleLength = prefs.getInt(_cycleLengthKey);
    final periodLength = prefs.getInt(_periodLengthKey);
    if (cycleLength == null || periodLength == null) {
      return null;
    }
    return CycleSettings(
        averageCycleLength: cycleLength, periodLength: periodLength);
  }

  Future<void> _writeToPrefs(CycleSettings settings) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setInt(_cycleLengthKey, settings.averageCycleLength);
    await prefs.setInt(_periodLengthKey, settings.periodLength);
  }
}
