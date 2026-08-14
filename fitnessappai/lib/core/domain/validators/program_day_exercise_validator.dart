import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/validators/validation_result.dart';

/// Валидация метрик упражнения в тренировочном дне по типу упражнения.
///
/// Метрики по типам: strength → sets + reps + weightKg;
/// bodyweight → sets + reps; plank → sets + durationSeconds;
/// running → distanceMeters + durationSeconds.
class ProgramDayExerciseValidator {
  ValidationResult validate(ProgramDayExercise item, ExerciseType type) {
    final errors = <String>[];
    if (item.sets == null || item.sets! < 1) {
      errors.add('Количество подходов должно быть >= 1');
    }
    switch (type) {
      case ExerciseType.strength:
        if (item.reps == null || item.reps! < 1) {
          errors.add('Количество повторений должно быть >= 1');
        }
        if (item.weightKg != null && item.weightKg! < 0) {
          errors.add('Вес не может быть отрицательным');
        }
      case ExerciseType.bodyweight:
        if (item.reps == null || item.reps! < 1) {
          errors.add('Количество повторений должно быть >= 1');
        }
      case ExerciseType.plank:
        if (item.durationSeconds == null || item.durationSeconds! < 1) {
          errors.add('Время удержания должно быть >= 1 с');
        }
      case ExerciseType.running:
        if (item.durationSeconds == null || item.durationSeconds! < 1) {
          errors.add('Продолжительность должна быть >= 1 с');
        }
        if (item.distanceMeters != null && item.distanceMeters! < 0) {
          errors.add('Дистанция не может быть отрицательной');
        }
    }
    return ValidationResult(errors);
  }
}
