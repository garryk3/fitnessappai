import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/notifications/reminder_catch_up_log.dart';

/// Отметки о том, что системное напоминание дня уже показано пользователю
/// (задача 48.8).
///
/// Нужны, чтобы догон не продублировал уведомление, по которому пользователь
/// открыл приложение: `autoCancel` снимает уведомление из трея ещё до старта
/// процесса, и проверка трея этого уже не видит — остаётся только факт тапа
/// в launch-payload.
abstract class ReminderDeliveredLog {
  /// Показывалось ли системное напоминание для дня [programDayId] в
  /// календарный день [day].
  Future<bool> wasDeliveredOn(int programDayId, DateTime day);

  /// Запоминает, что системное напоминание дня [programDayId] показали в [at].
  Future<void> markDelivered(int programDayId, DateTime at);
}

/// Хранилище отметок в таблице `app_meta`.
///
/// Устроено как [AppMetaReminderCatchUpLog]: ключ на день программы
/// (`reminder_delivered_<dayId>`), значение — дата `yyyy-MM-dd`
/// ([AppMetaReminderCatchUpLog.formatDay]). Сравнение строк лексикографическое,
/// префиксы двух журналов не пересекаются, поэтому записи могут лежать в одной
/// таблице; миграция схемы БД не нужна.
class AppMetaReminderDeliveredLog implements ReminderDeliveredLog {
  AppMetaReminderDeliveredLog(this._db);

  static const String keyPrefix = 'reminder_delivered_';

  final AppDatabase _db;

  String _keyOf(int programDayId) => '$keyPrefix$programDayId';

  @override
  Future<bool> wasDeliveredOn(int programDayId, DateTime day) async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_keyOf(programDayId)))).getSingleOrNull();
    return row?.value == AppMetaReminderCatchUpLog.formatDay(day);
  }

  @override
  Future<void> markDelivered(int programDayId, DateTime at) async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(
            key: _keyOf(programDayId),
            value: Value(AppMetaReminderCatchUpLog.formatDay(at)),
          ),
        );
  }
}
