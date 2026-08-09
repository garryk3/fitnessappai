import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/tables/exercises.dart';
import 'package:fitnessappai/core/database/tables/program_days.dart';

/// Упражнение внутри тренировочного дня.
@DataClassName('ProgramDayExerciseRow')
class ProgramDayExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId =>
      integer().references(ProgramDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().nullable().references(
    Exercises,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get orderIndex => integer()();
  IntColumn get sets => integer().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  BoolColumn get isAlternative =>
      boolean().withDefault(const Constant(false))();
}
