import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/sync/data/local_file_sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';

void main() {
  late Directory tempDir;
  late String dbPath;
  late AppDatabase database;
  late bool databaseOpen;
  late LocalFileSyncService service;
  late int importCalls;

  setUp(() async {
    // В тестах открывается несколько копий БД на разных файлах —
    // гонки исключены, предупреждение drift не информативно.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tempDir = await Directory.systemTemp.createTemp('sync_test_');
    dbPath = p.join(tempDir.path, 'app.sqlite');
    database = AppDatabase(executor: NativeDatabase(File(dbPath)));
    databaseOpen = true;
    importCalls = 0;
    service = LocalFileSyncService(
      database: database,
      databaseFilePath: () async => dbPath,
      temporaryDirectoryPath: () async => tempDir.path,
      onImported: () async {
        importCalls++;
      },
    );
  });

  tearDown(() async {
    if (databaseOpen) {
      await database.close();
    }
    await tempDir.delete(recursive: true);
  });

  Future<AppDatabase> openAt(String path) async =>
      AppDatabase(executor: NativeDatabase(File(path)));

  Future<String> createValidSourceDb({
    int version = appDatabaseSchemaVersion,
  }) async {
    final sourcePath = p.join(tempDir.path, 'source.sqlite');
    final source = await openAt(sourcePath);
    await source
        .into(source.muscleGroups)
        .insert(
          MuscleGroupsCompanion.insert(
            key: 'marker',
            labelRu: 'Маркер',
            view: MuscleView.front,
            regionKey: 'abs',
          ),
        );
    await source.close();
    if (version != appDatabaseSchemaVersion) {
      final raw = sqlite.sqlite3.open(sourcePath);
      raw.execute('PRAGMA user_version = $version');
      raw.close();
    }
    return sourcePath;
  }

  test('export создаёт корректную копию БД', () async {
    final path = await service.export();

    expect(await File(path).exists(), isTrue);
    final exported = await openAt(path);
    final rows = await exported.select(exported.muscleGroups).get();
    expect(rows.length, greaterThan(0));
    await exported.close();
  });

  test('export оставляет рабочую БД открытой', () async {
    await service.export();

    final rows = await database.select(database.muscleGroups).get();
    expect(rows.length, greaterThan(0));
  });

  test('import заменяет файл БД и вызывает onImported', () async {
    final sourcePath = await createValidSourceDb();

    await service.import(sourcePath);

    expect(importCalls, 1);
    databaseOpen = false;
    final reopened = await openAt(dbPath);
    final rows = await reopened.select(reopened.muscleGroups).get();
    expect(rows.map((row) => row.key), contains('marker'));
    await reopened.close();
  });

  test('import отклоняет повреждённый файл и не трогает БД', () async {
    final badPath = p.join(tempDir.path, 'corrupt.sqlite');
    await File(badPath).writeAsString('это не база данных');

    await expectLater(
      service.import(badPath),
      throwsA(
        isA<SyncValidationException>().having(
          (e) => e.message,
          'message',
          'Файл не является базой данных FitnessAppAI',
        ),
      ),
    );

    expect(importCalls, 0);
    final rows = await database.select(database.muscleGroups).get();
    expect(rows.length, greaterThan(0));
  });

  test(
    'import отклоняет файл с корректным расширением, но не SQLite',
    () async {
      final badPath = p.join(tempDir.path, 'data.sqlite');
      await File(badPath).writeAsString('{"json":"не база"}');

      await expectLater(
        service.import(badPath),
        throwsA(
          isA<SyncValidationException>().having(
            (e) => e.message,
            'message',
            'Файл не является базой данных FitnessAppAI',
          ),
        ),
      );

      expect(importCalls, 0);
    },
  );

  test('import отклоняет версию схемы новее установленной', () async {
    final sourcePath = await createValidSourceDb(version: 99);

    await expectLater(
      service.import(sourcePath),
      throwsA(isA<SyncValidationException>()),
    );

    expect(importCalls, 0);
    final rows = await database.select(database.muscleGroups).get();
    expect(rows.length, greaterThan(0));
  });

  test('import принимает версию схемы старше установленной', () async {
    final sourcePath = await createValidSourceDb(
      version: appDatabaseSchemaVersion - 1,
    );

    await service.import(sourcePath);

    expect(importCalls, 1);
  });

  test('import отклоняет пустой файл', () async {
    final emptyPath = p.join(tempDir.path, 'empty.sqlite');
    await File(emptyPath).writeAsString('');

    await expectLater(
      service.import(emptyPath),
      throwsA(isA<SyncValidationException>()),
    );

    expect(importCalls, 0);
  });
}
