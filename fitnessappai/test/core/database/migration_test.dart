import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:fitnessappai/core/database/app_database.dart';

void main() {
  test(
    'миграция 1→3 добавляет parentKey, сидирует дельты и dismissals',
    () async {
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
      sqlite.execute(
        'CREATE TABLE exercises ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL, '
        'description TEXT NOT NULL DEFAULT \'\', '
        'instructions TEXT NOT NULL DEFAULT \'\', '
        'common_mistakes TEXT NOT NULL DEFAULT \'[]\', '
        'type TEXT NOT NULL, '
        'thumbnail_path TEXT NULL, '
        'animation_path TEXT NULL, '
        'is_custom INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL);',
      );
      sqlite.execute(
        'CREATE TABLE programs ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL, '
        'description TEXT NOT NULL DEFAULT \'\', '
        'days_count INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL);',
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
    },
  );

  test('миграция 2→3 создаёт таблицу program_warning_dismissals', () async {
    final sqlite = sqlite3.openInMemory();
    sqlite.execute(
      'CREATE TABLE muscle_groups ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL, '
      'view TEXT NOT NULL, '
      'region_key TEXT NOT NULL, '
      'parent_key TEXT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE contraindication_tags ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE programs ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'description TEXT NOT NULL DEFAULT \'\', '
      'days_count INTEGER NOT NULL DEFAULT 0, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL);',
    );
    sqlite.execute("INSERT INTO programs VALUES (1, 'База', '', 0, 0, 0);");
    sqlite.execute(
      'CREATE TABLE exercises ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'description TEXT NOT NULL DEFAULT \'\', '
      'instructions TEXT NOT NULL DEFAULT \'\', '
      'common_mistakes TEXT NOT NULL DEFAULT \'[]\', '
      'type TEXT NOT NULL, '
      'thumbnail_path TEXT NULL, '
      'animation_path TEXT NULL, '
      'is_custom INTEGER NOT NULL DEFAULT 0, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL);',
    );
    sqlite.execute('PRAGMA user_version = 2');

    final database = AppDatabase(executor: NativeDatabase.opened(sqlite));
    addTearDown(database.close);

    await database
        .into(database.programWarningDismissals)
        .insert(
          ProgramWarningDismissalsCompanion.insert(
            programId: 1,
            dismissedAt: DateTime(2024, 1, 1),
          ),
        );
    final rows = await database.select(database.programWarningDismissals).get();

    expect(rows, hasLength(1));
    expect(rows.single.programId, 1);

    final version =
        sqlite.select('PRAGMA user_version;').single.columnAt(0) as int;
    expect(version, appDatabaseSchemaVersion);
  });

  test('миграция 3→4 добавляет exercises.hide_optional', () async {
    final sqlite = sqlite3.openInMemory();
    sqlite.execute(
      'CREATE TABLE muscle_groups ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL, '
      'view TEXT NOT NULL, '
      'region_key TEXT NOT NULL, '
      'parent_key TEXT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE contraindication_tags ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE exercises ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'description TEXT NOT NULL DEFAULT \'\', '
      'instructions TEXT NOT NULL DEFAULT \'\', '
      'common_mistakes TEXT NOT NULL DEFAULT \'[]\', '
      'type TEXT NOT NULL, '
      'thumbnail_path TEXT NULL, '
      'animation_path TEXT NULL, '
      'is_custom INTEGER NOT NULL DEFAULT 0, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL);',
    );
    sqlite.execute(
      'INSERT INTO exercises (name, type, created_at, updated_at) '
      "VALUES ('Приседания', 'strength', 0, 0);",
    );
    sqlite.execute(
      'CREATE TABLE programs ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'description TEXT NOT NULL DEFAULT \'\', '
      'days_count INTEGER NOT NULL DEFAULT 0, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL);',
    );
    sqlite.execute('PRAGMA user_version = 3');
    final database = AppDatabase(executor: NativeDatabase.opened(sqlite));
    addTearDown(database.close);

    final rows = await database.select(database.exercises).get();

    expect(rows, hasLength(1));
    expect(rows.single.hideOptional, isFalse);

    final version =
        sqlite.select('PRAGMA user_version;').single.columnAt(0) as int;
    expect(version, appDatabaseSchemaVersion);
  });

  test('миграция 4→5 добавляет programs.is_active', () async {
    final sqlite = sqlite3.openInMemory();
    sqlite.execute(
      'CREATE TABLE muscle_groups ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL, '
      'view TEXT NOT NULL, '
      'region_key TEXT NOT NULL, '
      'parent_key TEXT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE contraindication_tags ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'key TEXT NOT NULL UNIQUE, '
      'label_ru TEXT NOT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE exercises ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'description TEXT NOT NULL DEFAULT \'\', '
      'instructions TEXT NOT NULL DEFAULT \'\', '
      'common_mistakes TEXT NOT NULL DEFAULT \'[]\', '
      'type TEXT NOT NULL, '
      'thumbnail_path TEXT NULL, '
      'animation_path TEXT NULL, '
      'is_custom INTEGER NOT NULL DEFAULT 0, '
      'hide_optional INTEGER NOT NULL DEFAULT 0, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE programs ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'description TEXT NOT NULL DEFAULT \'\', '
      'days_count INTEGER NOT NULL DEFAULT 0, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL);',
    );
    sqlite.execute("INSERT INTO programs VALUES (1, 'База', '', 0, 0, 0);");
    sqlite.execute('PRAGMA user_version = 4');
    final database = AppDatabase(executor: NativeDatabase.opened(sqlite));
    addTearDown(database.close);

    final program = await database.select(database.programs).getSingle();

    expect(program.isActive, isFalse);

    final version =
        sqlite.select('PRAGMA user_version;').single.columnAt(0) as int;
    expect(version, appDatabaseSchemaVersion);
  });
}
