import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';

void main() {
  final now = DateTime(2026, 8, 9, 12, 0);

  Exercise build({int? id = 1}) {
    return Exercise(
      id: id,
      name: 'Приседания с гирей',
      description: 'Описание',
      instructions: 'Инструкция',
      commonMistakes: const ['Кругление поясницы'],
      type: ExerciseType.strength,
      thumbnailPath: 'thumb.webp',
      animationPath: 'anim.webp',
      isCustom: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('copyWith изменяет только указанные поля', () {
    final e = build();
    final changed = e.copyWith(
      name: 'Махи гирей',
      isCustom: false,
      fixedWeight: true,
      perSide: true,
    );

    expect(changed.id, 1);
    expect(changed.name, 'Махи гирей');
    expect(changed.description, e.description);
    expect(changed.type, e.type);
    expect(changed.isCustom, isFalse);
    expect(changed.fixedWeight, isTrue);
    expect(changed.perSide, isTrue);
    expect(e.name, 'Приседания с гирей');
  });

  test('copyWith(clearId: true) обнуляет id', () {
    final e = build();
    expect(e.copyWith(clearId: true).id, isNull);
  });

  test('равенство зависит от полей и списка ошибок', () {
    expect(build(), build());
    expect(build(id: 1), isNot(build(id: 2)));
    expect(build().copyWith(commonMistakes: const []), isNot(build()));
    expect(build().copyWith(fixedWeight: true), isNot(build()));
    expect(build().copyWith(perSide: true), isNot(build()));
    expect(build().hashCode, build().hashCode);
  });

  test('ExerciseType хранит текстовые ключи для БД', () {
    expect(ExerciseType.strength.name, 'strength');
    expect(ExerciseType.bodyweight.name, 'bodyweight');
    expect(ExerciseType.plank.name, 'plank');
    expect(ExerciseType.distance.name, 'distance');
  });

  group('tracksSides (48.5)', () {
    test('дистанция не делится на стороны даже при сохранённом флаге', () {
      expect(
        build()
            .copyWith(type: ExerciseType.distance, perSide: true)
            .tracksSides,
        isFalse,
        reason: 'бег одной стороной — флаг из данных до 48.5 игнорируется',
      );
      expect(
        build().copyWith(type: ExerciseType.distance).tracksSides,
        isFalse,
      );
    });

    test('остальные типы сохраняют флаг', () {
      for (final type in [
        ExerciseType.strength,
        ExerciseType.bodyweight,
        ExerciseType.plank,
      ]) {
        expect(
          build().copyWith(type: type, perSide: true).tracksSides,
          isTrue,
          reason: '$type поддерживает стороны',
        );
        expect(build().copyWith(type: type).tracksSides, isFalse);
      }
    });
  });

  group('exerciseTypeFromName (47.13)', () {
    test('актуальные имена разбираются как есть', () {
      for (final type in ExerciseType.values) {
        expect(exerciseTypeFromName(type.name), type);
      }
    });

    test('устаревшие running и bike разбираются как distance', () {
      expect(exerciseTypeFromName('running'), ExerciseType.distance);
      expect(exerciseTypeFromName('bike'), ExerciseType.distance);
    });

    test('неизвестная строка даёт null, а не исключение', () {
      expect(exerciseTypeFromName('swim'), isNull);
      expect(exerciseTypeFromName(''), isNull);
    });
  });
}
