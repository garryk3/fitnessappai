// ignore_for_file: type=lint
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/domain/workout_controller.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_controller.dart';

/// Регрессия задачи 53.5 (двойное сохранение тренировки).
///
/// До фикса `completeAndSave()` проверял `saved.value`, который выставляется
/// только после `await saveSession` — параллельный вызов (автосохранение из
/// `_FinishedView` + ручное сохранение из диалога выхода) проходил проверку
/// и писал вторую сессию в БД.
void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ProgramRepository programRepo;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late int dayId;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('workout_run_ctrl_test');
    programRepo = ProgramRepository(db);
    exerciseRepo = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: (fileType) async => null,
      ),
    );
    workoutRepo = WorkoutRepository(db);

    final created = await programRepo.create(
      Program(
        name: 'База',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0)],
    );
    final day = (await programRepo.getDays(created.id!)).first;
    final exId = await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: 'Приседания',
            type: ExerciseType.strength,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        );
    await programRepo.addExerciseToDay(day.id!, exId);
    dayId = day.id!;
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  WorkoutRunController makeController({
    Future<void> Function()? checkpointClearer,
  }) => WorkoutRunController(
    programRepository: programRepo,
    exerciseRepository: exerciseRepo,
    workoutRepository: workoutRepo,
    programDayId: dayId,
    variant: WorkoutVariant.main,
    checkpointClearer: checkpointClearer,
  );

  Future<List<WorkoutSession>> allSessions() =>
      workoutRepo.getSessionsBetween(DateTime(2020), DateTime(2030));

  test(
    'параллельные вызовы completeAndSave сохраняют сессию один раз',
    () async {
      final controller = makeController();
      await controller.load();
      controller.workout.finishEarly();

      // Воспроизведение гонки: второй вызов стартует, пока первый ещё в полёте.
      await Future.wait([
        controller.completeAndSave(),
        controller.completeAndSave(),
      ]);

      expect(await allSessions(), hasLength(1));
      expect(controller.saved.value, isTrue);
    },
  );

  test('повторный вызов completeAndSave после сохранения — no-op', () async {
    final controller = makeController();
    await controller.load();
    controller.workout.finishEarly();

    await controller.completeAndSave();
    await controller.completeAndSave();

    expect(await allSessions(), hasLength(1));
  });

  test(
    'успешное сохранение очищает чекпойнт завершённой сессии (57.6)',
    () async {
      var clearCalls = 0;
      final controller = makeController(
        checkpointClearer: () async => clearCalls++,
      );
      await controller.load();
      controller.workout.finishEarly();

      await controller.completeAndSave();

      // Инвариант TC-203: завершённая сессия не возобновляется — снимок с
      // диска исчезает в момент сохранения, до любого force-stop.
      expect(await allSessions(), hasLength(1));
      expect(clearCalls, 1);
    },
  );

  test(
    'неудачное сохранение чекпойнт не трогает; после успеха — очищает',
    () async {
      final flakyRepo = _FlakyWorkoutRepository(db, failTimes: 1);
      var clearCalls = 0;
      final controller = WorkoutRunController(
        programRepository: programRepo,
        exerciseRepository: exerciseRepo,
        workoutRepository: flakyRepo,
        programDayId: dayId,
        variant: WorkoutVariant.main,
        checkpointClearer: () async => clearCalls++,
      );
      await controller.load();
      controller.workout.finishEarly();

      await expectLater(controller.completeAndSave(), throwsA(anything));
      expect(clearCalls, 0);

      await controller.completeAndSave();
      expect(await allSessions(), hasLength(1));
      expect(clearCalls, 1);
    },
  );

  test('completeAndSave до завершения фазы ничего не сохраняет', () async {
    final controller = makeController();
    await controller.load();

    await controller.completeAndSave();

    expect(await allSessions(), isEmpty);
    expect(controller.saved.value, isFalse);
  });

  test('после неудачного сохранения повторная попытка пишет сессию', () async {
    final flakyRepo = _FlakyWorkoutRepository(db, failTimes: 1);
    final controller = WorkoutRunController(
      programRepository: programRepo,
      exerciseRepository: exerciseRepo,
      workoutRepository: flakyRepo,
      programDayId: dayId,
      variant: WorkoutVariant.main,
    );
    await controller.load();
    controller.workout.finishEarly();

    await expectLater(controller.completeAndSave(), throwsA(anything));
    expect(await allSessions(), isEmpty);

    await controller.completeAndSave();
    expect(await allSessions(), hasLength(1));
  });

  test(
    'restart сбрасывает сохранение и запускает свежую сессию (54.6)',
    () async {
      final controller = makeController();
      await controller.load();
      controller.workout.finishEarly();
      await controller.completeAndSave();
      expect(controller.saved.value, isTrue);
      expect(controller.savedDetail, isNotNull);

      await controller.restart();

      // Флаги сброшены: guard'ы 53.5 не считают новую сессию сохранённой,
      // а durationMinutes не берёт длительность первой сессии из savedDetail.
      expect(controller.saved.value, isFalse);
      expect(controller.savedDetail, isNull);
      expect(controller.workout.phase.value, WorkoutPhase.exercise);
      expect(controller.workout.completedSets.value, 0);
      expect(controller.workout.results.value, isEmpty);

      // Повторное завершение пишет вторую сессию (не no-op по stale saved).
      controller.workout.finishEarly();
      await controller.completeAndSave();
      expect(await allSessions(), hasLength(2));
    },
  );
}

/// Репозиторий, чей `saveSession` падает первые [failTimes] вызовов.
class _FlakyWorkoutRepository extends WorkoutRepository {
  _FlakyWorkoutRepository(super.db, {required this.failTimes});

  int failTimes;
  int calls = 0;

  @override
  Future<WorkoutSessionDetail> saveSession(
    WorkoutSession session,
    List<WorkoutSetResult> results,
  ) async {
    calls++;
    if (calls <= failTimes) {
      throw StateError('im simulated failure');
    }
    return super.saveSession(session, results);
  }
}
