import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum FlowLevel { none, light, medium, heavy }

extension FlowLevelX on FlowLevel {
  String get label {
    switch (this) {
      case FlowLevel.none:
        return 'None';
      case FlowLevel.light:
        return 'Light';
      case FlowLevel.medium:
        return 'Medium';
      case FlowLevel.heavy:
        return 'Heavy';
    }
  }

  static FlowLevel fromLabel(String value) {
    final normalized = value.toLowerCase();
    return FlowLevel.values.firstWhere(
      (level) => level.label.toLowerCase() == normalized,
      orElse: () => FlowLevel.none,
    );
  }
}

class CycleLog {
  CycleLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.isPeriod,
    required this.flow,
    required this.symptoms,
    required this.moods,
    this.notes,
  });

  factory CycleLog.forDate(DateTime date, {String userId = 'guest'}) {
    return CycleLog(
      id: defaultLogIdForDate(date),
      userId: userId,
      date: DateTime(date.year, date.month, date.day),
      isPeriod: false,
      flow: FlowLevel.none,
      symptoms: const [],
      moods: const [],
      notes: null,
    );
  }

  final String id;
  final String userId;
  final DateTime date;
  final bool isPeriod;
  final FlowLevel flow;
  final List<String> symptoms;
  final List<String> moods;
  final String? notes;

  CycleLog copyWith({
    String? id,
    String? userId,
    DateTime? date,
    bool? isPeriod,
    FlowLevel? flow,
    List<String>? symptoms,
    List<String>? moods,
    String? notes,
  }) {
    return CycleLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      isPeriod: isPeriod ?? this.isPeriod,
      flow: flow ?? this.flow,
      symptoms: symptoms ?? List<String>.from(this.symptoms),
      moods: moods ?? List<String>.from(this.moods),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'isPeriod': isPeriod,
      'flow': flow.label,
      'symptoms': symptoms,
      'moods': moods,
      'notes': notes,
    }..removeWhere((key, value) => value == null);
  }

  factory CycleLog.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      throw ArgumentError('Invalid date value: $rawDate');
    }

    return CycleLog(
      id: map['id'] as String? ?? defaultLogIdForDate(date),
      userId: map['userId'] as String? ?? 'guest',
      date: DateTime(date.year, date.month, date.day),
      isPeriod: map['isPeriod'] as bool? ?? false,
      flow:
          FlowLevelX.fromLabel(map['flow'] as String? ?? FlowLevel.none.label),
      symptoms: (map['symptoms'] as List<dynamic>? ?? const []).cast<String>(),
      moods: (map['moods'] as List<dynamic>? ?? const []).cast<String>(),
      notes: map['notes'] as String?,
    );
  }

  static String defaultLogIdForDate(DateTime date) {
    return DateFormat('yyyyMMdd')
        .format(DateTime(date.year, date.month, date.day));
  }
}

class CyclePeriod {
  CyclePeriod({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
  });

  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;

  CyclePeriod copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CyclePeriod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
    }..removeWhere((key, value) => value == null);
  }

  factory CyclePeriod.fromMap(Map<String, dynamic> map) {
    DateTime readDate(dynamic raw) {
      if (raw == null) {
        return DateTime.now();
      }
      if (raw is Timestamp) {
        return raw.toDate();
      }
      if (raw is DateTime) {
        return raw;
      }
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      throw ArgumentError('Invalid date value: $raw');
    }

    return CyclePeriod(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? 'guest',
      startDate: readDate(map['startDate']),
      endDate: map['endDate'] == null ? null : readDate(map['endDate']),
    );
  }
}

class CycleSettings {
  const CycleSettings({
    required this.averageCycleLength,
    required this.periodLength,
  });

  final int averageCycleLength;
  final int periodLength;

  CycleSettings copyWith({int? averageCycleLength, int? periodLength}) {
    return CycleSettings(
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      periodLength: periodLength ?? this.periodLength,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageCycleLength': averageCycleLength,
      'periodLength': periodLength,
    };
  }

  factory CycleSettings.fromMap(Map<String, dynamic> map) {
    return CycleSettings(
      averageCycleLength: (map['averageCycleLength'] as num?)?.toInt() ?? 28,
      periodLength: (map['periodLength'] as num?)?.toInt() ?? 5,
    );
  }
}

class CycleStats {
  const CycleStats({
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.predictedNextPeriod,
  });

  final double averageCycleLength;
  final double averagePeriodLength;
  final DateTime? predictedNextPeriod;
}

class CycleStatsCalculator {
  const CycleStatsCalculator();

  CycleStats calculate(List<CycleLog> logs) {
    if (logs.isEmpty) {
      return const CycleStats(
        averageCycleLength: 0,
        averagePeriodLength: 0,
        predictedNextPeriod: null,
      );
    }

    final sortedLogs = [...logs]..sort((a, b) => a.date.compareTo(b.date));

    final List<DateTime> periodStarts = [];
    final List<int> periodLengths = [];

    DateTime? currentStart;
    int currentLength = 0;
    DateTime? lastPeriodDay;

    for (final log in sortedLogs) {
      final logDate = _dateOnly(log.date);
      if (log.isPeriod) {
        if (currentStart == null) {
          currentStart = logDate;
        } else if (lastPeriodDay != null &&
            !_isConsecutive(lastPeriodDay!, logDate)) {
          periodStarts.add(currentStart);
          periodLengths.add(currentLength);
          currentStart = logDate;
          currentLength = 0;
        }
        currentLength += 1;
        lastPeriodDay = logDate;
      } else {
        if (currentStart != null) {
          periodStarts.add(currentStart);
          periodLengths.add(currentLength);
          currentStart = null;
          currentLength = 0;
          lastPeriodDay = null;
        }
      }
    }

    if (currentStart != null) {
      periodStarts.add(currentStart);
      periodLengths.add(currentLength == 0 ? 1 : currentLength);
    }

    final List<int> cycleLengths = [];
    for (var i = 1; i < periodStarts.length; i++) {
      final diff = periodStarts[i].difference(periodStarts[i - 1]).inDays;
      if (diff > 0) {
        cycleLengths.add(diff);
      }
    }

    double averageOf(List<int> values) {
      if (values.isEmpty) {
        return 0;
      }
      final startIndex = (values.length - 6).clamp(0, values.length);
      final slice = values.sublist(startIndex);
      final sum = slice.fold<int>(0, (acc, value) => acc + value);
      return sum / slice.length;
    }

    final averagedCycleLength = averageOf(cycleLengths);
    final averagedPeriodLength = averageOf(periodLengths);

    DateTime? predicted;
    if (periodStarts.isNotEmpty && averagedCycleLength > 0) {
      final lastStart = periodStarts.last;
      predicted = lastStart.add(Duration(days: averagedCycleLength.round()));
    }

    return CycleStats(
      averageCycleLength: averagedCycleLength,
      averagePeriodLength: averagedPeriodLength,
      predictedNextPeriod: predicted,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isConsecutive(DateTime previous, DateTime current) {
    final prevDay = _dateOnly(previous);
    final currentDay = _dateOnly(current);
    return currentDay.difference(prevDay).inDays == 1;
  }
}
