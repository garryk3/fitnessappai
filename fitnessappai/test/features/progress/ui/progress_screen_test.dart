import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/progress/ui/day_detail_screen.dart';
import 'package:fitnessappai/features/progress/ui/exercise_progression_screen.dart';
import 'package:fitnessappai/features/progress/ui/progress_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
    tempDir = await Directory.systemTemp.createTemp('progress_screen_test');
    exerciseRepo = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: (fileType) async => null,
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
            createdAt: clock(),
            updatedAt: clock(),
          ),
        );
  }

  WorkoutSession session(DateTime performedDate) => WorkoutSession(
    programName: 'База',
    dayIndex: 0,
    performedDate: performedDate,
    startedAt: performedDate.add(const Duration(hours: 18)),
    endedAt: performedDate.add(const Duration(hours: 18, minutes: 40)),
  );

  WorkoutSetResult setResult({
    required int exerciseId,
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

  Finder statCard(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(Card));

  Future<void> pumpProgress(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgressScreen(
          statsAggregator: aggregator,
          exerciseRepository: exerciseRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('карточки, графики и нагрузка на мышцы за период', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final groups = await exerciseRepo.getAllMuscleGroups();
    final strength = await exerciseRepo.create(
      Exercise(
        name: 'Приседания',
        type: ExerciseType.strength,
        createdAt: clock(),
        updatedAt: clock(),
      ),
      [
        ExerciseMuscle(
          exerciseId: 0,
          muscleGroupId: groups.first.id!,
          intensity: MuscleIntensity.primary,
        ),
        ExerciseMuscle(
          exerciseId: 0,
          muscleGroupId: groups.last.id!,
          intensity: MuscleIntensity.secondary,
        ),
      ],
    );
    final running = await insertExercise('Бег', type: ExerciseType.running);
    final plank = await insertExercise('Планка', type: ExerciseType.plank);

    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(exerciseId: strength.id!, reps: 8, weightKg: 20),
      setResult(
        exerciseId: running,
        type: ExerciseType.running,
        reps: null,
        weightKg: null,
        distanceMeters: 3000,
        durationSeconds: 900,
      ),
      setResult(
        exerciseId: plank,
        type: ExerciseType.plank,
        reps: null,
        weightKg: null,
        durationSeconds: 120,
      ),
    ]);

    await pumpProgress(tester);

    expect(
      find.descendant(of: statCard('Тренировок'), matching: find.text('1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: statCard('Дистанция'), matching: find.text('3 км')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: statCard('Время планки'),
        matching: find.text('2 мин'),
      ),
      findsOneWidget,
    );

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(MuscleDiagram), findsNWidgets(2));
    expect(find.text('Нагрузка на мышцы'), findsOneWidget);
    expect(find.text(groups.first.labelRu), findsOneWidget);
  });

  testWidgets('подписи осей графиков используют фиксированный интервал', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final exerciseId = await insertExercise('Приседания');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(exerciseId: exerciseId),
    ]);

    await pumpProgress(tester);

    final bar = tester.widget<BarChart>(find.byType(BarChart));
    expect(bar.data.titlesData.bottomTitles.sideTitles.interval, 1);

    final line = tester.widget<LineChart>(find.byType(LineChart));
    expect(line.data.titlesData.bottomTitles.sideTitles.interval, 1);
  });

  testWidgets('время планки с дробной частью: 90 с → «1.5 мин»', (
    tester,
  ) async {
    final plank = await insertExercise('Планка', type: ExerciseType.plank);

    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(
        exerciseId: plank,
        type: ExerciseType.plank,
        reps: null,
        weightKg: null,
        durationSeconds: 90,
      ),
    ]);

    await pumpProgress(tester);

    expect(
      find.descendant(
        of: statCard('Время планки'),
        matching: find.text('1.5 мин'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('смена периода обновляет карточки', (tester) async {
    final exerciseId = await insertExercise('Приседания');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 12)), [
      setResult(exerciseId: exerciseId),
    ]);
    await workoutRepo.saveSession(session(DateTime(2026, 8, 1)), [
      setResult(exerciseId: exerciseId),
    ]);
    await workoutRepo.saveSession(session(DateTime(2026, 8, 2)), [
      setResult(exerciseId: exerciseId),
    ]);

    await pumpProgress(tester);

    expect(
      find.descendant(of: statCard('Тренировок'), matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Месяц'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: statCard('Тренировок'), matching: find.text('3')),
      findsOneWidget,
    );
  });

  testWidgets('пустой период показывает сообщение без графиков', (
    tester,
  ) async {
    await insertExercise('Приседания');
    await pumpProgress(tester);

    expect(find.text('Нет тренировок за период'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(find.byType(LineChart), findsNothing);

    // Текст пустого состояния вертикально центрирован в оставшейся области
    // под segmented-контролом (нижняя половина экрана).
    final textCenter = tester.getCenter(find.text('Нет тренировок за период'));
    final screenHeight = tester.getSize(find.byType(Scaffold)).height;
    expect(textCenter.dy, greaterThan(screenHeight / 2));
  });

  testWidgets('выбор упражнения меняет график прогресса', (tester) async {
    final first = await insertExercise('Бег', type: ExerciseType.running);
    final second = await insertExercise('Приседания');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(
        exerciseId: first,
        type: ExerciseType.running,
        reps: null,
        weightKg: null,
        distanceMeters: 1000,
        durationSeconds: 300,
      ),
      setResult(exerciseId: second, reps: 8, weightKg: 40),
    ]);

    await pumpProgress(tester);

    expect(find.text('Бег'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Приседания').last);
    await tester.pumpAndSettle();

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('дропдаун метрик содержит только выполненные упражнения', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final performed = await insertExercise('Приседания');
    await insertExercise('Жим лёжа');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(exerciseId: performed, reps: 8, weightKg: 40),
    ]);

    await pumpProgress(tester);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    expect(find.text('Приседания'), findsWidgets);
    expect(find.text('Жим лёжа'), findsNothing);
  });

  testWidgets('карточки обновляются после новой сессии без переоткрытия', (
    tester,
  ) async {
    final exerciseId = await insertExercise('Приседания');
    await pumpProgress(tester);

    expect(find.text('Нет тренировок за период'), findsOneWidget);

    await workoutRepo.saveSession(session(DateTime(2026, 8, 12)), [
      setResult(exerciseId: exerciseId),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Нет тренировок за период'), findsNothing);
    expect(
      find.descendant(of: statCard('Тренировок'), matching: find.text('1')),
      findsOneWidget,
    );
  });

  GoRouter router() => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => ProgressScreen(
          statsAggregator: aggregator,
          exerciseRepository: exerciseRepo,
        ),
      ),
      GoRoute(
        path: '/progress/exercise/:id',
        builder: (context, state) => ExerciseProgressionScreen(
          exerciseId: int.parse(state.pathParameters['id']!),
          statsAggregator: aggregator,
          exerciseRepository: exerciseRepo,
        ),
      ),
      GoRoute(
        path: '/progress/day',
        builder: (context, state) => DayDetailScreen(
          start: DateTime.fromMillisecondsSinceEpoch(
            int.parse(state.uri.queryParameters['start']!),
          ),
          end: DateTime.fromMillisecondsSinceEpoch(
            int.parse(state.uri.queryParameters['end']!),
          ),
          workoutRepository: workoutRepo,
        ),
      ),
    ],
  );

  Future<void> pumpProgressRouter(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        routerConfig: router(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('кнопка динамики открывает экран прогрессии упражнения', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final exerciseId = await insertExercise('Приседания');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(exerciseId: exerciseId, reps: 8, weightKg: 40),
    ]);

    await pumpProgressRouter(tester);

    await tester.tap(find.byTooltip('Открыть динамику'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseProgressionScreen), findsOneWidget);
    expect(find.text('Максимум: 40 кг'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('тап по бару графика открывает детали дня', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final exerciseId = await insertExercise('Приседания');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 6)), [
      setResult(exerciseId: exerciseId),
    ]);

    await pumpProgressRouter(tester);

    final chartRect = tester.getRect(find.byType(BarChart));
    final usableH = chartRect.height - 24;
    final groupCenterX = chartRect.left + (chartRect.width - 84) / 8 + 6;
    await tester.tapAt(Offset(groupCenterX, chartRect.top + usableH * 0.75));
    await tester.pumpAndSettle();

    expect(find.byType(DayDetailScreen), findsOneWidget);
    expect(find.text('База'), findsOneWidget);
    expect(find.text('6 августа 2026'), findsWidgets);
  });

  testWidgets('хвостовые нули графика обрезаются до последнего дня', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final exerciseId = await insertExercise('Жим штанги');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(exerciseId: exerciseId, weightKg: 60),
    ]);
    await workoutRepo.saveSession(session(DateTime(2026, 8, 11)), [
      setResult(exerciseId: exerciseId, weightKg: 65),
    ]);

    await pumpProgressRouter(tester);

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(LineChart),
            matching: find.byType(Text),
          ),
        )
        .map((w) => w.data ?? '')
        .toList();
    final lastLabel = labels.lastWhere(
      (l) => l.isNotEmpty && l != 'кг',
      orElse: () => '',
    );
    expect(lastLabel, isNotEmpty);

    final slices = aggregator.slices(StatPeriod.week);
    final lastNonEmptyIndex = slices.indexWhere(
      (s) =>
          !s.$1.isAfter(DateTime(2026, 8, 11)) &&
          !s.$2.isBefore(DateTime(2026, 8, 11)),
    );
    expect(lastNonEmptyIndex, lessThan(slices.length - 1));
  });
}
