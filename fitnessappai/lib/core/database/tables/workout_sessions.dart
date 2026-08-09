import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';
import 'package:fitnessappai/core/database/converters/enum_converters.dart';
import 'package:fitnessappai/core/database/tables/program_days.dart';
import 'package:fitnessappai/core/database/tables/programs.dart';

/// Проведённая тренировочная сессия.
@DataClassName('WorkoutSessionRow')
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId => integer().nullable().references(
    Programs,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get programName => text()();
  IntColumn get programDayId => integer().nullable().references(
    ProgramDays,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get dayIndex => integer()();
  TextColumn get variant => text().map(const WorkoutVariantConverter())();
  IntColumn get performedDate => integer().map(const DateTimeConverter())();
  IntColumn get startedAt => integer().map(const DateTimeConverter())();
  IntColumn get endedAt => integer().map(const DateTimeConverter())();
  TextColumn get status => text().withDefault(const Constant('completed'))();
}
