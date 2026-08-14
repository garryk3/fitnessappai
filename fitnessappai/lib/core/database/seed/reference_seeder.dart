import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';

/// Идемпотентная заливка справочников `muscle_groups` и
/// `contraindication_tags` при создании БД.
class ReferenceSeeder {
  const ReferenceSeeder(this.database);

  final AppDatabase database;

  static const List<
    ({String key, String labelRu, MuscleView view, String regionKey})
  >
  muscleGroups =
      <({String key, String labelRu, MuscleView view, String regionKey})>[
        (
          key: 'abs',
          labelRu: 'Пресс',
          view: MuscleView.front,
          regionKey: 'abs',
        ),
        (
          key: 'obliques',
          labelRu: 'Косые',
          view: MuscleView.front,
          regionKey: 'obliques',
        ),
        (
          key: 'chest',
          labelRu: 'Грудь',
          view: MuscleView.front,
          regionKey: 'chest',
        ),
        (
          key: 'shoulders',
          labelRu: 'Плечи',
          view: MuscleView.front,
          regionKey: 'shoulders',
        ),
        (
          key: 'shoulders_front',
          labelRu: 'Передняя дельта',
          view: MuscleView.front,
          regionKey: 'shoulders_front',
        ),
        (
          key: 'shoulders_middle',
          labelRu: 'Средняя дельта',
          view: MuscleView.front,
          regionKey: 'shoulders_middle',
        ),
        (
          key: 'biceps',
          labelRu: 'Бицепс',
          view: MuscleView.front,
          regionKey: 'biceps',
        ),
        (
          key: 'triceps',
          labelRu: 'Трицепс',
          view: MuscleView.back,
          regionKey: 'triceps',
        ),
        (
          key: 'shoulders_rear',
          labelRu: 'Задняя дельта',
          view: MuscleView.back,
          regionKey: 'shoulders_rear',
        ),
        (
          key: 'forearms',
          labelRu: 'Предплечья',
          view: MuscleView.front,
          regionKey: 'forearms',
        ),
        (
          key: 'traps',
          labelRu: 'Трапеции',
          view: MuscleView.back,
          regionKey: 'traps',
        ),
        (
          key: 'lats',
          labelRu: 'Широчайшие',
          view: MuscleView.back,
          regionKey: 'lats',
        ),
        (
          key: 'lower_back',
          labelRu: 'Поясница',
          view: MuscleView.back,
          regionKey: 'lower_back',
        ),
        (
          key: 'glutes',
          labelRu: 'Ягодицы',
          view: MuscleView.back,
          regionKey: 'glutes',
        ),
        (
          key: 'quads',
          labelRu: 'Квадрицепсы',
          view: MuscleView.front,
          regionKey: 'quads',
        ),
        (
          key: 'hamstrings',
          labelRu: 'Бицепс бедра',
          view: MuscleView.back,
          regionKey: 'hamstrings',
        ),
        (
          key: 'calves',
          labelRu: 'Икры',
          view: MuscleView.back,
          regionKey: 'calves',
        ),
        (
          key: 'neck',
          labelRu: 'Шея',
          view: MuscleView.front,
          regionKey: 'neck',
        ),
      ];

  static const List<({String key, String labelRu})> contraindicationTags =
      <({String key, String labelRu})>[
        (key: 'knees', labelRu: 'Колени'),
        (key: 'back', labelRu: 'Спина'),
        (key: 'neck', labelRu: 'Шея'),
        (key: 'shoulders', labelRu: 'Плечи'),
        (key: 'elbows', labelRu: 'Локти'),
        (key: 'wrists', labelRu: 'Запястья'),
        (key: 'heart', labelRu: 'Сердечно-сосудистые'),
        (key: 'pregnancy', labelRu: 'Беременность'),
      ];

  /// Родительская группа для подгрупп (например, дельт).
  static const Map<String, String> muscleParentKeys = {
    'shoulders_front': 'shoulders',
    'shoulders_middle': 'shoulders',
    'shoulders_rear': 'shoulders',
  };

  /// Вставляет справочники, пропуская уже существующие записи по `key`.
  Future<void> seed() async {
    await database.batch((batch) {
      batch.insertAll(database.muscleGroups, [
        for (final m in muscleGroups)
          MuscleGroupsCompanion.insert(
            key: m.key,
            labelRu: m.labelRu,
            view: m.view,
            regionKey: m.regionKey,
            parentKey: Value(muscleParentKeys[m.key]),
          ),
      ], mode: InsertMode.insertOrIgnore);
      batch.insertAll(database.contraindicationTags, [
        for (final t in contraindicationTags)
          ContraindicationTagsCompanion.insert(key: t.key, labelRu: t.labelRu),
      ], mode: InsertMode.insertOrIgnore);
    });
  }
}
