import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/tables/contraindication_tags.dart';
import 'package:fitnessappai/core/database/tables/exercises.dart';

/// Связь упражнения с тегом противопоказания (M2M).
@DataClassName('ExerciseContraindicationRow')
@TableIndex(
  name: 'exercise_contraindications_tag_idx',
  columns: {#contraindicationTagId},
)
class ExerciseContraindications extends Table {
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get contraindicationTagId => integer().references(
    ContraindicationTags,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @override
  Set<Column> get primaryKey => {exerciseId, contraindicationTagId};
}
