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
        25,
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
        25,
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
    });

    test(
      'подгруппы груди, рук, спины, ног и кора сидятся с parentKey',
      () async {
        final parentKeys = await database
            .select(database.muscleGroups)
            .get()
            .then((r) => r.where((row) => row.parentKey != null).toList());

        expect(parentKeys.map((r) => r.key).toList()..sort(), [
          'abs',
          'biceps',
          'calves',
          'chest_center',
          'chest_lower',
          'chest_upper',
          'forearms',
          'glutes',
          'hamstrings',
          'lats',
          'lower_back',
          'obliques',
          'quads',
          'shoulders_front',
          'shoulders_middle',
          'shoulders_rear',
          'traps',
          'triceps',
        ]);
        expect(parentKeys.where((r) => r.parentKey == 'arms').length, 3);
        expect(parentKeys.where((r) => r.parentKey == 'back').length, 3);
        expect(parentKeys.where((r) => r.parentKey == 'legs').length, 4);
        expect(parentKeys.where((r) => r.parentKey == 'chest').length, 3);
        expect(parentKeys.where((r) => r.parentKey == 'core').length, 2);
      },
    );

    test('группа кора сидится с родителем по parentKey на core', () async {
      final rows = await (database.select(
        database.muscleGroups,
      )..where((t) => t.parentKey.equals('core'))).get();

      expect(rows.map((r) => r.key), ['abs', 'obliques']);
      expect(rows.map((r) => r.labelRu), ['Пресс', 'Косые']);
    });

    test('наборы справочников непустые', () {
      expect(ReferenceSeeder.muscleGroups, isNotEmpty);
      expect(ReferenceSeeder.muscleParentKeys, isNotEmpty);
      expect(ReferenceSeeder.contraindicationTags, isNotEmpty);
    });

    test('группа «кора» промаркирована как «Кора»', () {
      final core = ReferenceSeeder.muscleGroups.firstWhere(
        (m) => m.key == 'core',
      );
      expect(core.labelRu, 'Кора');
    });
  });
}
