import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

void main() {
  /// Среда, 12 августа 2026 (понедельник недели — 10 августа).
  DateTime clock() => DateTime(2026, 8, 12, 12);

  late AppDatabase db;
  late Directory tempDir;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late StatsAggregator aggregator;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('stats_aggregator_test');
    exerciseRepo = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: () async => null,
      ),
    );
    workoutRepo = WorkoutRepository(db);
    aggregator = StatsAggregator(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
      clock: clock,
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  WorkoutSession session(DateTime performedDate) => WorkoutSession(
    programName: 'База',
    dayIndex: 0,
    performedDate: performedDate,
    startedAt: performedDate.add(const Duration(hours: 18)),
    endedAt: performedDate.add(const Duration(hours: 18, minutes: 40)),
  );

  Future<int> insertExercise(String name) {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: ExerciseType.strength,
            createdAt: clock(),
            updatedAt: clock(),
          ),
        );
  }

  WorkoutSetResult setResult({
    int? exerciseId,
    ExerciseType type = ExerciseType.strength,
    int? reps = 8,
    double? weightKg = 20,
    int? durationSeconds,
    double? distanceMeters,
  }) => WorkoutSetResult(
    sessionId: 0,
    exerciseId: exerciseId,
    exerciseName: 'Упражнение',
    exerciseType: type,
    setIndex: 1,
    reps: reps,
    weightKg: weightKg,
    durationSeconds: durationSeconds,
    distanceMeters: distanceMeters,
    completedAt: clock(),
  );

  group('границы периодов', () {
    test('неделя начинается с понедельника', () {
      final (start, end) = aggregator.periodBounds(StatPeriod.week);
      expect(start, DateTime(2026, 8, 10));
      expect(end, DateTime(2026, 8, 17));
    });

    test('месяц и год считаются от начала календарного периода', () {
      final (monthStart, monthEnd) = aggregator.periodBounds(StatPeriod.month);
      expect(monthStart, DateTime(2026, 8, 1));
      expect(monthEnd, DateTime(2026, 9, 1));

      final (yearStart, yearEnd) = aggregator.periodBounds(StatPeriod.year);
      expect(yearStart, DateTime(2026, 1, 1));
      expect(yearEnd, DateTime(2027, 1, 1));
    });

    test('срезы недели — 7 дней', () {
      final slices = aggregator.slices(StatPeriod.week);
      expect(slices, hasLength(7));
      expect(slices.first.$1, DateTime(2026, 8, 10));
      expect(slices.last.$2, DateTime(2026, 8, 17));
    });

    test('срезы месяца — недели с понедельника, крайние укорочены', () {
      final slices = aggregator.slices(StatPeriod.month);
      expect(slices.first.$1, DateTime(2026, 8, 1));
      expect(slices.first.$2, DateTime(2026, 8, 3));
      expect(slices.last.$1, DateTime(2026, 8, 31));
      expect(slices.last.$2, DateTime(2026, 9, 1));
      for (var i = 1; i < slices.length - 1; i++) {
        expect(slices[i].$2.difference(slices[i].$1).inDays, 7);
      }
    });

    test('срезы года — 12 месяцев', () {
      final slices = aggregator.slices(StatPeriod.year);
      expect(slices, hasLength(12));
      expect(slices.first.$1, DateTime(2026, 1, 1));
      expect(slices.last.$2, DateTime(2027, 1, 1));
    });
  });

  group('метрики', () {
    test('workoutCount считает только сессии в периоде', () async {
      await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), []);
      await workoutRepo.saveSession(session(DateTime(2026, 8, 12)), []);
      await workoutRepo.saveSession(session(DateTime(2026, 8, 1)), []);
      await workoutRepo.saveSession(session(DateTime(2026, 2, 1)), []);
      await workoutRepo.saveSession(session(DateTime(2025, 12, 31)), []);

      expect(await aggregator.workoutCount(StatPeriod.week), 2);
      expect(await aggregator.workoutCount(StatPeriod.month), 3);
      expect(await aggregator.workoutCount(StatPeriod.year), 4);
    });

    test('пустой период даёт нули', () async {
      expect(await aggregator.workoutCount(StatPeriod.week), 0);
      expect(await aggregator.totalDistance(StatPeriod.week), 0);
      expect(await aggregator.totalPlankTime(StatPeriod.week), Duration.zero);
      expect(await aggregator.totalReps(1, StatPeriod.week), 0);
      expect(await aggregator.maxWeight(1, StatPeriod.week), isNull);
      expect(await aggregator.muscleLoadPercent(StatPeriod.week), isEmpty);
      expect(
        await aggregator.workoutCountPerSlice(StatPeriod.week),
        List.filled(7, 0),
      );
    });

    test('totalDistance суммирует только бег', () async {
      await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
        setResult(
          type: ExerciseType.running,
          reps: null,
          weightKg: null,
          distanceMeters: 1000,
          durationSeconds: 300,
        ),
        setResult(
          type: ExerciseType.running,
          reps: null,
          weightKg: null,
          distanceMeters: 2500,
          durationSeconds: 600,
        ),
        setResult(),
      ]);

      expect(await aggregator.totalDistance(StatPeriod.week), 3500);
    });

    test('totalPlankTime суммирует только планку', () async {
      await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
        setResult(
          type: ExerciseType.plank,
          reps: null,
          weightKg: null,
          durationSeconds: 30,
        ),
        setResult(
          type: ExerciseType.plank,
          reps: null,
          weightKg: null,
          durationSeconds: 60,
        ),
        setResult(),
      ]);

      expect(
        await aggregator.totalPlankTime(StatPeriod.week),
        const Duration(seconds: 90),
      );
    });

    test('maxWeight ищет максимум по упражнению', () async {
      final first = await insertExercise('Приседания');
      final second = await insertExercise('Тяга');

      await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
        setResult(exerciseId: first, weightKg: 20),
        setResult(exerciseId: first, weightKg: 40),
        setResult(exerciseId: first, weightKg: 35),
        setResult(exerciseId: second, weightKg: 100),
      ]);

      expect(await aggregator.maxWeight(first, StatPeriod.week), 40);
      expect(await aggregator.maxWeight(second, StatPeriod.week), 100);
      expect(await aggregator.maxWeight(999, StatPeriod.week), isNull);
    });

    test('totalReps суммирует повторения по упражнению', () async {
      final first = await insertExercise('Приседания');
      final second = await insertExercise('Тяга');

      await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
        setResult(exerciseId: first, reps: 8),
        setResult(exerciseId: first, reps: 10),
        setResult(exerciseId: second, reps: 5),
      ]);

      expect(await aggregator.totalReps(first, StatPeriod.week), 18);
      expect(await aggregator.totalReps(second, StatPeriod.week), 5);
    });

    test(
      'workoutCountPerSlice раскладывает тренировки по дням недели',
      () async {
        await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), []);
        await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), []);
        await workoutRepo.saveSession(session(DateTime(2026, 8, 12)), []);

        expect(await aggregator.workoutCountPerSlice(StatPeriod.week), [
          2,
          0,
          1,
          0,
          0,
          0,
          0,
        ]);
      },
    );
  });

  group('нагрузка на мышцы', () {
    test('primary даёт 1.0, secondary 0.5, сумма ≈ 100%', () async {
      final groups = await exerciseRepo.getAllMuscleGroups();
      final primary = groups.first;
      final secondary = groups.last;

      final exercise = await exerciseRepo.create(
        Exercise(
          name: 'Приседания',
          type: ExerciseType.strength,
          createdAt: clock(),
          updatedAt: clock(),
        ),
        [
          ExerciseMuscle(
            exerciseId: 0,
            muscleGroupId: primary.id!,
            intensity: MuscleIntensity.primary,
          ),
          ExerciseMuscle(
            exerciseId: 0,
            muscleGroupId: secondary.id!,
            intensity: MuscleIntensity.secondary,
          ),
        ],
      );

      await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
        setResult(exerciseId: exercise.id),
        setResult(exerciseId: exercise.id),
      ]);

      final loads = await aggregator.muscleLoadPercent(StatPeriod.week);
      expect(loads, hasLength(2));
      expect(loads.first.muscleGroup.key, primary.key);
      expect(loads.first.percent, closeTo(200 / 3, 0.01));
      expect(loads.last.muscleGroup.key, secondary.key);
      expect(loads.last.percent, closeTo(100 / 3, 0.01));
      final total = loads.fold<double>(0, (sum, l) => sum + l.percent);
      expect(total, closeTo(100, 0.01));
    });

    test('подходы без упражнения и без привязок мышц не учитываются', () async {
      final groups = await exerciseRepo.getAllMuscleGroups();
      final group = groups.first;
      final withMuscles = await exerciseRepo.create(
        Exercise(
          name: 'С мышцами',
          type: ExerciseType.strength,
          createdAt: clock(),
          updatedAt: clock(),
        ),
        [
          ExerciseMuscle(
            exerciseId: 0,
            muscleGroupId: group.id!,
            intensity: MuscleIntensity.primary,
          ),
        ],
      );
      final withoutMuscles = await exerciseRepo.create(
        Exercise(
          name: 'Без мышц',
          type: ExerciseType.strength,
          createdAt: clock(),
          updatedAt: clock(),
        ),
        const [],
      );

      await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
        setResult(exerciseId: withMuscles.id),
        setResult(exerciseId: withoutMuscles.id),
        setResult(exerciseId: null),
      ]);

      final loads = await aggregator.muscleLoadPercent(StatPeriod.week);
      expect(loads, hasLength(1));
      expect(loads.single.percent, closeTo(100, 0.01));
    });
  });
}
