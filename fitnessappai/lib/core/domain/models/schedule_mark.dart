/// Статус отметки в планировщике недели.
///
/// [rescheduled] — тренировка этой недели была перенесена на другой день,
/// поэтому в своей неделе источник показывается пустым (задача 47.3).
/// Хранится как TEXT (`byName`), новое значение миграции не требует.
enum ScheduleMarkStatus { skipped, rescheduled }

/// Отметка пропуска тренировочного дня на неделе.
class ScheduleMark {
  const ScheduleMark({
    this.id,
    required this.programDayId,
    required this.weekStart,
    this.status = ScheduleMarkStatus.skipped,
  });

  final int? id;
  final int programDayId;

  /// Дата понедельника недели.
  final DateTime weekStart;
  final ScheduleMarkStatus status;

  ScheduleMark copyWith({
    int? id,
    int? programDayId,
    DateTime? weekStart,
    ScheduleMarkStatus? status,
    bool clearId = false,
  }) {
    return ScheduleMark(
      id: clearId ? null : id ?? this.id,
      programDayId: programDayId ?? this.programDayId,
      weekStart: weekStart ?? this.weekStart,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScheduleMark &&
            other.id == id &&
            other.programDayId == programDayId &&
            other.weekStart == weekStart &&
            other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, programDayId, weekStart, status);

  @override
  String toString() =>
      'ScheduleMark(id: $id, programDayId: $programDayId, weekStart: $weekStart, status: $status)';
}
