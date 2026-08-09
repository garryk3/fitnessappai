import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/validators/validation_result.dart';

/// Валидация структуры программы: дни 1–7, уникальный dayIndex,
/// у каждого дня >= 1 основного (не альтернативного) упражнения.
class ProgramValidator {
  static const int minDays = 1;
  static const int maxDays = 7;

  ValidationResult validate({
    required Program program,
    required List<ProgramDay> days,
    required Map<int, List<ProgramDayExercise>> exercisesByDayIndex,
  }) {
    final errors = <String>[];
    if (program.name.trim().isEmpty) {
      errors.add('Название программы обязательно');
    }

    if (days.length < minDays || days.length > maxDays) {
      errors.add('Количество дней должно быть от $minDays до $maxDays');
    }
    if (days.length != program.daysCount) {
      errors.add('daysCount не совпадает с количеством дней');
    }

    final indexes = days.map((d) => d.dayIndex).toList();
    if (indexes.toSet().length != indexes.length) {
      errors.add('Индексы дней должны быть уникальными');
    }

    for (final day in days) {
      final items = exercisesByDayIndex[day.dayIndex] ?? const [];
      final primaryCount = items.where((e) => !e.isAlternative).length;
      if (primaryCount < 1) {
        errors.add(
          'У дня ${day.dayIndex + 1} должно быть хотя бы одно '
          'основное упражнение',
        );
      }
    }

    return ValidationResult(errors);
  }
}
