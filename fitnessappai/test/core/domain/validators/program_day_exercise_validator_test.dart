import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/validators/program_day_exercise_validator.dart';

void main() {
  final validator = ProgramDayExerciseValidator();

  ProgramDayExercise build({
    int? sets = 3,
    int? reps = 8,
    int? durationSeconds,
    double? weightKg = 16,
    double? distanceMeters,
  }) {
    return ProgramDayExercise(
      dayId: 1,
      orderIndex: 0,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      weightKg: weightKg,
      distanceMeters: distanceMeters,
    );
  }

  group('strength', () {
    test('3x8 c весом валидно', () {
      expect(
        validator.validate(build(), ExerciseType.strength).isValid,
        isTrue,
      );
    });

    test('без повторений невалидно', () {
      expect(
        validator.validate(build(reps: null), ExerciseType.strength).isValid,
        isFalse,
      );
    });

    test('отрицательный вес невалиден', () {
      expect(
        validator.validate(build(weightKg: -1), ExerciseType.strength).isValid,
        isFalse,
      );
    });
  });

  group('plank', () {
    test('время удержания обязательно', () {
      expect(validator.validate(build(), ExerciseType.plank).isValid, isFalse);
    });

    test('валидно с временем удержания', () {
      expect(
        validator
            .validate(build(durationSeconds: 30), ExerciseType.plank)
            .isValid,
        isTrue,
      );
    });
  });

  group('running', () {
    test('нужны продолжительность и дистанция', () {
      expect(
        validator
            .validate(build(durationSeconds: null), ExerciseType.running)
            .isValid,
        isFalse,
      );
      expect(
        validator
            .validate(
              build(durationSeconds: 300, distanceMeters: 1000),
              ExerciseType.running,
            )
            .isValid,
        isTrue,
      );
    });

    test('отрицательная дистанция невалидна', () {
      expect(
        validator
            .validate(
              build(durationSeconds: 300, distanceMeters: -5),
              ExerciseType.running,
            )
            .isValid,
        isFalse,
      );
    });
  });

  test('количество подходов должно быть >= 1 для всех типов', () {
    for (final type in ExerciseType.values) {
      expect(
        validator.validate(build(sets: 0), type).isValid,
        isFalse,
        reason: 'тип $type',
      );
    }
  });
}
