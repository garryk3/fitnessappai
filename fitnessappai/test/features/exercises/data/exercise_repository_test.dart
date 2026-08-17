import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaStore mediaStore;
  late ExerciseRepository repo;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('exercise_repo_test');
    mediaStore = MediaStore(
      directoryProvider: () async => tempDir,
      assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
      filePicker: (fileType) async => null,
    );
    repo = ExerciseRepository(db, mediaStore);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Exercise exercise({
    String name = 'Жим штанги',
    ExerciseType type = ExerciseType.strength,
    String description = '',
    String instructions = '',
    List<String> commonMistakes = const [],
    bool isCustom = false,
    String? thumbnailPath,
    String? animationPath,
  }) {
    return Exercise(
      name: name,
      description: description,
      instructions: instructions,
      commonMistakes: commonMistakes,
      type: type,
      thumbnailPath: thumbnailPath,
      animationPath: animationPath,
      isCustom: isCustom,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  Future<int> muscleId(String key) async {
    final row = await (db.select(
      db.muscleGroups,
    )..where((t) => t.key.equals(key))).getSingle();
    return row.id;
  }

  Future<int> tagId(String key) async {
    final row = await (db.select(
      db.contraindicationTags,
    )..where((t) => t.key.equals(key))).getSingle();
    return row.id;
  }

  group('CRUD', () {
    test('create сохраняет все поля и возвращает id', () async {
      final created = await repo.create(
        exercise(
          description: 'Базовое движение',
          instructions: 'Лечь на скамью',
          commonMistakes: const ['отрыв таза'],
          isCustom: true,
        ),
        const [],
      );
      expect(created.id, isNotNull);
      expect(created.description, 'Базовое движение');
      expect(created.instructions, 'Лечь на скамью');
      expect(created.commonMistakes, ['отрыв таза']);
      expect(created.isCustom, isTrue);
      expect(created.type, ExerciseType.strength);

      final fromDb = await repo.getById(created.id!);
      expect(fromDb, created);
    });

    test('getById возвращает null для отсутствующего id', () async {
      expect(await repo.getById(999), isNull);
    });

    test('getAll сортирует по названию', () async {
      await repo.create(
        exercise(name: 'Бег трусцой', type: ExerciseType.running),
        const [],
      );
      await repo.create(
        exercise(name: 'Планка', type: ExerciseType.plank),
        const [],
      );
      await repo.create(exercise(name: 'Жим штанги'), const []);

      final all = await repo.getAll();
      expect(all.map((e) => e.name), ['Бег трусцой', 'Жим штанги', 'Планка']);
    });

    test('update изменяет поля', () async {
      final created = await repo.create(exercise(), const []);
      final updated = await repo.update(
        created.copyWith(name: 'Жим гантелей', instructions: 'Новая техника'),
      );
      expect(updated.name, 'Жим гантелей');
      expect(updated.instructions, 'Новая техника');
      expect((await repo.getById(created.id!))!.name, 'Жим гантелей');
    });

    test('update удаляет привязки мышц при передаче пустого списка', () async {
      final chest = await muscleId('chest');
      final created = await repo.create(exercise(), [
        ExerciseMuscle(
          exerciseId: 0,
          muscleGroupId: chest,
          intensity: MuscleIntensity.primary,
        ),
      ]);
      final updated = await repo.update(created.copyWith(), muscles: const []);
      expect(updated.id, created.id);
      expect(await repo.getMuscles(created.id!), isEmpty);
    });

    test('delete удаляет упражнение и его связи', () async {
      final chest = await muscleId('chest');
      final knees = await tagId('knees');
      final created = await repo.create(exercise(), [
        ExerciseMuscle(
          exerciseId: 0,
          muscleGroupId: chest,
          intensity: MuscleIntensity.primary,
        ),
      ]);
      await repo.setContraindications(created.id!, [knees]);

      await repo.delete(created.id!);

      expect(await repo.getById(created.id!), isNull);
      expect(await repo.getMuscles(created.id!), isEmpty);
      expect(await repo.getContraindications(created.id!), isEmpty);
    });

    test('delete не бросает исключение для отсутствующего id', () async {
      await expectLater(repo.delete(999), completes);
    });
  });

  group('поиск и фильтр', () {
    test('search находит по подстроке без учёта регистра', () async {
      await repo.create(exercise(name: 'Жим штанги'), const []);
      await repo.create(exercise(name: 'Жим гантелей'), const []);
      await repo.create(
        exercise(name: 'Бег трусцой', type: ExerciseType.running),
        const [],
      );

      final results = await repo.search('жим');
      expect(results.map((e) => e.name).toList(), [
        'Жим гантелей',
        'Жим штанги',
      ]);
    });

    test('search пустой строки возвращает все упражнения', () async {
      await repo.create(exercise(), const []);
      await repo.create(
        exercise(name: 'Планка', type: ExerciseType.plank),
        const [],
      );
      expect(await repo.search(''), hasLength(2));
      expect(await repo.search('   '), hasLength(2));
    });

    test('getByType фильтрует по типу', () async {
      await repo.create(exercise(), const []);
      await repo.create(
        exercise(name: 'Планка', type: ExerciseType.plank),
        const [],
      );
      await repo.create(
        exercise(name: 'Бег трусцой', type: ExerciseType.running),
        const [],
      );

      final planks = await repo.getByType(ExerciseType.plank);
      expect(planks.map((e) => e.name), ['Планка']);
      expect(await repo.getByType(ExerciseType.running), hasLength(1));
    });
  });

  group('мышцы', () {
    test('create сохраняет мышцы', () async {
      final chest = await muscleId('chest');
      final shoulders = await muscleId('shoulders');
      final created = await repo.create(exercise(), [
        ExerciseMuscle(
          exerciseId: 0,
          muscleGroupId: chest,
          intensity: MuscleIntensity.primary,
        ),
        ExerciseMuscle(
          exerciseId: 0,
          muscleGroupId: shoulders,
          intensity: MuscleIntensity.secondary,
        ),
      ]);
      final muscles = await repo.getMuscles(created.id!);
      expect(muscles, hasLength(2));
      expect(
        muscles.where((m) => m.muscleGroupId == chest).single.intensity,
        MuscleIntensity.primary,
      );
      expect(
        muscles.where((m) => m.muscleGroupId == shoulders).single.intensity,
        MuscleIntensity.secondary,
      );
    });

    test('setMuscles заменяет существующие привязки', () async {
      final chest = await muscleId('chest');
      final created = await repo.create(exercise(), const []);
      await repo.setMuscles(created.id!, [
        ExerciseMuscle(
          exerciseId: created.id!,
          muscleGroupId: chest,
          intensity: MuscleIntensity.primary,
        ),
      ]);
      expect(await repo.getMuscles(created.id!), hasLength(1));

      final quads = await muscleId('quads');
      await repo.setMuscles(created.id!, [
        ExerciseMuscle(
          exerciseId: created.id!,
          muscleGroupId: quads,
          intensity: MuscleIntensity.primary,
        ),
      ]);
      final muscles = await repo.getMuscles(created.id!);
      expect(muscles, hasLength(1));
      expect(muscles.single.muscleGroupId, quads);
    });
  });

  group('противопоказания', () {
    test('setContraindications сохраняет и заменяет теги', () async {
      final created = await repo.create(exercise(), const []);
      final knees = await tagId('knees');
      final back = await tagId('back');

      await repo.setContraindications(created.id!, [knees, back]);
      var tags = await repo.getContraindications(created.id!);
      expect(tags.map((t) => t.key).toSet(), {'knees', 'back'});

      await repo.setContraindications(created.id!, [knees]);
      tags = await repo.getContraindications(created.id!);
      expect(tags.map((t) => t.key).toList(), ['knees']);
      expect(tags.single, isA<ContraindicationTag>());
      expect(tags.single.labelRu, 'Колени');
    });
  });

  group('удаление файлов медиа', () {
    test('delete удаляет файлы миниатюры и анимации', () async {
      final thumb = await mediaStore.copyAssetToStorage('assets/thumb.png');
      final anim = await mediaStore.copyAssetToStorage('assets/anim.webp');
      expect(await File(thumb).exists(), isTrue);
      expect(await File(anim).exists(), isTrue);

      final created = await repo.create(
        exercise(thumbnailPath: thumb, animationPath: anim),
        const [],
      );
      await repo.delete(created.id!);

      expect(await File(thumb).exists(), isFalse);
      expect(await File(anim).exists(), isFalse);
    });

    test('delete не трогает файлы, не привязанные к упражнению', () async {
      final unused = p.join(tempDir.path, 'unused.webp');
      await File(unused).writeAsBytes([1, 2, 3]);
      final created = await repo.create(exercise(), const []);
      await repo.delete(created.id!);
      expect(await File(unused).exists(), isTrue);
    });
  });

  group('использование в программах', () {
    test(
      'referencedPrograms возвращает названия программ с упражнением',
      () async {
        final created = await repo.create(exercise(), const []);
        final programRepo = ProgramRepository(db);
        final program = await programRepo.create(
          Program(
            name: 'База',
            daysCount: 1,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          [ProgramDay(programId: 0, dayIndex: 0)],
        );
        final day = (await programRepo.getDays(program.id!)).first;
        await programRepo.addExerciseToDay(day.id!, created.id!);

        final names = await repo.referencedPrograms(created.id!);
        expect(names, ['База']);
      },
    );

    test('referencedPrograms пуст для неиспользуемого упражнения', () async {
      final created = await repo.create(exercise(), const []);
      expect(await repo.referencedPrograms(created.id!), isEmpty);
    });
  });
}
