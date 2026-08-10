import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';

/// Упражнение для тренировочной сессии: позиция дня + данные упражнения.
///
/// Позиция хранит запланированные метрики, а [exercise] — имя и тип,
/// которые копируются в результат подхода.
class WorkoutExercise {
  const WorkoutExercise({required this.position, required this.exercise});

  final ProgramDayExercise position;
  final Exercise exercise;

  int? get id => exercise.id;
  String get name => exercise.name;
  ExerciseType get type => exercise.type;

  /// Запланированное количество подходов.
  int get sets => position.sets ?? 1;

  /// Отдых после подхода в секундах (0, если не задан).
  int get restSeconds => position.restSeconds ?? 0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkoutExercise &&
            other.position == position &&
            other.exercise == exercise;
  }

  @override
  int get hashCode => Object.hash(position, exercise);

  @override
  String toString() =>
      'WorkoutExercise(name: $name, type: $type, sets: $sets)';
}
