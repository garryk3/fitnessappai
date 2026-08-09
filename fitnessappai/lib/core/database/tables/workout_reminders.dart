import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/tables/program_days.dart';

/// Напоминание о тренировочном дне.
@DataClassName('WorkoutReminderRow')
class WorkoutReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programDayId =>
      integer().references(ProgramDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
