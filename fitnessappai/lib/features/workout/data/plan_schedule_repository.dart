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

  /// Назначает день программы [programDayId] на [date] с временем [hour]:
  /// [minute] и напоминанием [reminderEnabled] (48.10).
  ///
  /// Если такой день уже назначен — ничего не делает (идемпотентность) и
  /// возвращает уже существующую запись: повторное назначение не должно
  /// затирать заданное ранее время.
  Future<PlanScheduleItem> schedule(
    int programDayId,
    DateTime date, {
    int? hour,
    int? minute,
    bool reminderEnabled = false,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    await _db
        .into(_db.planSchedule)
        .insert(
          _companion(
            programDayId: programDayId,
            date: dateOnly,
            hour: hour,
            minute: minute,
            reminderEnabled: reminderEnabled,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    _notify();
    return (await getFor(programDayId, dateOnly))!;
  }

  /// Задаёт или меняет время и напоминание назначения (48.10).
  ///
  /// Если строки для дня на дату ещё нет — создаёт её: так время можно
  /// назначить дню, показанному по привязке к дню недели (у него в
  /// `plan_schedule` строки нет). Название «напоминание» подчёркивает, что
  /// вызов меняет только время и уведомление, а не состояние тренировки.
  ///
  /// [hour] равен `null` — время убирается, напоминание выключается.
  Future<PlanScheduleItem> setReminder(
    int programDayId,
    DateTime date, {
    required int? hour,
    required int? minute,
    required bool reminderEnabled,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    await _db
        .into(_db.planSchedule)
        .insert(
          _companion(
            programDayId: programDayId,
            date: dateOnly,
            hour: hour,
            minute: minute,
            reminderEnabled: reminderEnabled,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await (_db.update(_db.planSchedule)..where(
          (t) =>
              t.programDayId.equals(programDayId) &
              t.scheduledDate.equals(dateOnly),
        ))
        .write(
          PlanScheduleCompanion(
            reminderHour: Value(hour),
            reminderMinute: Value(minute),
            reminderEnabled: Value(_enabled(hour, minute, reminderEnabled)),
          ),
        );
    _notify();
    return (await getFor(programDayId, dateOnly))!;
  }

  /// Напоминание включается только вместе с заданным временем: без времени
  /// планировать нечего.
  static bool _enabled(int? hour, int? minute, bool requested) =>
      hour != null && minute != null && requested;

  PlanScheduleCompanion _companion({
    required int programDayId,
    required DateTime date,
    required int? hour,
    required int? minute,
    required bool reminderEnabled,
  }) {
    return PlanScheduleCompanion.insert(
      programDayId: programDayId,
      scheduledDate: date,
      reminderHour: Value(hour),
      reminderMinute: Value(minute),
      reminderEnabled: Value(_enabled(hour, minute, reminderEnabled)),
    );
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

  /// Назначение дня [programDayId] на [date] или `null`, если его нет.
  Future<PlanScheduleItem?> getFor(int programDayId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final row =
        await (_db.select(_db.planSchedule)..where(
              (t) =>
                  t.programDayId.equals(programDayId) &
                  t.scheduledDate.equals(dateOnly),
            ))
            .getSingleOrNull();
    return row == null ? null : _toItem(row);
  }

  /// Возвращает все назначения за период [start]–[end] (включительно).
  Future<List<PlanScheduleItem>> getForRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows =
        await (_db.select(_db.planSchedule)..where(
              (t) => t.scheduledDate.isBetweenValues(
                _dateOnly(start),
                _dateOnly(end),
              ),
            ))
            .get();
    return [for (final row in rows) _toItem(row)];
  }

  /// Назначения с включённым напоминанием за период [start]–[end] —
  /// перепланирование одноразовых уведомлений (48.10).
  ///
  /// Фильтр по активным программам совпадает с недельными напоминаниями
  /// ([WorkoutReminderRepository.allScheduled]): настройки дней деактивированной
  /// программы сохраняются, но её уведомления при возврате в приложение не
  /// должны перевзводиться.
  Future<List<PlanScheduleReminder>> remindersBetween(
    DateTime start,
    DateTime end,
  ) async {
    final query = _remindersQuery()
      ..where(
        _db.planSchedule.scheduledDate.isBetweenValues(
          _dateOnly(start),
          _dateOnly(end),
        ),
      )
      ..where(_db.programs.isActive.equals(true));
    return _readReminders(query);
  }

  /// Назначения с включённым напоминанием для дней [programDayIds] (48.10).
  ///
  /// Без фильтра по активности: вызывается явно при (де)активации программы,
  /// а деактивация уже снимает `isActive` — фильтр сделал бы отмену пустой.
  Future<List<PlanScheduleReminder>> remindersForDays(
    Iterable<int> programDayIds,
  ) async {
    final ids = programDayIds.toList();
    if (ids.isEmpty) {
      return const [];
    }
    final query = _remindersQuery()
      ..where(_db.planSchedule.programDayId.isIn(ids));
    return _readReminders(query);
  }

  JoinedSelectStatement _remindersQuery() {
    return _db.select(_db.planSchedule).join([
      innerJoin(
        _db.programDays,
        _db.programDays.id.equalsExp(_db.planSchedule.programDayId),
      ),
      innerJoin(
        _db.programs,
        _db.programs.id.equalsExp(_db.programDays.programId),
      ),
    ])..where(_db.planSchedule.reminderEnabled.equals(true));
  }

  Future<List<PlanScheduleReminder>> _readReminders(
    JoinedSelectStatement query,
  ) async {
    final rows = await query.get();
    return [
      for (final row in rows)
        if (row.readTable(_db.planSchedule).reminderHour != null)
          PlanScheduleReminder(
            scheduleId: row.readTable(_db.planSchedule).id,
            programDayId: row.readTable(_db.planSchedule).programDayId,
            scheduledDate: row.readTable(_db.planSchedule).scheduledDate,
            hour: row.readTable(_db.planSchedule).reminderHour!,
            minute: row.readTable(_db.planSchedule).reminderMinute!,
            programName: row.readTable(_db.programs).name,
            dayNumber: row.readTable(_db.programDays).dayIndex + 1,
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

  /// Удаляет назначения раньше [date] — «протухшие» строки расписания
  /// прошлых недель (задача 47.4).
  ///
  /// Возвращает число удалённых строк и не шлёт уведомление об изменении
  /// данных: вызывающий сам решает, нужно ли перерисовывать UI.
  Future<int> deleteBefore(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return (_db.delete(
      _db.planSchedule,
    )..where((t) => t.scheduledDate.isSmallerThanValue(dateOnly))).go();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static PlanScheduleItem _toItem(PlanScheduleData row) => PlanScheduleItem(
    id: row.id,
    programDayId: row.programDayId,
    scheduledDate: row.scheduledDate,
    reminderHour: row.reminderHour,
    reminderMinute: row.reminderMinute,
    reminderEnabled: row.reminderEnabled,
  );
}
