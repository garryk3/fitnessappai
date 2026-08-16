import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/workout_prepare_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Воспроизводит полный флоу создания тренировки:
/// программа → день → подготовка → выполнение → финиш → saveSession.
class _FakeWakelock implements WakelockService {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ProgramRepository programRepo;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late UserProfileRepository profileRepo;
  late _FakeWakelock wakelock;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('workout_full_flow_test');
    programRepo = ProgramRepository(db);
    exerciseRepo = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: () async => null,
      ),
    );
    workoutRepo = WorkoutRepository(db);
    profileRepo = UserProfileRepository(db);
    wakelock = _FakeWakelock();
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<int> insertExercise(
    String name, {
    ExerciseType type = ExerciseType.strength,
  }) {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: type,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        );
  }

  /// Создаёт программу с одним днём и одним упражнением [type].
  Future<int> createDay({
    String name = 'Бег',
    ExerciseType type = ExerciseType.strength,
    int sets = 1,
    int? restSeconds,
    int? durationSeconds,
    double? distanceMeters,
  }) async {
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
    final exId = await insertExercise(name, type: type);
    await programRepo.addExerciseToDay(day.id!, exId);
    final position = (await programRepo.getExercises(day.id!)).first;
    await programRepo.updateExercise(
      position.copyWith(
        sets: sets,
        reps: 8,
        restSeconds: restSeconds,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
      ),
    );
    return day.id!;
  }

  Future<void> pumpFlow(WidgetTester tester, int dayId) async {
    final router = GoRouter(
      initialLocation: '/workout/prepare/$dayId',
      routes: [
        GoRoute(
          path: '/workout/prepare/:programDayId',
          builder: (context, state) => WorkoutPrepareScreen(
            programDayId: int.parse(state.pathParameters['programDayId']!),
            programRepository: programRepo,
            exerciseRepository: exerciseRepo,
            profileRepository: profileRepo,
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) => WorkoutRunScreen(
            programDayId:
                int.tryParse(state.uri.queryParameters['programDayId'] ?? '') ??
                -1,
            variant: state.uri.queryParameters['variant'] == 'alternative'
                ? WorkoutVariant.alternative
                : WorkoutVariant.main,
            programRepository: programRepo,
            exerciseRepository: exerciseRepo,
            workoutRepository: workoutRepo,
            mediaCache: MediaCache(),
            wakelockService: wakelock,
          ),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const Scaffold(body: Text('progress')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startWorkout(WidgetTester tester) async {
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'полный флоу strength: подготовка → выполнение → финиш → saveSession',
    (tester) async {
      final dayId = await createDay(
        name: 'Приседания',
        sets: 2,
        restSeconds: 60,
      );
      await pumpFlow(tester, dayId);

      expect(find.text('Приседания'), findsOneWidget);

      await startWorkout(tester);

      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pump();

      await tester.tap(find.text('Пропустить отдых'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '12');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pumpAndSettle();

      expect(find.text('Тренировка завершена'), findsOneWidget);

      await tester.tap(find.text('Завершить тренировку'));
      await tester.pumpAndSettle();

      expect(find.text('Тренировка сохранена'), findsOneWidget);
      expect(wakelock.enableCalls, 1);

      final sessions = await workoutRepo.getSessionsBetween(
        DateTime(2020),
        DateTime(2030),
      );
      expect(sessions, hasLength(1));
      final detail = await workoutRepo.getSession(sessions.first.id!);
      expect(detail!.results, hasLength(2));
      expect(detail.results.map((r) => r.reps), [10, 12]);
    },
  );

  testWidgets('полный флоу running: дробная дистанция не роняет экран', (
    tester,
  ) async {
    final dayId = await createDay(
      name: 'Бег',
      type: ExerciseType.running,
      durationSeconds: 1800,
      distanceMeters: 5000,
    );
    await pumpFlow(tester, dayId);

    await startWorkout(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Дистанция (км)'),
      '5,5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Время (мин)'),
      '30',
    );
    await tester.tap(find.text('Подход выполнен'));
    await tester.pumpAndSettle();

    expect(find.text('Тренировка завершена'), findsOneWidget);

    await tester.tap(find.text('Завершить тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Тренировка сохранена'), findsOneWidget);

    final sessions = await workoutRepo.getSessionsBetween(
      DateTime(2020),
      DateTime(2030),
    );
    final detail = await workoutRepo.getSession(sessions.first.id!);
    expect(detail!.results.single.distanceMeters, 5500);
    expect(detail.results.single.durationSeconds, 1800);
  });

  testWidgets('полный флоу plank: hold-таймер стартует и фиксируется', (
    tester,
  ) async {
    final dayId = await createDay(
      name: 'Планка',
      type: ExerciseType.plank,
      durationSeconds: 45,
    );
    await pumpFlow(tester, dayId);

    await startWorkout(tester);

    expect(find.textContaining('Удержание'), findsOneWidget);
    expect(find.textContaining('Цель: 45 с'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Время (сек)'),
      '40',
    );
    await tester.tap(find.text('Подход выполнен'));
    await tester.pumpAndSettle();

    expect(find.text('Тренировка завершена'), findsOneWidget);

    await tester.tap(find.text('Завершить тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Тренировка сохранена'), findsOneWidget);

    final sessions = await workoutRepo.getSessionsBetween(
      DateTime(2020),
      DateTime(2030),
    );
    final detail = await workoutRepo.getSession(sessions.first.id!);
    expect(detail!.results.single.durationSeconds, 40);
  });
}
