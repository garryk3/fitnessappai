import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:fitnessappai/core/database/app_database.dart';

void main() {
  test('миграция 1→2 добавляет parentKey и сидирует подгруппы дельт', () async {
    final sqlite = sqlite3.openInMemory();
    sqlite.execute(
      'CREATE TABLE muscle_groups ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL, '
      'view TEXT NOT NULL, '
      'region_key TEXT NOT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE contraindication_tags ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL);',
    );
    sqlite.execute('PRAGMA user_version = 1');

    final database = AppDatabase(executor: NativeDatabase.opened(sqlite));
    addTearDown(database.close);

    final rows = await (database.select(
      database.muscleGroups,
    )..where((t) => t.parentKey.equals('shoulders'))).get();

    expect(rows.map((r) => r.key), [
      'shoulders_front',
      'shoulders_middle',
      'shoulders_rear',
    ]);
    expect(rows.map((r) => r.regionKey), [
      'shoulders_front',
      'shoulders_middle',
      'shoulders_rear',
    ]);

    final version =
        sqlite.select('PRAGMA user_version;').single.columnAt(0) as int;
    expect(version, appDatabaseSchemaVersion);
  });
}
