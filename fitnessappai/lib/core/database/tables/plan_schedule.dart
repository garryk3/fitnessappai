import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/tables/program_days.dart';

/// Ручное назначение программы на конкретную дату.
///
/// Отличается от рекуррентного `program_days.dayOfWeek` тем, что
/// привязано к конкретному дню календаря.
class PlanSchedule extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programDayId => integer().references(ProgramDays, #id)();
  DateTimeColumn get scheduledDate => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {programDayId, scheduledDate},
  ];
}
