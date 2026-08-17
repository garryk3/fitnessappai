import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:fitnessappai/core/database/app_database.dart';

void main() {
  const programDaysV5 =
      'CREATE TABLE program_days ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'program_id INTEGER NOT NULL REFERENCES programs (id) ON DELETE CASCADE, '
      'day_index INTEGER NOT NULL CHECK (day_index BETWEEN 0 AND 6), '
      'day_of_week INTEGER NULL CHECK (day_of_week BETWEEN 1 AND 7));';

  const workoutSessionsV7 =
      'CREATE TABLE workout_sessions ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'program_id INTEGER NULL, '
      'program_name TEXT NOT NULL, '
      'program_day_id INTEGER NULL, '
      'day_index INTEGER NOT NULL, '
      'variant TEXT NOT NULL, '
      'performed_date INTEGER NOT NULL, '
      'started_at INTEGER NOT NULL, '
      'ended_at INTEGER NULL);';

  const workoutSetResultsV7 =
      'CREATE TABLE workout_set_results ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'session_id INTEGER NOT NULL REFERENCES workout_sessions (id) '
      'ON DELETE CASCADE, '
      'exercise_id INTEGER NULL REFERENCES exercises (id) ON DELETE SET NULL, '
      'exercise_name TEXT NOT NULL, '
      'exercise_type TEXT NOT NULL, '
      'set_index INTEGER NOT NULL, '
      'reps INTEGER NULL, '
      'weight_kg REAL NULL, '
      'duration_seconds INTEGER NULL, '
      'distance_meters REAL NULL, '
      'completed_at INTEGER NOT NULL);';

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
      sqlite.execute(programDaysV5);
      sqlite.execute(workoutSessionsV7);
      sqlite.execute(workoutSetResultsV7);
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
    sqlite.execute(programDaysV5);
    sqlite.execute(workoutSessionsV7);
    sqlite.execute(workoutSetResultsV7);
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
    sqlite.execute(programDaysV5);
    sqlite.execute(workoutSessionsV7);
    sqlite.execute(workoutSetResultsV7);
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
    sqlite.execute(programDaysV5);
    sqlite.execute(workoutSessionsV7);
    sqlite.execute(workoutSetResultsV7);
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

  test('миграция 5→6 добавляет program_days.warmup_minutes', () async {
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
      'updated_at INTEGER NOT NULL, '
      'is_active INTEGER NOT NULL DEFAULT 0);',
    );
    sqlite.execute(programDaysV5);
    sqlite.execute(workoutSessionsV7);
    sqlite.execute(workoutSetResultsV7);
    sqlite.execute("INSERT INTO programs VALUES (1, 'База', '', 0, 0, 0, 1);");
    sqlite.execute(
      'INSERT INTO program_days (program_id, day_index) VALUES (1, 0);',
    );
    sqlite.execute('PRAGMA user_version = 5');
    final database = AppDatabase(executor: NativeDatabase.opened(sqlite));
    addTearDown(database.close);

    final rows = await database.select(database.programDays).get();

    expect(rows, hasLength(1));
    expect(rows.single.warmupMinutes, isNull);

    final version =
        sqlite.select('PRAGMA user_version;').single.columnAt(0) as int;
    expect(version, appDatabaseSchemaVersion);
  });

  test('миграция 6→7 добавляет флаги упражнений и сторону результатов', () async {
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
      'updated_at INTEGER NOT NULL, '
      'is_active INTEGER NOT NULL DEFAULT 0);',
    );
    sqlite.execute(programDaysV5);
    sqlite.execute(
      'CREATE TABLE workout_sessions ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'program_id INTEGER NULL, '
      'program_name TEXT NOT NULL, '
      'program_day_id INTEGER NULL, '
      'day_index INTEGER NOT NULL, '
      'variant TEXT NOT NULL, '
      'performed_date INTEGER NOT NULL, '
      'started_at INTEGER NOT NULL, '
      'ended_at INTEGER NULL);',
    );
    sqlite.execute(
      'CREATE TABLE workout_set_results ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      'session_id INTEGER NOT NULL REFERENCES workout_sessions (id) '
      'ON DELETE CASCADE, '
      'exercise_id INTEGER NULL REFERENCES exercises (id) ON DELETE SET NULL, '
      'exercise_name TEXT NOT NULL, '
      'exercise_type TEXT NOT NULL, '
      'set_index INTEGER NOT NULL, '
      'reps INTEGER NULL, '
      'weight_kg REAL NULL, '
      'duration_seconds INTEGER NULL, '
      'distance_meters REAL NULL, '
      'completed_at INTEGER NOT NULL);',
    );
    sqlite.execute(
      'INSERT INTO exercises (name, type, created_at, updated_at) '
      'VALUES (\'Приседания\', \'strength\', 0, 0);',
    );
    sqlite.execute(
      'INSERT INTO workout_sessions '
      '(program_name, day_index, variant, performed_date, started_at) '
      'VALUES (\'База\', 0, \'main\', 0, 0);',
    );
    sqlite.execute(
      'INSERT INTO workout_set_results (session_id, exercise_id, '
      'exercise_name, exercise_type, set_index, reps, weight_kg, '
      'completed_at) VALUES (1, 1, \'Приседания\', \'strength\', 1, 8, 20, 0);',
    );
    sqlite.execute('PRAGMA user_version = 6');
    final database = AppDatabase(executor: NativeDatabase.opened(sqlite));
    addTearDown(database.close);

    final exercise = await database.select(database.exercises).getSingle();
    expect(exercise.fixedWeight, isFalse);
    expect(exercise.perSide, isFalse);

    final result = await database
        .select(database.workoutSetResults)
        .getSingle();
    expect(result.side, isNull);

    final version =
        sqlite.select('PRAGMA user_version;').single.columnAt(0) as int;
    expect(version, appDatabaseSchemaVersion);
  });
}
