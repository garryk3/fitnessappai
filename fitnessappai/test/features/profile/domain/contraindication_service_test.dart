import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/profile/domain/contraindication_service.dart';

void main() {
  const service = ContraindicationService();

  ContraindicationTag tag(int id, String key, String labelRu) =>
      ContraindicationTag(id: id, key: key, labelRu: labelRu);

  final knees = tag(1, 'knees', 'Колени');
  final back = tag(2, 'back', 'Спина');
  final heart = tag(7, 'heart', 'Сердечно-сосудистые');

  Exercise exercise(int? id, String name) => Exercise(
    id: id,
    name: name,
    type: ExerciseType.strength,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  group('ContraindicationService.warningsFor', () {
    test('пересечение тегов даёт предупреждения с labelRu', () {
      final warnings = service.warningsFor(
        [knees, back, heart],
        {'knees', 'heart'},
      );

      expect(warnings, ['Колени', 'Сердечно-сосудистые']);
    });

    test('без пересечения предупреждений нет', () {
      final warnings = service.warningsFor([knees, back], {'heart'});

      expect(warnings, isEmpty);
    });

    test('пустые теги пользователя не дают предупреждений', () {
      expect(service.warningsFor([knees, back], {}), isEmpty);
      expect(service.warningsFor([], {'knees'}), isEmpty);
    });
  });

  group('ContraindicationService.hasContraindications', () {
    test('true при пересечении тегов', () {
      expect(service.hasContraindications([knees, back], {'knees'}), isTrue);
    });

    test('false без пересечения', () {
      expect(service.hasContraindications([knees, back], {'heart'}), isFalse);
      expect(service.hasContraindications([knees], {}), isFalse);
    });
  });

  group('ContraindicationService.filterAllowed', () {
    final squat = exercise(1, 'Приседания');
    final press = exercise(2, 'Жим лёжа');
    final run = exercise(3, 'Бег');

    final tagsById = {
      1: [knees, back],
      2: [heart],
    };

    test('исключает упражнения с пересечением противопоказаний', () {
      final allowed = service.filterAllowed(
        [squat, press, run],
        tagsById,
        {'knees'},
      );

      expect(allowed, [press, run]);
    });

    test('упражнения без записи в карте считаются допустимыми', () {
      final allowed = service.filterAllowed(
        [squat, press, run],
        tagsById,
        {'knees', 'heart'},
      );

      expect(allowed, [run]);
    });

    test('пустые теги пользователя не фильтруют', () {
      final allowed = service.filterAllowed([squat, press], tagsById, {});

      expect(allowed, [squat, press]);
    });

    test('сохраняет порядок исходного списка', () {
      final allowed = service.filterAllowed(
        [run, squat, press],
        tagsById,
        {'heart'},
      );

      expect(allowed.map((e) => e.name), ['Бег', 'Приседания']);
    });
  });
}
