/// Параметры одиночного упражнения для старта тренировки.
///
/// Заполняются на экране [SingleExerciseParamsScreen] и передаются в
/// `WorkoutRunController` для построения [ProgramDayExercise].
class SingleExerciseParams {
  const SingleExerciseParams({
    this.sets,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.restSeconds,
  });

  final int? sets;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? restSeconds;
}
