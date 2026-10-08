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

  /// Время тренировки (48.10): час и минута задаются только вместе —
  /// пара nullable-полей, а не два независимых значения с частичным
  /// состоянием. `null` — времени нет.
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().nullable()();

  /// Включено ли одноразовое напоминание (48.10).
  ///
  /// Управляет только уведомлением: время показывается в плане всегда,
  /// независимо от этого флага (решение владельца).
  BoolColumn get reminderEnabled => boolean().withDefault(Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {programDayId, scheduledDate},
  ];
}
