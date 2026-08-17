import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  WorkoutSession session({
    int? id,
    int? programId,
    int? programDayId,
    int dayIndex = 0,
    WorkoutVariant variant = WorkoutVariant.main,
    DateTime? performedDate,
    DateTime? startedAt,
    DateTime? endedAt,
  }) => WorkoutSession(
    id: id,
    programId: programId,
    programName: 'База',
    programDayId: programDayId,
    dayIndex: dayIndex,
    variant: variant,
    performedDate: performedDate ?? DateTime(2026, 8, 10),
    startedAt: startedAt ?? DateTime(2026, 8, 10, 18, 0),
    endedAt: endedAt ?? DateTime(2026, 8, 10, 18, 40),
  );

  WorkoutSetResult setResult({
    String name = 'Приседания',
    ExerciseType type = ExerciseType.strength,
    int setIndex = 1,
    int? reps = 8,
    double? weightKg = 20,
    int? durationSeconds,
    double? distanceMeters,
    int? exerciseId,
    DateTime? completedAt,
  }) => WorkoutSetResult(
    sessionId: 0,
    exerciseId: exerciseId,
    exerciseName: name,
    exerciseType: type,
    setIndex: setIndex,
    reps: reps,
    weightKg: weightKg,
    durationSeconds: durationSeconds,
    distanceMeters: distanceMeters,
    completedAt: completedAt ?? DateTime(2026, 8, 10, 18, 5),
  );

  Future<int> createProgramDay() async {
    final programRepository = ProgramRepository(db);
    final program = await programRepository.create(
      Program(
        name: 'База',
        daysCount: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 1)],
    );
    final days = await programRepository.getDays(program.id!);
    return days[0].id!;
  }

  Future<int> insertExercise(String name) {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: ExerciseType.strength,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
  }

  test('saveSession сохраняет сессию и результаты одной транзакцией', () async {
    final detail = await repo.saveSession(session(), [
      setResult(),
      setResult(setIndex: 2, reps: 10, weightKg: 24),
    ]);

    expect(detail.session.id, isNotNull);
    expect(detail.session.programName, 'База');
    expect(detail.session.variant, WorkoutVariant.main);

    expect(detail.results, hasLength(2));
    expect(detail.results[0].sessionId, detail.session.id);
    expect(detail.results[0].setIndex, 1);
    expect(detail.results[0].reps, 8);
    expect(detail.results[0].weightKg, 20);
    expect(detail.results[1].setIndex, 2);
  });

  test('saveSession сохраняет копии имени и типа упражнения', () async {
    final detail = await repo.saveSession(session(), [
      setResult(name: 'Планка', type: ExerciseType.plank, durationSeconds: 45),
      setResult(
        name: 'Бег',
        type: ExerciseType.running,
        durationSeconds: 1800,
        distanceMeters: 5000,
      ),
    ]);

    expect(detail.results[0].exerciseName, 'Планка');
    expect(detail.results[0].durationSeconds, 45);
    expect(detail.results[1].exerciseType, ExerciseType.running);
    expect(detail.results[1].distanceMeters, 5000);
  });

  test('saveSession сохраняет сессию с пустыми результатами', () async {
    final detail = await repo.saveSession(session(), const []);

    expect(detail.session.id, isNotNull);
    expect(detail.results, isEmpty);
  });

  test('getSession возвращает сессию с результатами по id', () async {
    final saved = await repo.saveSession(session(), [
      setResult(),
      setResult(setIndex: 2),
    ]);

    final loaded = await repo.getSession(saved.session.id!);

    expect(loaded, isNotNull);
    expect(loaded!.session.id, saved.session.id);
    expect(loaded.results, hasLength(2));
    expect(loaded.results[0].sessionId, saved.session.id);
  });

  test('getSession возвращает null для отсутствующей сессии', () async {
    expect(await repo.getSession(999), isNull);
  });

  test('getSessions фильтрует сессии дня по неделе', () async {
    final dayId = await createProgramDay();
    final weekStart = DateTime(2026, 8, 10); // понедельник
    await repo.saveSession(
      session(
        programDayId: dayId,
        programId: 1,
        performedDate: DateTime(2026, 8, 10),
      ),
      [setResult()],
    );
    await repo.saveSession(
      session(
        programDayId: dayId,
        programId: 1,
        performedDate: DateTime(2026, 8, 13),
      ),
      [setResult()],
    );
    await repo.saveSession(
      session(
        programDayId: dayId,
        programId: 1,
        performedDate: DateTime(2026, 8, 17),
      ), // след. неделя
      [setResult()],
    );

    final sessions = await repo.getSessions(dayId, weekStart);

    expect(sessions, hasLength(2));
    expect(
      sessions.map((s) => s.performedDate),
      containsAll([DateTime(2026, 8, 10), DateTime(2026, 8, 13)]),
    );
  });

  test('getSessionsBetween возвращает сессии в диапазоне', () async {
    await repo.saveSession(session(performedDate: DateTime(2026, 8, 9)), [
      setResult(),
    ]);
    await repo.saveSession(session(performedDate: DateTime(2026, 8, 10)), [
      setResult(),
    ]);
    await repo.saveSession(session(performedDate: DateTime(2026, 8, 11)), [
      setResult(),
    ]);

    final sessions = await repo.getSessionsBetween(
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 11),
    );

    expect(sessions, hasLength(1));
    expect(sessions.single.performedDate, DateTime(2026, 8, 10));
  });

  test('markSkipped идемпотентно, getSkips и clearSkip работают', () async {
    final dayId = await createProgramDay();
    final weekStart = DateTime(2026, 8, 10);

    await repo.markSkipped(dayId, weekStart);
    await repo.markSkipped(dayId, weekStart);

    var skips = await repo.getSkips(weekStart);
    expect(skips, hasLength(1));
    expect(skips.single.programDayId, dayId);
    expect(skips.single.status, ScheduleMarkStatus.skipped);

    await repo.clearSkip(dayId, weekStart);
    skips = await repo.getSkips(weekStart);
    expect(skips, isEmpty);
  });

  test('getSkips не возвращает отметки других недель', () async {
    final dayId = await createProgramDay();
    await repo.markSkipped(dayId, DateTime(2026, 8, 10));
    await repo.markSkipped(dayId, DateTime(2026, 8, 17));

    final skips = await repo.getSkips(DateTime(2026, 8, 10));

    expect(skips, hasLength(1));
    expect(skips.single.weekStart, DateTime(2026, 8, 10));
  });

  test(
    'lastResultsForExercise возвращает результаты из последней сессии',
    () async {
      final squats = await insertExercise('Приседания');
      final bench = await insertExercise('Жим');
      await repo.saveSession(session(performedDate: DateTime(2026, 8, 10)), [
        setResult(exerciseId: squats, setIndex: 1, reps: 8),
        setResult(exerciseId: squats, setIndex: 2, reps: 6),
        setResult(exerciseId: bench),
      ]);
      await repo.saveSession(session(performedDate: DateTime(2026, 8, 13)), [
        setResult(exerciseId: squats, setIndex: 1, reps: 10),
        setResult(exerciseId: squats, setIndex: 2, reps: 8),
      ]);

      final results = await repo.lastResultsForExercise(squats);

      expect(results, hasLength(2));
      expect(results.map((r) => r.reps), [10, 8]);
      expect(results.map((r) => r.setIndex), [1, 2]);
    },
  );

  test('lastResultsForExercise для невыполненного упражнения пуст', () async {
    final squats = await insertExercise('Приседания');
    await repo.saveSession(session(), [setResult(exerciseId: squats)]);

    final results = await repo.lastResultsForExercise(999);

    expect(results, isEmpty);
  });
}
