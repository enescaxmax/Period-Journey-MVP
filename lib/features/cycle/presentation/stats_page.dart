import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization.dart';
import '../../../shared/utils/date_utils.dart';
import '../data/cycle_providers.dart';
import '../data/models.dart';
import '../data/settings_controller.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final stats = ref.watch(cycleStatsProvider);
    final settingsAsync = ref.watch(cycleSettingsProvider);
    final settings = settingsAsync.asData?.value;
    final daysUnit = localization.t('days_unit');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (settingsAsync.isLoading) const LinearProgressIndicator(),
        Text(localization.t('settings_title'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (settings != null) ...[
          _StatCard(
            title: localization.t('average_cycle_length_label'),
            value: '${settings.averageCycleLength} $daysUnit',
          ),
          _StatCard(
            title: localization.t('period_length_label'),
            value: '${settings.periodLength} $daysUnit',
          ),
        ],
        const SizedBox(height: 24),
        Text(localization.t('stats_title'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _StatCard(
          title: localization.t('average_cycle_length_stat'),
          value: stats.averageCycleLength == 0
              ? '-'
              : '${stats.averageCycleLength.toStringAsFixed(1)} $daysUnit',
        ),
        _StatCard(
          title: localization.t('average_period_length_stat'),
          value: stats.averagePeriodLength == 0
              ? '-'
              : '${stats.averagePeriodLength.toStringAsFixed(1)} $daysUnit',
        ),
        _StatCard(
          title: localization.t('next_period_prediction'),
          value: stats.predictedNextPeriod == null
              ? '-'
              : AppDateUtils.formatFull(stats.predictedNextPeriod!),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
