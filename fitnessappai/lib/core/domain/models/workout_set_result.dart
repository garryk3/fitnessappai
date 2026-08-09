import 'package:fitnessappai/core/domain/models/exercise_type.dart';

/// Результат одного подхода в тренировочной сессии.
class WorkoutSetResult {
  const WorkoutSetResult({
    this.id,
    required this.sessionId,
    this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.setIndex,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    required this.completedAt,
  });

  final int? id;
  final int sessionId;
  final int? exerciseId;

  /// Копии названия и типа (сохраняются при удалении упражнения).
  final String exerciseName;
  final ExerciseType exerciseType;
  final int setIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final DateTime completedAt;

  WorkoutSetResult copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    String? exerciseName,
    ExerciseType? exerciseType,
    int? setIndex,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    DateTime? completedAt,
    bool clearId = false,
    bool clearExerciseId = false,
  }) {
    return WorkoutSetResult(
      id: clearId ? null : id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: clearExerciseId ? null : exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkoutSetResult &&
            other.id == id &&
            other.sessionId == sessionId &&
            other.exerciseId == exerciseId &&
            other.exerciseName == exerciseName &&
            other.exerciseType == exerciseType &&
            other.setIndex == setIndex &&
            other.reps == reps &&
            other.weightKg == weightKg &&
            other.durationSeconds == durationSeconds &&
            other.distanceMeters == distanceMeters &&
            other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sessionId,
      exerciseId,
      exerciseName,
      exerciseType,
      setIndex,
      reps,
      weightKg,
      durationSeconds,
      distanceMeters,
      completedAt,
    );
  }

  @override
  String toString() =>
      'WorkoutSetResult(id: $id, exerciseName: $exerciseName, setIndex: $setIndex)';
}
