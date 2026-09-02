import 'package:drift/drift.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/workout/domain/plan_schedule_item.dart';

/// Репозиторий ручных назначений программы на конкретные даты.
class PlanScheduleRepository {
  PlanScheduleRepository(this._db, {DataChangeNotifier? changes})
    : _changes = changes ?? appDataChanges;

  final AppDatabase _db;
  final DataChangeNotifier _changes;

  void _notify() => _changes.notifyChanged();

  /// Назначает день программы [programDayId] на [date].
  ///
  /// Если такой день уже назначен — ничего не делает (идемпотентность).
  Future<void> schedule(int programDayId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    await _db
        .into(_db.planSchedule)
        .insert(
          PlanScheduleCompanion.insert(
            programDayId: programDayId,
            scheduledDate: dateOnly,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    _notify();
  }

  /// Отменяет назначение дня программы на дату.
  Future<void> cancel(int programDayId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    await (_db.delete(_db.planSchedule)..where(
          (t) =>
              t.programDayId.equals(programDayId) &
              t.scheduledDate.equals(dateOnly),
        ))
        .go();
    _notify();
  }

  /// Возвращает все назначения за период [start]–[end] (включительно).
  Future<List<PlanScheduleItem>> getForRange(
    DateTime start,
    DateTime end,
  ) async {
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    final rows = await (_db.select(
      _db.planSchedule,
    )..where((t) => t.scheduledDate.isBetweenValues(startOnly, endOnly))).get();
    return [
      for (final row in rows)
        PlanScheduleItem(
          id: row.id,
          programDayId: row.programDayId,
          scheduledDate: row.scheduledDate,
        ),
    ];
  }

  /// Проверяет, назначено ли конкретное назначение.
  Future<bool> isScheduled(int programDayId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final result =
        await (_db.select(_db.planSchedule)..where(
              (t) =>
                  t.programDayId.equals(programDayId) &
                  t.scheduledDate.equals(dateOnly),
            ))
            .get();
    return result.isNotEmpty;
  }
}
