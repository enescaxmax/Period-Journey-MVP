import 'package:flutter_test/flutter_test.dart';

import 'package:period_journey/features/cycle/data/models.dart';

void main() {
  group('CycleStatsCalculator', () {
    test('computes averages from recent cycles', () {
      final calculator = const CycleStatsCalculator();
      final logs = <CycleLog>[];
      final baseDate = DateTime(2024, 1, 1);

      for (var cycleIndex = 0; cycleIndex < 3; cycleIndex++) {
        final start = baseDate.add(Duration(days: cycleIndex * 28));
        for (var day = 0; day < 5; day++) {
          final date = start.add(Duration(days: day));
          logs.add(
            CycleLog.forDate(date).copyWith(
              isPeriod: true,
              flow: FlowLevel.medium,
              symptoms: ['Cramps'],
            ),
          );
        }
      }

      final stats = calculator.calculate(logs);

      expect(stats.averageCycleLength, closeTo(28, 0.1));
      expect(stats.averagePeriodLength, closeTo(5, 0.1));
      expect(stats.predictedNextPeriod, DateTime(2024, 3, 25));
    });
  });
}
