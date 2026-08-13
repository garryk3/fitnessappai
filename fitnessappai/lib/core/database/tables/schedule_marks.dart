import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';
import 'package:fitnessappai/core/database/converters/enum_converters.dart';
import 'package:fitnessappai/core/database/tables/program_days.dart';

/// Отметка пропуска тренировочного дня на неделе.
@DataClassName('ScheduleMarkRow')
@TableIndex(name: 'schedule_marks_day_idx', columns: {#programDayId})
class ScheduleMarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programDayId =>
      integer().references(ProgramDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get weekStart => integer().map(const DateTimeConverter())();
  TextColumn get status => text().map(const ScheduleMarkStatusConverter())();
}
