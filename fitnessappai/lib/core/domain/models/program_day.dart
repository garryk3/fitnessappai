/// Тренировочный день программы.
class ProgramDay {
  const ProgramDay({
    this.id,
    required this.programId,
    required this.dayIndex,
    this.dayOfWeek,
  });

  final int? id;

  /// Родительская программа.
  final int programId;

  /// Порядковый номер дня: 0–6.
  final int dayIndex;

  /// День недели для расписания: 1 = Пн … 7 = Вс, null — не привязан.
  final int? dayOfWeek;

  ProgramDay copyWith({
    int? id,
    int? programId,
    int? dayIndex,
    int? dayOfWeek,
    bool clearId = false,
    bool clearDayOfWeek = false,
  }) {
    return ProgramDay(
      id: clearId ? null : id ?? this.id,
      programId: programId ?? this.programId,
      dayIndex: dayIndex ?? this.dayIndex,
      dayOfWeek: clearDayOfWeek ? null : dayOfWeek ?? this.dayOfWeek,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProgramDay &&
            other.id == id &&
            other.programId == programId &&
            other.dayIndex == dayIndex &&
            other.dayOfWeek == dayOfWeek;
  }

  @override
  int get hashCode => Object.hash(id, programId, dayIndex, dayOfWeek);

  @override
  String toString() =>
      'ProgramDay(id: $id, programId: $programId, dayIndex: $dayIndex)';
}
