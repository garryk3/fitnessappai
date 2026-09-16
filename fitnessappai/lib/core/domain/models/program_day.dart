/// Тренировочный день программы.
class ProgramDay {
  const ProgramDay({
    this.id,
    required this.programId,
    required this.dayIndex,
    this.dayOfWeek,
    this.warmupMinutes,
    this.title,
  });

  final int? id;

  /// Родительская программа.
  final int programId;

  /// Порядковый номер дня: 0–6.
  final int dayIndex;

  /// День недели для расписания: 1 = Пн … 7 = Вс, null — не привязан.
  final int? dayOfWeek;

  /// Продолжительность разминки перед тренировкой в минутах, null — нет.
  final int? warmupMinutes;

  /// Кастомное название дня тренировки, null — «День N».
  final String? title;

  ProgramDay copyWith({
    int? id,
    int? programId,
    int? dayIndex,
    int? dayOfWeek,
    int? warmupMinutes,
    String? title,
    bool clearId = false,
    bool clearDayOfWeek = false,
    bool clearWarmup = false,
    bool clearTitle = false,
  }) {
    return ProgramDay(
      id: clearId ? null : id ?? this.id,
      programId: programId ?? this.programId,
      dayIndex: dayIndex ?? this.dayIndex,
      dayOfWeek: clearDayOfWeek ? null : dayOfWeek ?? this.dayOfWeek,
      warmupMinutes: clearWarmup ? null : warmupMinutes ?? this.warmupMinutes,
      title: clearTitle ? null : title ?? this.title,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProgramDay &&
            other.id == id &&
            other.programId == programId &&
            other.dayIndex == dayIndex &&
            other.dayOfWeek == dayOfWeek &&
            other.warmupMinutes == warmupMinutes &&
            other.title == title;
  }

  @override
  int get hashCode =>
      Object.hash(id, programId, dayIndex, dayOfWeek, warmupMinutes, title);

  @override
  String toString() =>
      'ProgramDay(id: $id, programId: $programId, dayIndex: $dayIndex)';
}
