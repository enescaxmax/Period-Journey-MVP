import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization.dart';
import '../../../app/router.dart';
import '../../../shared/providers.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/cycle_providers.dart';
import '../data/cycle_repository.dart';
import '../data/models.dart';
import 'calendar_page.dart';
import 'stats_page.dart';

class CycleHomePage extends ConsumerStatefulWidget {
  const CycleHomePage({
    super.key,
    required this.isGuest,
    this.onSignInRequested,
  });

  final bool isGuest;
  final VoidCallback? onSignInRequested;

  @override
  ConsumerState<CycleHomePage> createState() => _CycleHomePageState();
}

class _CycleHomePageState extends ConsumerState<CycleHomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final titles = [
      localization.t('home_title'),
      localization.t('calendar_title'),
      localization.t('stats_title'),
    ];

    final pages = [
      _HomeTab(
        onOpenLogPage: (date) =>
            Navigator.of(context).pushNamed(AppRouter.logDay, arguments: date),
      ),
      const CalendarPage(),
      const StatsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          if (widget.isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(label: Text(localization.t('guest_mode_badge'))),
                    if (widget.onSignInRequested != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: widget.onSignInRequested,
                        child: Text(localization.t('signin_button')),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            TextButton(
              onPressed: () async {
                await ref.read(firebaseAuthProvider)?.signOut();
              },
              child: Text(localization.t('signout_button')),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.favorite),
              label: localization.t('home_title')),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month),
              label: localization.t('calendar_title')),
          NavigationDestination(
              icon: const Icon(Icons.insights),
              label: localization.t('stats_title')),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab({required this.onOpenLogPage});

  final ValueChanged<DateTime> onOpenLogPage;

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  // TODO: Integrate local notifications for daily logging reminders.
  static const _symptomOptions = ['Cramps', 'Bloating', 'Headache', 'Fatigue'];
  static const _moodOptions = ['Calm', 'Happy', 'Tired', 'Irritable'];

  bool _isPeriod = false;
  FlowLevel _flow = FlowLevel.none;
  List<String> _symptoms = const [];
  List<String> _moods = const [];
  final TextEditingController _notesController = TextEditingController();
  bool _formDirty = false;
  CycleLog? _currentLog;

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<List<CycleLog>>>(cycleLogsProvider, (previous, next) {
      final logs = next.asData?.value;
      if (logs == null) {
        return;
      }
      _hydrateWithLogs(logs);
    });
  }

  void _hydrateWithLogs(List<CycleLog> logs) {
    final todayLog = findLogForDate(logs, DateTime.now());
    if (!_formDirty || todayLog != null) {
      final effectiveLog = todayLog ?? CycleLog.forDate(DateTime.now());
      setState(() {
        _currentLog = effectiveLog;
        _isPeriod = effectiveLog.isPeriod;
        _flow = effectiveLog.flow;
        _symptoms = List<String>.from(effectiveLog.symptoms);
        _moods = List<String>.from(effectiveLog.moods);
        _notesController.text = effectiveLog.notes ?? '';
        _formDirty = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_formDirty) {
      setState(() => _formDirty = true);
    }
  }

  Future<void> _save() async {
    final repository = ref.read(cycleRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final localization = AppLocalizations.of(context);
    final log = (_currentLog ?? CycleLog.forDate(DateTime.now())).copyWith(
      userId: user?.uid ?? 'guest',
      isPeriod: _isPeriod,
      flow: _isPeriod ? _flow : FlowLevel.none,
      symptoms: _symptoms,
      moods: _moods,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await repository.saveLog(log);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localization.t('log_saved_message'))),
    );
    setState(() {
      _formDirty = false;
      _currentLog = log;
    });
  }

  Future<void> _deleteLog() async {
    final log = _currentLog;
    if (log == null) {
      return;
    }
    final repository = ref.read(cycleRepositoryProvider);
    final localization = AppLocalizations.of(context);
    await repository.deleteLog(log.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localization.t('log_deleted_message'))),
    );
    setState(() {
      _formDirty = false;
      _currentLog = null;
      _isPeriod = false;
      _flow = FlowLevel.none;
      _symptoms = const [];
      _moods = const [];
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final logsAsync = ref.watch(cycleLogsProvider);
    final logs =
        logsAsync.maybeWhen(data: (value) => value, orElse: () => <CycleLog>[]);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localization.t('log_day_title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(localization.t('today_label')),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(localization.t('is_period_label')),
                  value: _isPeriod,
                  onChanged: (value) {
                    setState(() {
                      _isPeriod = value;
                      if (!value) {
                        _flow = FlowLevel.none;
                      }
                    });
                    _markDirty();
                  },
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: _isPeriod ? 1 : 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(localization.t('flow_label'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ChoiceChipGroup(
                        options: FlowLevel.values.map((e) => e.label).toList(),
                        selected: _flow.label,
                        onSelected: (value) {
                          if (!_isPeriod) {
                            return;
                          }
                          setState(() => _flow = FlowLevelX.fromLabel(value));
                          _markDirty();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(localization.t('symptoms_label'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                FilterChipGroup(
                  options: _symptomOptions,
                  selectedValues: _symptoms,
                  onSelectionChanged: (values) {
                    setState(() => _symptoms = values);
                    _markDirty();
                  },
                ),
                const SizedBox(height: 16),
                Text(localization.t('moods_label'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                FilterChipGroup(
                  options: _moodOptions,
                  selectedValues: _moods,
                  onSelectionChanged: (values) {
                    setState(() => _moods = values);
                    _markDirty();
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration:
                      InputDecoration(labelText: localization.t('notes_label')),
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: localization.t('save_button'),
                        onPressed: _save,
                      ),
                    ),
                    if (_currentLog != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: localization.t('delete_log'),
                        onPressed: _deleteLog,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => widget.onOpenLogPage(DateTime.now()),
                    child: Text(localization.t('log_today_action')),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          logs.isEmpty
              ? localization.t('log_home_empty_state')
              : localization.t('recent_logs_title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (logs.isNotEmpty)
          ...logs.reversed
              .take(5)
              .map((log) => _LogListTile(log: log))
              .toList(),
      ],
    );
  }
}

class _LogListTile extends StatelessWidget {
  const _LogListTile({required this.log});

  final CycleLog log;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final subtitle = <String>[];
    if (log.isPeriod) {
      subtitle.add('${localization.t('flow_label')}: ${log.flow.label}');
    }
    if (log.symptoms.isNotEmpty) {
      subtitle.add(
          '${localization.t('symptoms_label')}: ${log.symptoms.join(', ')}');
    }
    if (log.moods.isNotEmpty) {
      subtitle.add('${localization.t('moods_label')}: ${log.moods.join(', ')}');
    }
    if ((log.notes ?? '').isNotEmpty) {
      subtitle.add('${localization.t('notes_label')}: ${log.notes}');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(AppDateUtils.formatMedium(log.date)),
        subtitle: subtitle.isEmpty ? null : Text(subtitle.join(' | ')),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () {
            Navigator.of(context)
                .pushNamed(AppRouter.logDay, arguments: log.date);
          },
        ),
      ),
    );
  }
}
