import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/enum_converters.dart';
import 'package:fitnessappai/core/database/tables/exercises.dart';
import 'package:fitnessappai/core/database/tables/muscle_groups.dart';

/// Связь упражнения с мышечной группой и степенью нагрузки.
@DataClassName('ExerciseMuscleRow')
class ExerciseMuscles extends Table {
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get muscleGroupId =>
      integer().references(MuscleGroups, #id, onDelete: KeyAction.cascade)();
  TextColumn get intensity => text().map(const MuscleIntensityConverter())();

  @override
  Set<Column> get primaryKey => {exerciseId, muscleGroupId};
}
