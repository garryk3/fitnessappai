/// Значения, введённые пользователем для текущего подхода.
///
/// Набор заполненных полей зависит от типа упражнения:
/// strength → [reps] + [weightKg]; plank → [durationSeconds];
/// running → [durationSeconds] + [distanceMeters].
///
/// [side] указывает сторону для упражнений «по сторонам» ('left'/'right').
class WorkoutSetInput {
  const WorkoutSetInput({
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.side,
  });

  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final String? side;

  WorkoutSetInput copyWith({
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    String? side,
  }) {
    return WorkoutSetInput(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      side: side ?? this.side,
    );
  }
}
