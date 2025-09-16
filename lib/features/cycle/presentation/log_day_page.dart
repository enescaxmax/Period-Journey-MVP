import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization.dart';
import '../../../shared/providers.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/cycle_providers.dart';
import '../data/cycle_repository.dart';
import '../data/models.dart';

class LogDayPage extends ConsumerStatefulWidget {
  const LogDayPage({super.key, this.date});

  final DateTime? date;

  @override
  ConsumerState<LogDayPage> createState() => _LogDayPageState();
}

class _LogDayPageState extends ConsumerState<LogDayPage> {
  static const _symptomOptions = ['Cramps', 'Bloating', 'Headache', 'Fatigue'];
  static const _moodOptions = ['Calm', 'Happy', 'Tired', 'Irritable'];

  late DateTime _selectedDate;
  bool _isPeriod = false;
  FlowLevel _flow = FlowLevel.none;
  List<String> _symptoms = const [];
  List<String> _moods = const [];
  final TextEditingController _notesController = TextEditingController();
  CycleLog? _log;

  @override
  void initState() {
    super.initState();
    _selectedDate = AppDateUtils.startOfDay(widget.date ?? DateTime.now());
    ref.listen<AsyncValue<List<CycleLog>>>(cycleLogsProvider, (previous, next) {
      final logs = next.asData?.value;
      if (logs == null) {
        return;
      }
      _hydrateFromLogs(logs);
    });
  }

  void _hydrateFromLogs(List<CycleLog> logs) {
    final existing = findLogForDate(logs, _selectedDate);
    setState(() {
      _log = existing;
      _isPeriod = existing?.isPeriod ?? false;
      _flow = existing?.flow ?? FlowLevel.none;
      _symptoms = List<String>.from(existing?.symptoms ?? const []);
      _moods = List<String>.from(existing?.moods ?? const []);
      _notesController.text = existing?.notes ?? '';
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.utc(2018, 1, 1),
      lastDate: DateTime.utc(2040, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _selectedDate = AppDateUtils.startOfDay(selected));
      final logs =
          ref.read(cycleLogsProvider).asData?.value ?? const <CycleLog>[];
      _hydrateFromLogs(logs);
    }
  }

  Future<void> _save() async {
    final repository = ref.read(cycleRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final localization = AppLocalizations.of(context);
    final log = (_log ?? CycleLog.forDate(_selectedDate)).copyWith(
      userId: user?.uid ?? 'guest',
      date: _selectedDate,
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
    setState(() => _log = log);
  }

  Future<void> _delete() async {
    final log = _log;
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
      _log = null;
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
    final dateLabel = AppDateUtils.formatFull(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('log_day_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: localization.t('log_date_label'),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(dateLabel, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(localization.t('is_period_label')),
            value: _isPeriod,
            onChanged: (value) => setState(() {
              _isPeriod = value;
              if (!value) {
                _flow = FlowLevel.none;
              }
            }),
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
            onSelectionChanged: (values) => setState(() => _symptoms = values),
          ),
          const SizedBox(height: 16),
          Text(localization.t('moods_label'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilterChipGroup(
            options: _moodOptions,
            selectedValues: _moods,
            onSelectionChanged: (values) => setState(() => _moods = values),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration:
                InputDecoration(labelText: localization.t('notes_label')),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: localization.t('save_button'),
            onPressed: _save,
          ),
          if (_log != null)
            TextButton(
              onPressed: _delete,
              child: Text(localization.t('delete_log')),
            ),
        ],
      ),
    );
  }
}
