/// Значения, введённые пользователем для текущего подхода.
///
/// Набор заполненных полей зависит от типа упражнения:
/// strength → [reps] + [weightKg]; plank → [durationSeconds];
/// running → [durationSeconds] + [distanceMeters].
class WorkoutSetInput {
  const WorkoutSetInput({
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
  });

  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;

  WorkoutSetInput copyWith({
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
  }) {
    return WorkoutSetInput(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
