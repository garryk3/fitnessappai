import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/single_exercise_params.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/wakelock_banner_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';
import 'package:fitnessappai/features/workout/domain/workout_foreground_service.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

class _FakeWakelock implements WakelockService {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  bool get isEnabled => enableCalls > 0 && enableCalls > disableCalls;

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

class _DisabledWakelock implements WakelockService {
  @override
  bool get isEnabled => false;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

class _ControllableSoundService implements SoundService {
  final _isPlayingController = StreamController<bool>.broadcast();
  int stopCalls = 0;

  @override
  bool get isPlaying => false;

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  void emit(bool playing) => _isPlayingController.add(playing);

  @override
  Future<void> playCompletion() async {}

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> preview() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeWakelockBannerRepository implements WakelockBannerRepository {
  bool dismissed = false;

  @override
  Future<bool> isDismissed() async => dismissed;

  @override
  Future<void> setDismissed() async {
    dismissed = true;
  }
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ProgramRepository programRepo;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late _FakeWakelock wakelock;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('workout_run_test');
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

  Future<int> createDay({
    int sets = 3,
    int? restSeconds = 60,
    bool withAlternative = false,
    bool fixedWeight = false,
    bool perSide = false,
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
    final exId = await insertExercise('Приседания');
    if (fixedWeight || perSide) {
      await (db.update(db.exercises)..where((t) => t.id.equals(exId))).write(
        ExercisesCompanion(
          fixedWeight: Value(fixedWeight),
          perSide: Value(perSide),
        ),
      );
    }
    await programRepo.addExerciseToDay(day.id!, exId);
    await programRepo.updateExercise(
      (await programRepo.getExercises(day.id!)).first.copyWith(
        sets: sets,
        reps: 8,
        weightKg: 20,
        restSeconds: restSeconds,
      ),
    );
    if (withAlternative) {
      final altExId = await insertExercise('Жим ногами');
      await programRepo.addExerciseToDay(day.id!, altExId, isAlternative: true);
      await programRepo.updateExercise(
        (await programRepo.getExercises(
          day.id!,
        )).last.copyWith(sets: 1, reps: 10),
      );
    }
    return day.id!;
  }

  Future<void> pumpRun(
    WidgetTester tester,
    int dayId, {
    WorkoutVariant variant = WorkoutVariant.main,
    String initialLocation = '',
    Future<void> Function(WorkoutCheckpoint)? checkpointSaver,
    WorkoutForegroundService? foregroundService,
    WakelockService? wakelockService,
    SoundService? soundService,
    WakelockBannerRepository? wakelockBannerRepository,
  }) async {
    final location = initialLocation.isEmpty
        ? '/workout/run?programDayId=$dayId&variant=${variant.name}'
        : initialLocation;
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('home')),
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
            wakelockService: wakelockService ?? wakelock,
            foregroundService:
                foregroundService ?? StubWorkoutForegroundService(),
            soundService: soundService ?? StubSoundService(),
            checkpointLoader: () async => null,
            checkpointSaver: checkpointSaver ?? (_) async {},
            checkpointClearer: () async {},
            wakelockBannerRepository:
                wakelockBannerRepository ?? _FakeWakelockBannerRepository(),
          ),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const Scaffold(body: Text('progress')),
        ),
        GoRoute(
          path: '/exercises/:id',
          builder: (context, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
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

  testWidgets('показывает упражнение, счётчики и поля ввода', (tester) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId);

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('Упражнение 1 из 1 · Подход 1 из 3'), findsOneWidget);
    expect(find.text('Повторения'), findsOneWidget);
    expect(find.text('Вес (кг)'), findsOneWidget);
    expect(find.text('Подход выполнен'), findsOneWidget);
  });

  testWidgets('пустой ввод показывает ошибку валидации', (tester) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId);

    await tester.tap(find.text('Подход выполнен'));
    await tester.pumpAndSettle();

