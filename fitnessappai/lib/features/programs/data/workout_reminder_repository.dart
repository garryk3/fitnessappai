import 'package:drift/drift.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/workout_reminder.dart';

/// Напоминание вместе с данными, нужными для планирования уведомления.
class ReminderSchedule {
  const ReminderSchedule({
    required this.reminder,
    required this.dayOfWeek,
    required this.programName,
    required this.dayNumber,
  });

  final WorkoutReminder reminder;
  final int? dayOfWeek;
  final String programName;
  final int dayNumber;
}

/// Репозиторий напоминаний о тренировочных днях.
class WorkoutReminderRepository {
  WorkoutReminderRepository(this._db, {DataChangeNotifier? changes})
    : _changes = changes ?? appDataChanges;

  final AppDatabase _db;
  final DataChangeNotifier _changes;

  /// Возвращает напоминание дня по [dayId] или `null`.
  Future<WorkoutReminder?> getForDay(int dayId) async {
    final row = await (_db.select(
      _db.workoutReminders,
    )..where((t) => t.programDayId.equals(dayId))).getSingleOrNull();
    return row == null ? null : _toReminder(row);
  }

  /// Создаёт или обновляет напоминание для дня по [dayId].
  Future<WorkoutReminder> saveForDay(
    int dayId, {
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    final existing = await getForDay(dayId);
    final values = WorkoutRemindersCompanion(
      hour: Value(hour),
      minute: Value(minute),
      enabled: Value(enabled),
    );
    if (existing == null) {
      final id = await _db
          .into(_db.workoutReminders)
          .insert(
            WorkoutRemindersCompanion.insert(
              programDayId: dayId,
              hour: hour,
              minute: minute,
              enabled: Value(enabled),
            ),
          );
      _changes.notifyChanged();
      return _toReminder((await _reminderById(id))!);
    }
    await (_db.update(
      _db.workoutReminders,
    )..where((t) => t.id.equals(existing.id!))).write(values);
    _changes.notifyChanged();
    return _toReminder((await _reminderById(existing.id!))!);
  }

  /// Удаляет напоминание дня по [dayId].
  Future<void> deleteForDay(int dayId) async {
    await (_db.delete(
      _db.workoutReminders,
    )..where((t) => t.programDayId.equals(dayId))).go();
    _changes.notifyChanged();
  }

  /// Все напоминания с днём недели и названием программы — для
  /// перепланирования после импорта БД.
  Future<List<ReminderSchedule>> allScheduled() async {
    final query = _db.select(_db.workoutReminders).join([
      innerJoin(
        _db.programDays,
        _db.programDays.id.equalsExp(_db.workoutReminders.programDayId),
      ),
      innerJoin(
        _db.programs,
        _db.programs.id.equalsExp(_db.programDays.programId),
      ),
    ]);
    final rows = await query.get();
    return [
      for (final row in rows)
        ReminderSchedule(
          reminder: _toReminder(row.readTable(_db.workoutReminders)),
          dayOfWeek: row.readTable(_db.programDays).dayOfWeek,
          programName: row.readTable(_db.programs).name,
          dayNumber: row.readTable(_db.programDays).dayIndex + 1,
        ),
    ];
  }

  Future<WorkoutReminderRow?> _reminderById(int id) async {
    return (_db.select(
      _db.workoutReminders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  WorkoutReminder _toReminder(WorkoutReminderRow row) => WorkoutReminder(
    id: row.id,
    programDayId: row.programDayId,
    hour: row.hour,
    minute: row.minute,
    enabled: row.enabled,
  );
}
