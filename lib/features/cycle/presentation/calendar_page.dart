import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/localization.dart';
import '../../../app/router.dart';
import '../../../shared/utils/date_utils.dart';
import '../data/cycle_providers.dart';
import '../data/models.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  // TODO: Enhance the calendar with a heatmap-style visual.
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final logsAsync = ref.watch(cycleLogsProvider);
    final logs =
        logsAsync.maybeWhen(data: (value) => value, orElse: () => <CycleLog>[]);

    final eventsByDay = <DateTime, List<CycleLog>>{};
    for (final log in logs) {
      final key = AppDateUtils.startOfDay(log.date);
      eventsByDay.putIfAbsent(key, () => []).add(log);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TableCalendar<CycleLog>(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2018, 1, 1),
            lastDay: DateTime.utc(2040, 12, 31),
            selectedDayPredicate: (day) =>
                _selectedDay != null &&
                AppDateUtils.isSameDay(day, _selectedDay!),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) =>
                eventsByDay[AppDateUtils.startOfDay(day)] ?? const [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              Navigator.of(context)
                  .pushNamed(AppRouter.logDay, arguments: selectedDay);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) {
                  return const SizedBox.shrink();
                }
                final hasPeriod = events.any((event) => event.isPeriod);
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasPeriod
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null)
            ..._buildLogDetails(localization,
                eventsByDay[AppDateUtils.startOfDay(_selectedDay!)] ?? []),
        ],
      ),
    );
  }

  List<Widget> _buildLogDetails(
      AppLocalizations localization, List<CycleLog> logs) {
    if (logs.isEmpty) {
      return [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(localization.t('log_home_empty_state')),
        ),
      ];
    }
    return logs
        .map(
          (log) => Card(
            child: ListTile(
              title: Text(AppDateUtils.formatMedium(log.date)),
              subtitle: Text(
                [
                  if (log.isPeriod)
                    '${localization.t('flow_label')}: ${log.flow.label}',
                  if (log.symptoms.isNotEmpty)
                    '${localization.t('symptoms_label')}: ${log.symptoms.join(', ')}',
                  if (log.moods.isNotEmpty)
                    '${localization.t('moods_label')}: ${log.moods.join(', ')}',
                ].where((element) => element.isNotEmpty).join(' | '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRouter.logDay, arguments: log.date),
            ),
          ),
        )
        .toList();
  }
}
