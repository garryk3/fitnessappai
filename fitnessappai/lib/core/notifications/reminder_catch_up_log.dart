import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';

/// Отметки о показаных «догоняющих» уведомлениях (задача 47.6).
///
/// Абстракция нужна, чтобы [ReminderService] не зависел от БД: в тестах
/// подставляется фейк, в приложении — реализация поверх `app_meta`.
abstract class ReminderCatchUpLog {
  /// Показывалось ли догоняющее уведомление для дня [programDayId]
  /// в календарный день [day].
  Future<bool> wasShownOn(int programDayId, DateTime day);

  /// Запоминает, что для дня [programDayId] догон показали в [at].
  Future<void> markShown(int programDayId, DateTime at);

  /// Снимает отметку дня [programDayId] (задача 48.8).
  ///
  /// Нужно, когда показ после отметки не состоялся: без снятия день навсегда
  /// остался бы «показанным» и догон не повторил бы попытку.
  Future<void> unmarkShown(int programDayId);
}

/// Хранилище отметок в таблице `app_meta`.
///
/// Ключ на день программы (`reminder_catchup_<dayId>`), значение — дата
/// `yyyy-MM-dd`. Сравнение с сегодняшней датой отсекает повторный догон в
/// течение дня; сами ключи не растут, потому что днём программы всегда один и
/// тот же ключ. Миграция схемы БД не требуется.
class AppMetaReminderCatchUpLog implements ReminderCatchUpLog {
  AppMetaReminderCatchUpLog(this._db);

  static const String keyPrefix = 'reminder_catchup_';

  final AppDatabase _db;

  String _keyOf(int programDayId) => '$keyPrefix$programDayId';

  /// Дата в формате `yyyy-MM-dd` (без года-не-месяца разделителей нельзя:
  /// сравнение строк должно быть лексикографическим).
  static String formatDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  @override
  Future<bool> wasShownOn(int programDayId, DateTime day) async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_keyOf(programDayId)))).getSingleOrNull();
    return row?.value == formatDay(day);
  }

  @override
  Future<void> markShown(int programDayId, DateTime at) async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(
            key: _keyOf(programDayId),
            value: Value(formatDay(at)),
          ),
        );
  }

  @override
  Future<void> unmarkShown(int programDayId) async {
    await (_db.delete(
      _db.appMeta,
    )..where((t) => t.key.equals(_keyOf(programDayId)))).go();
  }
}
