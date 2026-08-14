import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('in-memory БД открывается и выполняет запросы', () async {
    final rows = await database.select(database.appMeta).get();
    expect(rows, isEmpty);
  });

  test('in-memory БД закрывается', () async {
    await database.close();
    await database.close();
  });

  test('schemaVersion = appDatabaseSchemaVersion', () {
    expect(database.schemaVersion, appDatabaseSchemaVersion);
  });

  test('app_meta: insert и round-trip', () async {
    await database
        .into(database.appMeta)
        .insert(
          AppMetaCompanion.insert(key: 'dataVersion', value: const Value('2')),
        );
    final row = await (database.select(
      database.appMeta,
    )..where((t) => t.key.equals('dataVersion'))).getSingleOrNull();

    expect(row, isNotNull);
    expect(row!.value, '2');
  });

  test('app_meta: update значения', () async {
    await database
        .into(database.appMeta)
        .insert(
          AppMetaCompanion.insert(key: 'seeded', value: const Value('false')),
        );
    await (database.update(database.appMeta)
          ..where((t) => t.key.equals('seeded')))
        .write(const AppMetaCompanion(value: Value('true')));

    final row = await (database.select(
      database.appMeta,
    )..where((t) => t.key.equals('seeded'))).getSingle();
    expect(row.value, 'true');
  });

  test('app_meta: delete', () async {
    await database
        .into(database.appMeta)
        .insert(AppMetaCompanion.insert(key: 'temp', value: const Value('1')));
    await (database.delete(
      database.appMeta,
    )..where((t) => t.key.equals('temp'))).go();

    final count = await database.select(database.appMeta).get();
    expect(count, isEmpty);
  });

  test('duplicate key: upsert заменяет значение', () async {
    await database
        .into(database.appMeta)
        .insert(AppMetaCompanion.insert(key: 'key', value: const Value('a')));
    await database
        .into(database.appMeta)
        .insert(
          AppMetaCompanion.insert(key: 'key', value: const Value('b')),
          mode: InsertMode.insertOrReplace,
        );

    final row = await (database.select(
      database.appMeta,
    )..where((t) => t.key.equals('key'))).getSingle();
    expect(row.value, 'b');
  });

  test('DI: registerCoreServices регистрирует AppDatabase', () {
    final sl = ServiceLocator();
    registerCoreServices(sl);
    expect(() => sl.get<AppDatabase>(), isNot(throwsStateError));
  });
}
