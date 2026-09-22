/// Значения, введённые пользователем для текущего подхода.
///
/// Набор заполненных полей зависит от типа упражнения:
/// strength → [reps] + [weightKg]; plank → [durationSeconds];
/// running → [durationSeconds] + [distanceMeters] + [avgPace] + [steps];
/// bike → [durationSeconds] + [distanceMeters] + [avgSpeed] + [avgCadence] +
/// [avgPulse] + [ascentMeters] + [descentMeters].
///
/// [side] указывает сторону для упражнений «по сторонам» ('left'/'right').
class WorkoutSetInput {
  const WorkoutSetInput({
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.avgSpeed,
    this.avgCadence,
    this.avgPulse,
    this.ascentMeters,
    this.descentMeters,
    this.avgPace,
    this.steps,
    this.side,
  });

  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? avgSpeed;
  final double? avgCadence;
  final int? avgPulse;
  final double? ascentMeters;
  final double? descentMeters;
  final double? avgPace;
  final int? steps;
  final String? side;

  WorkoutSetInput copyWith({
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    double? avgSpeed,
    double? avgCadence,
    int? avgPulse,
    double? ascentMeters,
    double? descentMeters,
    double? avgPace,
    int? steps,
    String? side,
  }) {
    return WorkoutSetInput(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      avgCadence: avgCadence ?? this.avgCadence,
      avgPulse: avgPulse ?? this.avgPulse,
      ascentMeters: ascentMeters ?? this.ascentMeters,
      descentMeters: descentMeters ?? this.descentMeters,
      avgPace: avgPace ?? this.avgPace,
      steps: steps ?? this.steps,
      side: side ?? this.side,
    );
  }
}
