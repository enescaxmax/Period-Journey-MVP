import 'dart:async';

import 'package:collection/collection.dart';

import 'cycle_repository.dart';
import 'models.dart';

class MockCycleRepository implements CycleRepository {
  MockCycleRepository() {
    _emitLogs();
    _emitCycles();
  }

  final _logs = <CycleLog>[];
  final _cycles = <CyclePeriod>[];
  CycleSettings? _settings;

  final _logsController = StreamController<List<CycleLog>>.broadcast();
  final _cyclesController = StreamController<List<CyclePeriod>>.broadcast();

  void dispose() {
    unawaited(_logsController.close());
    unawaited(_cyclesController.close());
  }

  @override
  Stream<List<CycleLog>> watchLogs() => _logsController.stream;

  @override
  Future<List<CycleLog>> fetchLogs() async =>
      List<CycleLog>.unmodifiable(_logs);

  @override
  Future<void> saveLog(CycleLog log) async {
    final index = _logs.indexWhere((item) => item.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
    } else {
      _logs.add(log);
    }
    _logs.sort((a, b) => a.date.compareTo(b.date));
    _emitLogs();
  }

  @override
  Future<void> deleteLog(String id) async {
    _logs.removeWhere((item) => item.id == id);
    _emitLogs();
  }

  void _emitLogs() {
    _logsController.add(List<CycleLog>.unmodifiable(_logs));
  }

  @override
  Stream<List<CyclePeriod>> watchCycles() => _cyclesController.stream;

  @override
  Future<List<CyclePeriod>> fetchCycles() async =>
      List<CyclePeriod>.unmodifiable(_cycles);

  @override
  Future<void> saveCycle(CyclePeriod cycle) async {
    final index = _cycles.indexWhere((item) => item.id == cycle.id);
    if (index >= 0) {
      _cycles[index] = cycle;
    } else {
      _cycles.add(cycle);
    }
    _cycles.sort((a, b) => a.startDate.compareTo(b.startDate));
    _emitCycles();
  }

  @override
  Future<void> deleteCycle(String id) async {
    _cycles.removeWhere((item) => item.id == id);
    _emitCycles();
  }

  void _emitCycles() {
    _cyclesController.add(List<CyclePeriod>.unmodifiable(_cycles));
  }

  @override
  Future<CycleSettings?> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(CycleSettings settings) async {
    _settings = settings;
  }
}