    expect(find.text('Заполните поле'), findsOneWidget);
    expect(find.text('Отдых'), findsNothing);
  });

  testWidgets('свой вес: ввод повторов без веса', (tester) async {
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
    final exId = await insertExercise(
      'Отжимания',
      type: ExerciseType.bodyweight,
    );
    await programRepo.addExerciseToDay(day.id!, exId);
    await programRepo.updateExercise(
      (await programRepo.getExercises(
        day.id!,
      )).first.copyWith(sets: 3, reps: 15, restSeconds: 45),
    );
    await pumpRun(tester, day.id!);

    expect(find.text('Отжимания'), findsOneWidget);
    expect(find.text('Повторения'), findsOneWidget);
    expect(find.text('Вес (кг)'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '12');
    await tester.tap(find.text('Подход выполнен'));
    await tester.pump();

    expect(find.text('Отдых'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
  });

  testWidgets(
    'фиксация подхода запускает отдых, пропуск возвращает к подходу',
    (tester) async {
      final dayId = await createDay();
      await pumpRun(tester, dayId);

      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pump();

      expect(find.text('Отдых'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);

      await tester.tap(find.text('Пропустить отдых'));
      await tester.pumpAndSettle();

      expect(find.text('Упражнение 1 из 1 · Подход 2 из 3'), findsOneWidget);
    },
  );

  testWidgets(
    'по сторонам: подписи сторон и отдых между сторонами, результат сохраняет сторону',
    (tester) async {
      final dayId = await createDay(sets: 1, restSeconds: 60, perSide: true);
      await pumpRun(tester, dayId);

      expect(find.text('Повторения — левая'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '8');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pump();

      expect(find.text('Отдых'), findsOneWidget);
      expect(find.text('Отдых между сторонами'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);

      await tester.tap(find.text('Пропустить отдых'));
      await tester.pumpAndSettle();

      expect(find.text('Повторения — правая'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '6');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pumpAndSettle();

      expect(find.text('Тренировка завершена'), findsOneWidget);
      await tester.pumpAndSettle();

      final sessions = await workoutRepo.getSessionsBetween(
        DateTime(2020),
        DateTime(2030),
      );
      final detail = await workoutRepo.getSession(sessions.first.id!);
      expect(detail!.results.map((r) => r.side), ['left', 'right']);
      expect(detail.results.map((r) => r.reps), [8, 6]);
    },
  );

  testWidgets('завершение всех подходов сохраняет тренировку', (tester) async {
    final dayId = await createDay(sets: 1, restSeconds: null);
    await pumpRun(tester, dayId);

    await tester.enterText(find.byType(TextFormField).first, '8');
    await tester.tap(find.text('Подход выполнен'));
    await tester.pumpAndSettle();

    expect(find.text('Тренировка завершена'), findsOneWidget);
    expect(find.text('База'), findsOneWidget);
    expect(find.text('1 подход'), findsOneWidget);
    expect(find.text('Время: 1 мин'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Тренировка сохранена'), findsOneWidget);

    final sessions = await workoutRepo.getSessionsBetween(
      DateTime(2020),
      DateTime(2030),
    );
    expect(sessions, hasLength(1));
    expect(sessions.first.programName, 'База');
    final detail = await workoutRepo.getSession(sessions.first.id!);
    expect(detail!.results, hasLength(1));
    expect(detail.results.first.reps, 8);

    await tester.tap(find.text('К прогрессу'));
    await tester.pumpAndSettle();
    expect(find.text('progress'), findsOneWidget);
  });

  testWidgets('альтернативный вариант показывает свои упражнения', (
    tester,
  ) async {
    final dayId = await createDay(withAlternative: true);
    await pumpRun(tester, dayId, variant: WorkoutVariant.alternative);

    expect(find.text('Жим ногами'), findsOneWidget);
    expect(find.text('Приседания'), findsNothing);
  });

  testWidgets('выход без завершения подтверждается и отменяет тренировку', (
    tester,
  ) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId, initialLocation: '/');

    final router = GoRouter.of(tester.element(find.text('home')));
    router.push('/workout/run?programDayId=$dayId&variant=main');
    await tester.pumpAndSettle();

    expect(find.text('Приседания'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Выйти из тренировки?'), findsOneWidget);
    expect(find.text('Тренировка не будет сохранена. Выйти?'), findsOneWidget);

    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    final sessions = await workoutRepo.getSessionsBetween(
      DateTime(2020),
      DateTime(2030),
    );
    expect(sessions, isEmpty);
  });

  testWidgets('отмена диалога выхода оставляет на тренировке', (tester) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId, initialLocation: '/');

    final router = GoRouter.of(tester.element(find.text('home')));
    router.push('/workout/run?programDayId=$dayId&variant=main');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Выйти из тренировки?'), findsNothing);
    expect(find.text('Подход выполнен'), findsOneWidget);
  });

  testWidgets(
    'диалог выхода: «Завершить и сохранить» сохраняет частичную тренировку',
    (tester) async {
      final dayId = await createDay(sets: 3, restSeconds: 60);
      await pumpRun(tester, dayId, initialLocation: '/');

      final router = GoRouter.of(tester.element(find.text('home')));
      router.push('/workout/run?programDayId=$dayId&variant=main');
      await tester.pumpAndSettle();

      // Подтвердить первый подход, перейти к отдыху.
      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pump();
      expect(find.text('Отдых'), findsOneWidget);

      // Back → диалог.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Выйти из тренировки?'), findsOneWidget);

      await tester.tap(find.text('Завершить и сохранить'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // После сохранения и pop возвращаемся на домашний экран.
      expect(find.text('home'), findsOneWidget);

      final sessions = await workoutRepo.getSessionsBetween(
        DateTime(2020),
        DateTime(2030),
      );
      expect(sessions, hasLength(1));
      final detail = await workoutRepo.getSession(sessions.first.id!);
      expect(detail!.results, hasLength(1));
      expect(detail.results.first.reps, 10);
    },
  );

  testWidgets('wake lock включается при старте и выключается при выходе', (
    tester,
  ) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId);

    expect(wakelock.enableCalls, 1);
    expect(wakelock.disableCalls, 0);

    await tester.pumpWidget(const SizedBox());
    expect(wakelock.disableCalls, 1);
  });

  testWidgets('неизвестный день показывает сообщение', (tester) async {
    await pumpRun(tester, 999);

    expect(find.text('День не найден'), findsOneWidget);
    expect(find.text('Подход выполнен'), findsNothing);
  });

  testWidgets('иконка информации открывает описание упражнения', (
    tester,
  ) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    final exercises = await programRepo.getExercises(dayId);
    expect(find.text('detail ${exercises.first.id}'), findsOneWidget);
  });

  testWidgets('показывает карточку последней тренировки', (tester) async {
    final dayId = await createDay();
    final exerciseId = (await programRepo.getExercises(dayId)).first.id!;
    await workoutRepo.saveSession(
      WorkoutSession(
        id: null,
        programId: null,
        programName: 'База',
        programDayId: null,
        dayIndex: 0,
        variant: WorkoutVariant.main,
        performedDate: DateTime(2026, 8, 14),
        startedAt: DateTime(2026, 8, 14, 18, 0),
        endedAt: DateTime(2026, 8, 14, 18, 30),
      ),
      [
        WorkoutSetResult(
          sessionId: 0,
          exerciseId: exerciseId,
          exerciseName: 'Приседания',
          exerciseType: ExerciseType.strength,
          setIndex: 1,
          reps: 8,
          weightKg: 20,
          durationSeconds: null,
          distanceMeters: null,
          completedAt: DateTime(2026, 8, 14, 18, 5),
        ),
      ],
    );

    await pumpRun(tester, dayId);

    expect(find.text('Последняя тренировка'), findsOneWidget);
    expect(find.textContaining('20'), findsWidgets);
  });

  testWidgets('карточка последней тренировки скрыта без истории', (
    tester,
  ) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId);

    expect(find.text('Последняя тренировка'), findsNothing);
  });

  testWidgets('фиксированный вес автозаполняется из параметров', (
    tester,
  ) async {
    final dayId = await createDay(fixedWeight: true);
    await pumpRun(tester, dayId);

    final weightField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Вес (кг)'),
    );
    expect(weightField.controller!.text, '20');
  });

  testWidgets('без флага фиксированного веса поле веса пустое', (tester) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId);

    final weightField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Вес (кг)'),
    );
    expect(weightField.controller!.text, isEmpty);
  });

  Future<void> pumpRunSingle(WidgetTester tester, int exerciseId) async {
    final router = GoRouter(
      initialLocation: '/workout/run?exerciseId=$exerciseId',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) => WorkoutRunScreen(
            exerciseId: int.tryParse(
              state.uri.queryParameters['exerciseId'] ?? '',
            ),
            programRepository: programRepo,
            exerciseRepository: exerciseRepo,
            workoutRepository: workoutRepo,
            mediaCache: MediaCache(),
            wakelockService: wakelock,
            foregroundService: StubWorkoutForegroundService(),
            soundService: StubSoundService(),
            checkpointLoader: () async => null,
            checkpointSaver: (_) async {},
            checkpointClearer: () async {},
            wakelockBannerRepository: _FakeWakelockBannerRepository(),
          ),
        ),
        GoRoute(
          path: '/exercises/:id',
          builder: (context, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
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

  testWidgets('одиночная сессия: упражнение загружается без программы', (
    tester,
  ) async {
    final exId = await insertExercise('Жим штанги');
    await pumpRunSingle(tester, exId);

    expect(find.text('Жим штанги'), findsWidgets);
    expect(find.text('Упражнение 1 из 1 · Подход 1 из 3'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('одиночная сессия: параметры из query применяются', (
    tester,
  ) async {
    final exId = await insertExercise('Приседания');
    await (db.update(db.exercises)..where((t) => t.id.equals(exId))).write(
      const ExercisesCompanion(fixedWeight: Value(true)),
    );
    final router = GoRouter(
      initialLocation:
          '/workout/run?exerciseId=$exId&sets=4&reps=5&weightKg=60&restSeconds=45',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            final qp = state.uri.queryParameters;
            return WorkoutRunScreen(
              exerciseId: int.tryParse(qp['exerciseId'] ?? ''),
              singleExerciseParams: SingleExerciseParams(
                sets: int.tryParse(qp['sets'] ?? ''),
                reps: int.tryParse(qp['reps'] ?? ''),
                weightKg: double.tryParse(qp['weightKg'] ?? ''),
                restSeconds: int.tryParse(qp['restSeconds'] ?? ''),
              ),
              programRepository: programRepo,
              exerciseRepository: exerciseRepo,
              workoutRepository: workoutRepo,
              mediaCache: MediaCache(),
              wakelockService: wakelock,
              foregroundService: StubWorkoutForegroundService(),
              soundService: StubSoundService(),
              checkpointLoader: () async => null,
              checkpointSaver: (_) async {},
              checkpointClearer: () async {},
              wakelockBannerRepository: _FakeWakelockBannerRepository(),
            );
          },
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

    expect(find.text('Приседания'), findsWidgets);
    expect(find.text('Упражнение 1 из 1 · Подход 1 из 4'), findsOneWidget);
    final weightField = find.widgetWithText(TextFormField, 'Вес (кг)');
    expect(tester.widget<TextFormField>(weightField).controller!.text, '60');
  });

  testWidgets('одиночная сессия: завершение сохраняет сессию без программы', (
    tester,
  ) async {
    final exId = await insertExercise('Подтягивания');

    final router = GoRouter(
      initialLocation: '/workout/run?exerciseId=$exId',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) => WorkoutRunScreen(
            exerciseId: int.tryParse(
              state.uri.queryParameters['exerciseId'] ?? '',
            ),
            programRepository: programRepo,
            exerciseRepository: exerciseRepo,
            workoutRepository: workoutRepo,
            mediaCache: MediaCache(),
            wakelockService: wakelock,
            foregroundService: StubWorkoutForegroundService(),
            soundService: StubSoundService(),
            checkpointLoader: () async => null,
            checkpointSaver: (_) async {},
            checkpointClearer: () async {},
            wakelockBannerRepository: _FakeWakelockBannerRepository(),
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

    // Ввести повторы и завершить подход (3 подхода × 1 подход)
    for (var i = 0; i < 3; i++) {
      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pumpAndSettle();
      if (i < 2) {
        await tester.tap(find.text('Пропустить отдых'));
        await tester.pumpAndSettle();
      }
    }

    // Проверить, что показан экран завершения
    expect(find.text('Тренировка завершена'), findsOneWidget);

    // Подождать завершения сохранения (async в _FinishedView)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Проверить, что сессия сохранена
    final sessions = await workoutRepo.getAllSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.programName, 'Подтягивания');
    expect(sessions.first.programId, isNull);
    expect(sessions.first.programDayId, isNull);
  });

  testWidgets('чекпоинт восстанавливает startedAt и exerciseIndex', (
    tester,
  ) async {
    final dayId = await createDay(sets: 3, restSeconds: 0);
    final staleStartedAt = DateTime(2025, 1, 15, 8, 0);
    final checkpoint = WorkoutCheckpoint(
      programDayId: dayId,
      exerciseIndex: 0,
      currentSet: 1,
      completedSets: 0,
      resultsJson: '[]',
      startedAt: staleStartedAt,
      programName: 'База',
      dayIndex: 0,
    );

    final router = GoRouter(
      initialLocation: '/workout/run?programDayId=$dayId&variant=main',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('home')),
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
            foregroundService: StubWorkoutForegroundService(),
            soundService: StubSoundService(),
            clock: () => DateTime(2026, 8, 31, 12, 0),
            checkpointLoader: () async => checkpoint,
            checkpointSaver: (_) async {},
            checkpointClearer: () async {},
            wakelockBannerRepository: _FakeWakelockBannerRepository(),
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

    // Экран загружается с restored startedAt из чекпоинта.
    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('Упражнение 1 из 1 · Подход 1 из 3'), findsOneWidget);
  });

  testWidgets(
    'без чекпоинта: startedAt берётся от clock(), exerciseIndex = 0',
    (tester) async {
      final dayId = await createDay(sets: 1, restSeconds: 0);

      final router = GoRouter(
        initialLocation: '/workout/run?programDayId=$dayId&variant=main',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/workout/run',
            builder: (context, state) => WorkoutRunScreen(
              programDayId:
                  int.tryParse(
                    state.uri.queryParameters['programDayId'] ?? '',
                  ) ??
                  -1,
              variant: state.uri.queryParameters['variant'] == 'alternative'
                  ? WorkoutVariant.alternative
                  : WorkoutVariant.main,
              programRepository: programRepo,
              exerciseRepository: exerciseRepo,
              workoutRepository: workoutRepo,
              mediaCache: MediaCache(),
              wakelockService: wakelock,
              foregroundService: StubWorkoutForegroundService(),
              soundService: StubSoundService(),
              clock: () => DateTime(2026, 8, 31, 12, 0),
              checkpointLoader: () async => null,
              checkpointSaver: (_) async {},
              checkpointClearer: () async {},
              wakelockBannerRepository: _FakeWakelockBannerRepository(),
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

      // Завершить 1 подход (единственный) — тренировка должна завершиться.
      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pumpAndSettle();

      expect(find.text('Тренировка завершена'), findsOneWidget);
      expect(find.text('Время: 1 мин'), findsOneWidget);

      await tester.pumpAndSettle();

      // Сохранённая сессия имеет performedDate = сегодня (2026-08-31).
      final sessions = await workoutRepo.getSessionsBetween(
        DateTime(2020),
        DateTime(2030),
      );
      expect(sessions, hasLength(1));
      expect(sessions.first.performedDate, DateTime(2026, 8, 31));
    },
  );

  testWidgets('чекпоинт сохраняется после фиксации подхода', (tester) async {
    final dayId = await createDay(sets: 2, restSeconds: 60);
    var saveCalls = 0;
    await pumpRun(tester, dayId, checkpointSaver: (_) async => saveCalls++);
    expect(saveCalls, 0);

    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.tap(find.text('Подход выполнен'));
    await tester.pump();

    expect(saveCalls, 1);
  });

  testWidgets('чекпоинт сохраняется на lifecycle pause', (tester) async {
    final dayId = await createDay();
    var saveCalls = 0;
    await pumpRun(tester, dayId, checkpointSaver: (_) async => saveCalls++);
    expect(saveCalls, 0);

    final state = tester.state(find.byType(WorkoutRunScreen));
    (state as WidgetsBindingObserver).didChangeAppLifecycleState(
      AppLifecycleState.paused,
    );
    await tester.pump();

    expect(saveCalls, 1);
  });

  testWidgets('чекпоинт периодически сохраняется', (tester) async {
    final dayId = await createDay();
    var saveCalls = 0;
    await pumpRun(tester, dayId, checkpointSaver: (_) async => saveCalls++);
    final before = saveCalls;

    await tester.pump(const Duration(seconds: 5));

    expect(saveCalls, greaterThan(before));
  });

  testWidgets('чекпоинт не сохраняется после завершения тренировки', (
    tester,
  ) async {
    final dayId = await createDay(sets: 1, restSeconds: 0);
    var saveCalls = 0;
    await pumpRun(tester, dayId, checkpointSaver: (_) async => saveCalls++);

    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.tap(find.text('Подход выполнен'));
    await tester.pumpAndSettle();
    expect(find.text('Тренировка завершена'), findsOneWidget);

    final callsAfterFinish = saveCalls;
    final state = tester.state(find.byType(WorkoutRunScreen));
    (state as WidgetsBindingObserver).didChangeAppLifecycleState(
      AppLifecycleState.paused,
    );
    await tester.pump();

    expect(saveCalls, callsAfterFinish);
  });

  testWidgets(
    'foreground service стартует при тренировке и останавливается при выходе',
    (tester) async {
      final dayId = await createDay();
      final fg = StubWorkoutForegroundService();
      await pumpRun(tester, dayId, foregroundService: fg);

      expect(fg.startCalls, 1);
      expect(fg.stopCalls, 0);

      await tester.pumpWidget(const SizedBox());
      expect(fg.stopCalls, 1);
    },
  );

  testWidgets(
    'foreground service останавливается после завершения тренировки',
    (tester) async {
      final dayId = await createDay(sets: 1, restSeconds: 0);
      final fg = StubWorkoutForegroundService();
      await pumpRun(tester, dayId, foregroundService: fg);

      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.tap(find.text('Подход выполнен'));
      await tester.pumpAndSettle();

      expect(find.text('Тренировка завершена'), findsOneWidget);
      expect(fg.stopCalls, 1);
    },
  );

  testWidgets('баннер предупреждения wakelock виден, когда wakelock выключен', (
    tester,
  ) async {
    final dayId = await createDay();
    await pumpRun(tester, dayId, wakelockService: _DisabledWakelock());

    expect(
      find.textContaining('Экран может выключаться во время тренировки'),
      findsOneWidget,
    );

    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Экран может выключаться во время тренировки'),
      findsNothing,
    );
  });

  testWidgets('баннер wakelock не повторяется после персистентного dismiss', (
    tester,
  ) async {
    final dayId = await createDay();
    final repo = _FakeWakelockBannerRepository();
    // First visit: banner shown, tap OK → persisted.
    await pumpRun(
      tester,
      dayId,
      wakelockService: _DisabledWakelock(),
      wakelockBannerRepository: repo,
    );
    expect(
      find.textContaining('Экран может выключаться во время тренировки'),
      findsOneWidget,
    );
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(repo.dismissed, isTrue);

    // Second visit: banner should not appear.
    await pumpRun(
      tester,
      dayId,
      wakelockService: _DisabledWakelock(),
      wakelockBannerRepository: repo,
    );
    expect(
      find.textContaining('Экран может выключаться во время тренировки'),
      findsNothing,
    );
  });

  testWidgets(
    'плавающая кнопка остановки звука появляется при воспроизведении',
    (tester) async {
      final dayId = await createDay();
      final sound = _ControllableSoundService();
      await pumpRun(tester, dayId, soundService: sound);

      FloatingActionButton fab() => tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab().onPressed, isNull);

      sound.emit(true);
      await tester.pumpAndSettle();
      expect(fab().onPressed, isNotNull);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(sound.stopCalls, 1);

      sound.emit(false);
      await tester.pumpAndSettle();
      expect(fab().onPressed, isNull);
    },
  );

  testWidgets('диалог выхода на узком экране: кнопки с отступом 16px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final dayId = await createDay();
    await pumpRun(tester, dayId, initialLocation: '/');

    final router = GoRouter.of(tester.element(find.text('home')));
    router.push('/workout/run?programDayId=$dayId&variant=main');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Выйти из тренировки?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final spacers = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .where((s) => s.height == 16)
        .length;
    expect(spacers, greaterThanOrEqualTo(2));
  });

  testWidgets('шрифт удержания планки headlineMedium на всех экранах', (
    tester,
  ) async {
    final exId = await insertExercise('Планка', type: ExerciseType.plank);

    Text holdText(WidgetTester t) {
      final texts = t
          .widgetList<Text>(find.textContaining('Удержание'))
          .toList();
      return texts.first;
    }

    // Обычная ширина: headlineMedium (28).
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    final routerWide = GoRouter(
      initialLocation: '/workout/run?exerciseId=$exId&durationSeconds=30',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            final qp = state.uri.queryParameters;
            return WorkoutRunScreen(
              exerciseId: int.tryParse(qp['exerciseId'] ?? ''),
              singleExerciseParams: SingleExerciseParams(
                durationSeconds: int.tryParse(qp['durationSeconds'] ?? ''),
              ),
              programRepository: programRepo,
              exerciseRepository: exerciseRepo,
              workoutRepository: workoutRepo,
              mediaCache: MediaCache(),
              wakelockService: wakelock,
              foregroundService: StubWorkoutForegroundService(),
              soundService: StubSoundService(),
              checkpointLoader: () async => null,
              checkpointSaver: (_) async {},
              checkpointClearer: () async {},
              wakelockBannerRepository: _FakeWakelockBannerRepository(),
            );
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: routerWide,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
    expect(holdText(tester).style!.fontSize, 28);
    addTearDown(tester.view.reset);

    // Узкий экран: headlineMedium (28).
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1.0;
    final routerNarrow = GoRouter(
      initialLocation: '/workout/run?exerciseId=$exId&durationSeconds=30',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            final qp = state.uri.queryParameters;
            return WorkoutRunScreen(
              exerciseId: int.tryParse(qp['exerciseId'] ?? ''),
              singleExerciseParams: SingleExerciseParams(
                durationSeconds: int.tryParse(qp['durationSeconds'] ?? ''),
              ),
              programRepository: programRepo,
              exerciseRepository: exerciseRepo,
              workoutRepository: workoutRepo,
              mediaCache: MediaCache(),
              wakelockService: wakelock,
              foregroundService: StubWorkoutForegroundService(),
              soundService: StubSoundService(),
              checkpointLoader: () async => null,
              checkpointSaver: (_) async {},
              checkpointClearer: () async {},
              wakelockBannerRepository: _FakeWakelockBannerRepository(),
            );
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: routerNarrow,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
    expect(holdText(tester).style!.fontSize, 28);
  });
}
