// ignore_for_file: type=lint
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_history_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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

  /// Реальное упражнение в БД: workoutSetResults.exerciseId — FK.
  Future<int> insertExercise(String name) => db
      .into(db.exercises)
      .insert(
        ExercisesCompanion.insert(
          name: name,
          type: ExerciseType.strength,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

  WorkoutSession session(DateTime performedDate) => WorkoutSession(
    programName: 'База',
    dayIndex: 0,
    variant: WorkoutVariant.main,
    performedDate: performedDate,
    startedAt: performedDate.add(const Duration(hours: 18)),
    endedAt: performedDate.add(const Duration(hours: 18, minutes: 40)),
  );

  WorkoutSetResult setResult({
    required int exerciseId,
    required DateTime completedAt,
    int setIndex = 1,
    int? reps = 8,
    double? weightKg = 20,
    String? side,
  }) => WorkoutSetResult(
    sessionId: 0,
    exerciseId: exerciseId,
    exerciseName: 'Приседания',
    exerciseType: ExerciseType.strength,
    setIndex: setIndex,
    reps: reps,
    weightKg: weightKg,
    side: side,
    completedAt: completedAt,
  );

  Future<void> pumpHistory(
    WidgetTester tester, {
    required int exerciseId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ExerciseHistoryScreen(
          exerciseId: exerciseId,
          exerciseName: 'Приседания',
          workoutRepository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает сессии от новых к старым с подходами', (
    tester,
  ) async {
    final exerciseId = await insertExercise('Приседания');
    final saved1 = await repo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(
        exerciseId: exerciseId,
        completedAt: DateTime(2026, 8, 10, 18, 5),
      ),
    ]);
    await repo.saveSession(session(DateTime(2026, 8, 14)), [
      setResult(
        exerciseId: exerciseId,
        completedAt: DateTime(2026, 8, 14, 18, 5),
        reps: 12,
      ),
      setResult(
        exerciseId: exerciseId,
        completedAt: DateTime(2026, 8, 14, 18, 8),
        reps: 10,
        setIndex: 2,
      ),
    ]);
    await pumpHistory(tester, exerciseId: exerciseId);

    expect(find.text('История упражнения'), findsOneWidget);
    expect(find.text('14 августа 2026'), findsOneWidget);
    expect(find.text('10 августа 2026'), findsOneWidget);
    expect(find.textContaining('12 ×'), findsOneWidget);
    expect(find.textContaining('2. 10 × 20 кг'), findsOneWidget);
    expect(find.textContaining('8 ×'), findsOneWidget);
    expect(saved1.session.id, isNotNull);
  });

  testWidgets('подходы по сторонам помечены «л»/«п»', (tester) async {
    final exerciseId = await insertExercise('Приседания');
    await repo.saveSession(session(DateTime(2026, 8, 14)), [
      setResult(
        exerciseId: exerciseId,
        completedAt: DateTime(2026, 8, 14, 18, 5),
        side: 'left',
        reps: 8,
      ),
      setResult(
        exerciseId: exerciseId,
        completedAt: DateTime(2026, 8, 14, 18, 8),
        side: 'right',
        reps: 9,
      ),
    ]);
    await pumpHistory(tester, exerciseId: exerciseId);

    expect(find.textContaining('1л.'), findsOneWidget);
    expect(find.textContaining('1п.'), findsOneWidget);
  });

  testWidgets('пустая история показывает empty state', (tester) async {
    await pumpHistory(tester, exerciseId: 999);

    expect(find.text('Это упражнение ещё не выполнялось'), findsOneWidget);
    expect(find.text('Приседания'), findsOneWidget);
  });
}
