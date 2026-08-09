import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/validators/validation_result.dart';

/// Валидация упражнения.
class ExerciseValidator {
  static const int maxNameLength = 100;

  ValidationResult validate(Exercise exercise) {
    final errors = <String>[];
    final name = exercise.name.trim();
    if (name.isEmpty) {
      errors.add('Название упражнения обязательно');
    } else if (name.length > maxNameLength) {
      errors.add('Название не должно превышать $maxNameLength символов');
    }
    return ValidationResult(errors);
  }
}
