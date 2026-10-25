// ignore_for_file: type=lint
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:fitnessappai/app/bootstrap.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/seed/exercise_seeder.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late ServiceLocator container;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('bootstrap_test');
    container = ServiceLocator();
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  MediaStore mediaStore() => MediaStore(
    directoryProvider: () async => tempDir,
    assetLoader: (assetPath) async =>
        Uint8List.fromList(utf8.encode('webp:$assetPath')),
    filePicker: (fileType) async => null,
  );

  Future<String> seedJson() =>
      File(ExerciseSeeder.seedAssetPath).readAsString();

  Future<int> exercisesCount() =>
      db.select(db.exercises).get().then((rows) => rows.length);

  test('bootstrap заливает 8 упражнений и ставит флаг в app_meta', () async {
    await bootstrap(
      container: container,
      database: db,
      mediaStore: mediaStore(),
      seedJsonLoader: seedJson,
    );

    expect(await exercisesCount(), 8);
    final flag =
        await (db.select(db.appMeta)
              ..where((t) => t.key.equals(ExerciseSeeder.seededFlagKey)))
            .getSingleOrNull();
    expect(flag, isNotNull);
  });

  test('повторный bootstrap не дублирует упражнения', () async {
    await bootstrap(
      container: container,
      database: db,
      mediaStore: mediaStore(),
      seedJsonLoader: seedJson,
    );
    final count = await exercisesCount();

    await bootstrap(
      container: container,
      database: db,
      mediaStore: mediaStore(),
      seedJsonLoader: seedJson,
    );

    expect(await exercisesCount(), count);
  });

  group('восстановление чекпойнта — только «по факту» (57.2)', () {
    setUp(() {
      restoredCheckpoint = null;
      final original = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
      addTearDown(() => PathProviderPlatform.instance = original);
    });

    Future<int> createDay() async {
      final repo = ProgramRepository(db);
      final program = await repo.create(
        Program(
          name: 'Силовая',
          daysCount: 1,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        [ProgramDay(programId: 0, dayIndex: 0)],
      );
      final days = await repo.getDays(program.id!);
      return days.single.id!;
    }

    Future<void> saveCheckpoint(int dayId, DateTime startedAt) =>
        WorkoutCheckpoint(
          programDayId: dayId,
          exerciseIndex: 0,
          currentSet: 1,
          completedSets: 0,
          resultsJson: '[]',
          startedAt: startedAt,
          programName: 'Силовая',
          dayIndex: 0,
        ).save();

    Future<bool> checkpointFileExists() async => tempDir
        .listSync()
        .whereType<File>()
        .any((f) => f.path.endsWith('workout_checkpoint.json'));

    Future<void> runBootstrap() => bootstrap(
      container: container,
      database: db,
      mediaStore: mediaStore(),
      seedJsonLoader: seedJson,
    );

    test('свежий чекпойнт существующего дня восстанавливается', () async {
      final dayId = await createDay();
      await saveCheckpoint(
        dayId,
        DateTime.now().subtract(const Duration(minutes: 10)),
      );

      await runBootstrap();

      expect(restoredCheckpoint, isNotNull);
      expect(restoredCheckpoint!.programDayId, dayId);
      expect(await checkpointFileExists(), isTrue);
    });

    test('чекпойнт старше 12 часов не восстанавливается и удаляется', () async {
      final dayId = await createDay();
      await saveCheckpoint(
        dayId,
        DateTime.now().subtract(WorkoutCheckpoint.ttl),
      );

      await runBootstrap();

      expect(restoredCheckpoint, isNull);
      expect(await checkpointFileExists(), isFalse);
    });

    test(
      'чекпойнт несуществующего дня не восстанавливается и удаляется',
      () async {
        await saveCheckpoint(
          999999,
          DateTime.now().subtract(const Duration(minutes: 10)),
        );

        await runBootstrap();

        expect(restoredCheckpoint, isNull);
        expect(await checkpointFileExists(), isFalse);
      },
    );
  });
}

/// Подставник path_provider: documents → temp-каталог теста.
class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}
