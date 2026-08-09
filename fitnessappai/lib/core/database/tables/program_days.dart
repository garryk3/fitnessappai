import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/tables/programs.dart';

/// Тренировочный день программы.
@DataClassName('ProgramDayRow')
class ProgramDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId =>
      integer().references(Programs, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayIndex =>
      integer().customConstraint('CHECK (day_index BETWEEN 0 AND 6)')();
  IntColumn get dayOfWeek => integer().nullable().customConstraint(
    'CHECK (day_of_week BETWEEN 1 AND 7)',
  )();
}
