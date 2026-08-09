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
        15,
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
        15,
      );
      expect(
        await database
            .select(database.contraindicationTags)
            .get()
            .then((r) => r.length),
        8,
      );
    });

    test('наборы справочников непустые', () {
      expect(ReferenceSeeder.muscleGroups, isNotEmpty);
      expect(ReferenceSeeder.contraindicationTags, isNotEmpty);
    });
  });
}
