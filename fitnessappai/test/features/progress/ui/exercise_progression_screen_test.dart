import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/progress/ui/exercise_progression_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late StatsAggregator aggregator;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('progression_screen_test');
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

  WorkoutSetResult setResult({
    required int exerciseId,
    int? reps = 8,
    double? weightKg = 20,
  }) => WorkoutSetResult(
    sessionId: 0,
    exerciseId: exerciseId,
    exerciseName: 'Приседания',
    exerciseType: ExerciseType.strength,
    setIndex: 1,
    reps: reps,
    weightKg: weightKg,
    completedAt: DateTime(2026, 8, 12, 12),
  );

  Future<Exercise> createExercise(String name) {
    return exerciseRepo.create(
      Exercise(
        name: name,
        type: ExerciseType.strength,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      const [],
    );
  }

  Future<void> pumpProgression(WidgetTester tester, int exerciseId) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ExerciseProgressionScreen(
          exerciseId: exerciseId,
          statsAggregator: aggregator,
          exerciseRepository: exerciseRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает график, максимум и список дат', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final exercise = await createExercise('Приседания');
    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(exerciseId: exercise.id!, reps: 8, weightKg: 40),
      setResult(exerciseId: exercise.id!, reps: 6, weightKg: 50),
    ]);
    await workoutRepo.saveSession(session(DateTime(2026, 8, 12)), [
      setResult(exerciseId: exercise.id!, reps: 5, weightKg: 45),
    ]);

    await pumpProgression(tester, exercise.id!);

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Максимум: 50 кг'), findsOneWidget);
    expect(find.text('10 августа 2026'), findsOneWidget);
    expect(find.text('12 августа 2026'), findsOneWidget);
  });

  testWidgets('без тренировок показывает сообщение', (tester) async {
    final exercise = await createExercise('Приседания');
    await pumpProgression(tester, exercise.id!);

    expect(find.text('Ещё нет тренировок с этим упражнением'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('неизвестное упражнение показывает сообщение', (tester) async {
    await pumpProgression(tester, 999);

    expect(find.text('Упражнение не найдено'), findsOneWidget);
  });
}
