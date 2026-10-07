import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/notifications/reminder_catch_up_log.dart';
import 'package:fitnessappai/core/notifications/reminder_delivered_log.dart';

void main() {
  late AppDatabase db;
  late AppMetaReminderDeliveredLog log;
  late AppMetaReminderCatchUpLog catchUpLog;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    log = AppMetaReminderDeliveredLog(db);
    catchUpLog = AppMetaReminderCatchUpLog(db);
    addTearDown(db.close);
  });

  test('до тапа по уведомлению доставки не зафиксировано', () async {
    expect(await log.wasDeliveredOn(12, DateTime(2026, 9, 29)), isFalse);
  });

  test('отметка дня распознаётся в тот же день', () async {
    await log.markDelivered(12, DateTime(2026, 9, 29, 9, 15));

    expect(await log.wasDeliveredOn(12, DateTime(2026, 9, 29, 23, 59)), isTrue);
  });

  test('в другой день отметка не действует', () async {
    await log.markDelivered(12, DateTime(2026, 9, 29, 9, 15));

    expect(await log.wasDeliveredOn(12, DateTime(2026, 9, 30, 0, 1)), isFalse);
  });

  test('отметки разных дней программы не путаются', () async {
    await log.markDelivered(12, DateTime(2026, 9, 29));

    expect(await log.wasDeliveredOn(13, DateTime(2026, 9, 29)), isFalse);
  });

  test('повторная отметка того же дня перезаписывает дату', () async {
    await log.markDelivered(12, DateTime(2026, 9, 29));
    await log.markDelivered(12, DateTime(2026, 9, 30));

    expect(await log.wasDeliveredOn(12, DateTime(2026, 9, 30)), isTrue);
    expect(await log.wasDeliveredOn(12, DateTime(2026, 9, 29)), isFalse);
    // Одна строка на день программы — БД не растёт с числом запусков.
    final rows = await db.select(db.appMeta).get();
    expect(rows, hasLength(1));
  });

  test(
    'журналы доставки и догона живут в одной таблице без конфликтов',
    () async {
      await log.markDelivered(12, DateTime(2026, 9, 29));
      await catchUpLog.markShown(12, DateTime(2026, 9, 29));

      expect(await log.wasDeliveredOn(12, DateTime(2026, 9, 29)), isTrue);
      expect(await catchUpLog.wasShownOn(12, DateTime(2026, 9, 29)), isTrue);
      // Разные префиксы — записи не затирают друг друга, миграция не нужна.
      final rows = await db.select(db.appMeta).get();
      expect(rows, hasLength(2));
      expect(
        rows.map((row) => row.key),
        containsAll([
          '${AppMetaReminderDeliveredLog.keyPrefix}12',
          '${AppMetaReminderCatchUpLog.keyPrefix}12',
        ]),
      );
    },
  );

  test('каждый журнал видит только свои ключи', () async {
    await catchUpLog.markShown(12, DateTime(2026, 9, 29));

    expect(await log.wasDeliveredOn(12, DateTime(2026, 9, 29)), isFalse);
  });
}
