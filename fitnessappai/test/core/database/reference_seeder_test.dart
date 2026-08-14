import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/database/seed/reference_seeder.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('ReferenceSeeder', () {
    test('при создании БД справочники заполняются автоматически', () async {
      expect(
        await database
            .select(database.muscleGroups)
            .get()
            .then((r) => r.length),
        18,
      );
      expect(
        await database
            .select(database.contraindicationTags)
            .get()
            .then((r) => r.length),
        8,
      );
    });

    test('seed идемпотентен и не создаёт дубликатов', () async {
      await ReferenceSeeder(database).seed();
      expect(
        await database
            .select(database.muscleGroups)
            .get()
            .then((r) => r.length),
        18,
      );
      expect(
        await database
            .select(database.contraindicationTags)
            .get()
            .then((r) => r.length),
        8,
      );
    });

    test('дельты сидятся с parentKey на shoulders', () async {
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
      expect(
        await database
            .select(database.muscleGroups)
            .get()
            .then((r) => r.where((row) => row.parentKey != null).length),
        3,
      );
    });

    test('наборы справочников непустые', () {
      expect(ReferenceSeeder.muscleGroups, isNotEmpty);
      expect(ReferenceSeeder.muscleParentKeys, isNotEmpty);
      expect(ReferenceSeeder.contraindicationTags, isNotEmpty);
    });
  });
}
