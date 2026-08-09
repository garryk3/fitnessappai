import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/validators/exercise_validator.dart';

void main() {
  final validator = ExerciseValidator();
  final now = DateTime(2026, 8, 9);

  Exercise build({String name = 'Приседания'}) {
    return Exercise(
      name: name,
      type: ExerciseType.strength,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('валидное упражнение проходит проверку', () {
    expect(validator.validate(build()).isValid, isTrue);
  });

  test('пустое название невалидно', () {
    expect(validator.validate(build(name: '   ')).isValid, isFalse);
  });

  test('слишком длинное название невалидно', () {
    final long = List.filled(101, 'а').join();
    expect(validator.validate(build(name: long)).isValid, isFalse);
    expect(
      validator.validate(build(name: List.filled(100, 'а').join())).isValid,
      isTrue,
    );
  });

  test('ошибка возвращается с сообщением', () {
    final result = validator.validate(build(name: ''));
    expect(result.errors, isNotEmpty);
    expect(result.isValid, isFalse);
  });
}
