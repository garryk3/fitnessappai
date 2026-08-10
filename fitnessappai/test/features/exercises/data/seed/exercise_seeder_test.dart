import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/seed/exercise_seeder.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaStore mediaStore;
  late ExerciseSeeder seeder;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('exercise_seeder_test');
    mediaStore = MediaStore(
      directoryProvider: () async => tempDir,
      assetLoader: (assetPath) async {
        final bytes = utf8.encode('webp:$assetPath');
        return Uint8List.fromList(bytes);
      },
      filePicker: () async => null,
    );
    seeder = ExerciseSeeder(
      db: db,
      mediaStore: mediaStore,
      seedJsonLoader: () async =>
          File('assets/data/exercises_seed.json').readAsString(),
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('изначально флаг seeded отсутствует', () async {
    expect(await seeder.isSeeded(), isFalse);
  });

  test('первый сид вставляет упражнения и копирует анимации', () async {
    await seeder.seed();

    expect(await seeder.isSeeded(), isTrue);

    final exercises = await db.select(db.exercises).get();
    expect(exercises.length, greaterThanOrEqualTo(15));
    expect(
      exercises.map((e) => e.type).toSet(),
      containsAll(ExerciseType.values),
    );

    final mediaDir = Directory(p.join(tempDir.path, MediaStore.mediaSubDir));
    for (final row in exercises) {
      final path = row.animationPath;
      expect(path, isNotNull);
      final file = File(path!);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), isNotEmpty);
      expect(p.dirname(file.path), mediaDir.path);
      expect(row.isCustom, isFalse);
    }
  });

  test('второй сид не дублирует упражнения', () async {
    await seeder.seed();
    final count = (await db.select(db.exercises).get()).length;
    final mediaDir = Directory(p.join(tempDir.path, MediaStore.mediaSubDir));
    final filesAfterFirst = mediaDir.listSync().whereType<File>().length;

    await seeder.seed();
    await seeder.seed();

    expect((await db.select(db.exercises).get()).length, count);
    expect(mediaDir.listSync().whereType<File>().length, filesAfterFirst);
  });

  test('сид сохраняет мышцы и противопоказания', () async {
    await seeder.seed();

    final squat = await (db.select(
      db.exercises,
    )..where((t) => t.name.equals('Приседания со штангой'))).getSingle();
    final squatMuscles = await (db.select(
      db.exerciseMuscles,
    )..where((t) => t.exerciseId.equals(squat.id))).get();
    expect(squatMuscles, isNotEmpty);

    final muscleKeys = <String>{};
    for (final link in squatMuscles) {
      final muscle = await (db.select(
        db.muscleGroups,
      )..where((t) => t.id.equals(link.muscleGroupId))).getSingle();
      muscleKeys.add(muscle.key);
    }
    expect(muscleKeys, contains('quads'));

    final contraLinks = await (db.select(
      db.exerciseContraindications,
    )..where((t) => t.exerciseId.equals(squat.id))).get();
    expect(contraLinks, hasLength(2));
  });
}
