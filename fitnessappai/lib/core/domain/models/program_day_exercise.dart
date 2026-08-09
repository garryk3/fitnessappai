/// Упражнение внутри тренировочного дня.
class ProgramDayExercise {
  const ProgramDayExercise({
    this.id,
    required this.dayId,
    this.exerciseId,
    required this.orderIndex,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
    this.distanceMeters,
    this.restSeconds,
    this.isAlternative = false,
  });

  final int? id;
  final int dayId;
  final int? exerciseId;

  /// Порядок в списке дня.
  final int orderIndex;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;
  final double? distanceMeters;
  final int? restSeconds;

  /// true — из альтернативного набора (заменяет основной при выборе варианта).
  final bool isAlternative;

  ProgramDayExercise copyWith({
    int? id,
    int? dayId,
    int? exerciseId,
    int? orderIndex,
    int? sets,
    int? reps,
    int? durationSeconds,
    double? weightKg,
    double? distanceMeters,
    int? restSeconds,
    bool? isAlternative,
    bool clearId = false,
    bool clearExerciseId = false,
  }) {
    return ProgramDayExercise(
      id: clearId ? null : id ?? this.id,
      dayId: dayId ?? this.dayId,
      exerciseId: clearExerciseId ? null : exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weightKg: weightKg ?? this.weightKg,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      restSeconds: restSeconds ?? this.restSeconds,
      isAlternative: isAlternative ?? this.isAlternative,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProgramDayExercise &&
            other.id == id &&
            other.dayId == dayId &&
            other.exerciseId == exerciseId &&
            other.orderIndex == orderIndex &&
            other.sets == sets &&
            other.reps == reps &&
            other.durationSeconds == durationSeconds &&
            other.weightKg == weightKg &&
            other.distanceMeters == distanceMeters &&
            other.restSeconds == restSeconds &&
            other.isAlternative == isAlternative;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      dayId,
      exerciseId,
      orderIndex,
      sets,
      reps,
      durationSeconds,
      weightKg,
      distanceMeters,
      restSeconds,
      isAlternative,
    );
  }

  @override
  String toString() =>
      'ProgramDayExercise(id: $id, dayId: $dayId, exerciseId: $exerciseId, orderIndex: $orderIndex, isAlternative: $isAlternative)';
}
