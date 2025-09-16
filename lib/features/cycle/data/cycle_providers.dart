import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cycle_repository.dart';
import 'models.dart';

final cycleLogsProvider = StreamProvider<List<CycleLog>>((ref) {
  final repository = ref.watch(cycleRepositoryProvider);
  return repository.watchLogs();
});

final cyclePeriodsProvider = StreamProvider<List<CyclePeriod>>((ref) {
  final repository = ref.watch(cycleRepositoryProvider);
  return repository.watchCycles();
});

final cycleStatsProvider = Provider<CycleStats>((ref) {
  final logs = ref
      .watch(cycleLogsProvider)
      .maybeWhen(data: (value) => value, orElse: () => <CycleLog>[]);
  return const CycleStatsCalculator().calculate(logs);
});

CycleLog? findLogForDate(List<CycleLog> logs, DateTime date) {
  for (final log in logs) {
    if (log.date.year == date.year &&
        log.date.month == date.month &&
        log.date.day == date.day) {
      return log;
    }
  }
  return null;
}
