/// Выбранный набор упражнений в тренировочном дне.
enum WorkoutVariant { main, alternative }

/// Проведённая тренировочная сессия.
class WorkoutSession {
  const WorkoutSession({
    this.id,
    this.programId,
    required this.programName,
    this.programDayId,
    required this.dayIndex,
    this.variant = WorkoutVariant.main,
    required this.performedDate,
    required this.startedAt,
    required this.endedAt,
    this.status = 'completed',
  });

  final int? id;
  final int? programId;

  /// Копия названия программы (сохраняется при её удалении).
  final String programName;
  final int? programDayId;
  final int dayIndex;
  final WorkoutVariant variant;
  final DateTime performedDate;
  final DateTime startedAt;
  final DateTime endedAt;
  final String status;

  WorkoutSession copyWith({
    int? id,
    int? programId,
    String? programName,
    int? programDayId,
    int? dayIndex,
    WorkoutVariant? variant,
    DateTime? performedDate,
    DateTime? startedAt,
    DateTime? endedAt,
    String? status,
    bool clearId = false,
    bool clearProgramId = false,
    bool clearProgramDayId = false,
  }) {
    return WorkoutSession(
      id: clearId ? null : id ?? this.id,
      programId: clearProgramId ? null : programId ?? this.programId,
      programName: programName ?? this.programName,
      programDayId: clearProgramDayId
          ? null
          : programDayId ?? this.programDayId,
      dayIndex: dayIndex ?? this.dayIndex,
      variant: variant ?? this.variant,
      performedDate: performedDate ?? this.performedDate,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkoutSession &&
            other.id == id &&
            other.programId == programId &&
            other.programName == programName &&
            other.programDayId == programDayId &&
            other.dayIndex == dayIndex &&
            other.variant == variant &&
            other.performedDate == performedDate &&
            other.startedAt == startedAt &&
            other.endedAt == endedAt &&
            other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      programId,
      programName,
      programDayId,
      dayIndex,
      variant,
      performedDate,
      startedAt,
      endedAt,
      status,
    );
  }

  @override
  String toString() =>
      'WorkoutSession(id: $id, programName: $programName, dayIndex: $dayIndex, status: $status)';
}
