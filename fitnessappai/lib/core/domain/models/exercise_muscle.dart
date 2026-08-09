/// Степень нагрузки на мышцу в упражнении.
enum MuscleIntensity { primary, secondary }

/// Привязка мышечной группы к упражнению.
class ExerciseMuscle {
  const ExerciseMuscle({
    required this.exerciseId,
    required this.muscleGroupId,
    required this.intensity,
  });

  final int exerciseId;
  final int muscleGroupId;
  final MuscleIntensity intensity;

  ExerciseMuscle copyWith({
    int? exerciseId,
    int? muscleGroupId,
    MuscleIntensity? intensity,
  }) {
    return ExerciseMuscle(
      exerciseId: exerciseId ?? this.exerciseId,
      muscleGroupId: muscleGroupId ?? this.muscleGroupId,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExerciseMuscle &&
            other.exerciseId == exerciseId &&
            other.muscleGroupId == muscleGroupId &&
            other.intensity == intensity;
  }

  @override
  int get hashCode => Object.hash(exerciseId, muscleGroupId, intensity);

  @override
  String toString() =>
      'ExerciseMuscle(exerciseId: $exerciseId, muscleGroupId: $muscleGroupId, intensity: $intensity)';
}
