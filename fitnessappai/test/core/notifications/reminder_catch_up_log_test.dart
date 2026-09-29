import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/notifications/reminder_catch_up_log.dart';

void main() {
  late AppDatabase db;
  late AppMetaReminderCatchUpLog log;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    log = AppMetaReminderCatchUpLog(db);
    addTearDown(db.close);
  });

  /// Дата в формате, который понимает журнал.
  String day(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-'
      '${m.toString().padLeft(2, '0')}-'
      '${d.toString().padLeft(2, '0')}';

  test('до показа ничего не отмечено', () async {
    expect(await log.wasShownOn(12, DateTime(2026, 9, 29)), isFalse);
  });

  test('отметка дня распознаётся в тот же день', () async {
    await log.markShown(12, DateTime(2026, 9, 29, 18, 30));

    expect(await log.wasShownOn(12, DateTime(2026, 9, 29, 23, 59)), isTrue);
  });

  test('в другой день отметка не действует', () async {
    await log.markShown(12, DateTime(2026, 9, 29, 18, 30));

    expect(await log.wasShownOn(12, DateTime(2026, 9, 30, 0, 1)), isFalse);
  });

  test('отметки разных дней программы не путаются', () async {
    await log.markShown(12, DateTime(2026, 9, 29));

    expect(await log.wasShownOn(13, DateTime(2026, 9, 29)), isFalse);
  });

  test('повторная отметка того же дня перезаписывает дату', () async {
    await log.markShown(12, DateTime(2026, 9, 29));
    await log.markShown(12, DateTime(2026, 9, 30));

    expect(await log.wasShownOn(12, DateTime(2026, 9, 30)), isTrue);
    expect(await log.wasShownOn(12, DateTime(2026, 9, 29)), isFalse);
    // Одна строка на день программы — БД не растёт с числом запусков.
    final rows = await db.select(db.appMeta).get();
    expect(rows, hasLength(1));
  });

  group('formatDay', () {
    test('сортируется лексикографически и дополняется нулями', () {
      expect(
        AppMetaReminderCatchUpLog.formatDay(DateTime(2026, 1, 2)),
        '2026-01-02',
      );
      expect(
        AppMetaReminderCatchUpLog.formatDay(
          DateTime(2026, 1, 2),
        ).compareTo(AppMetaReminderCatchUpLog.formatDay(DateTime(2026, 1, 10))),
        isNegative,
        reason: 'сравнение строк в журнале должно совпадать с хронологическим',
      );
      expect(
        day(2026, 12, 31),
        AppMetaReminderCatchUpLog.formatDay(DateTime(2026, 12, 31)),
      );
    });
  });
}
