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
    final changed = e.copyWith(name: 'Махи гирей', isCustom: false);

    expect(changed.id, 1);
    expect(changed.name, 'Махи гирей');
    expect(changed.description, e.description);
    expect(changed.type, e.type);
    expect(changed.isCustom, isFalse);
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
    expect(build().hashCode, build().hashCode);
  });

  test('ExerciseType хранит текстовые ключи для БД', () {
    expect(ExerciseType.strength.name, 'strength');
    expect(ExerciseType.plank.name, 'plank');
    expect(ExerciseType.running.name, 'running');
  });
}
