import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/progress/ui/day_detail_screen.dart';
import 'package:fitnessappai/features/progress/ui/history_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late WorkoutRepository workoutRepo;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('day_detail_test');
    workoutRepo = WorkoutRepository(db);
    ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: () async => null,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  WorkoutSession session(
    DateTime performedDate, {
    String programName = 'База',
  }) => WorkoutSession(
    programName: programName,
    dayIndex: 0,
    performedDate: performedDate,
    startedAt: performedDate.add(const Duration(hours: 18)),
    endedAt: performedDate.add(const Duration(hours: 18, minutes: 40)),
  );

  WorkoutSetResult setResult({String name = 'Приседания'}) => WorkoutSetResult(
    sessionId: 0,
    exerciseId: null,
    exerciseName: name,
    exerciseType: ExerciseType.strength,
    setIndex: 1,
    reps: 8,
    weightKg: 20,
    completedAt: DateTime(2026, 8, 12, 12),
  );

  Future<void> pumpDayDetail(
    WidgetTester tester, {
    required DateTime start,
    required DateTime end,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: DayDetailScreen(
          start: start,
          end: end,
          workoutRepository: workoutRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает сессии дня с составом и длительностью', (
    tester,
  ) async {
    await workoutRepo.saveSession(session(DateTime(2026, 8, 10)), [
      setResult(name: 'Приседания'),
      setResult(name: 'Жим лёжа'),
      setResult(name: 'Жим лёжа'),
    ]);
    await workoutRepo.saveSession(
      session(DateTime(2026, 8, 11), programName: 'Кардио'),
      [setResult(name: 'Бег')],
    );

    await pumpDayDetail(
      tester,
      start: DateTime(2026, 8, 10),
      end: DateTime(2026, 8, 12),
    );

    expect(find.text('10 августа 2026 — 11 августа 2026'), findsOneWidget);
    expect(find.text('База'), findsOneWidget);
    expect(find.text('Кардио'), findsOneWidget);
    expect(find.text('2 упражнения · 40 мин'), findsOneWidget);
    expect(find.text('1 упражнение · 40 мин'), findsOneWidget);
  });

  testWidgets('одиночный день в заголовке и пустой день — сообщение', (
    tester,
  ) async {
    await pumpDayDetail(
      tester,
      start: DateTime(2026, 8, 10),
      end: DateTime(2026, 8, 11),
    );

    expect(find.text('10 августа 2026'), findsOneWidget);
    expect(find.text('Нет тренировок за этот день'), findsOneWidget);
  });

  testWidgets('тап по сессии открывает детали тренировки', (tester) async {
    final saved = await workoutRepo.saveSession(
      session(DateTime(2026, 8, 10)),
      [setResult(name: 'Приседания')],
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DayDetailScreen(
            start: DateTime(2026, 8, 10),
            end: DateTime(2026, 8, 11),
            workoutRepository: workoutRepo,
          ),
        ),
        GoRoute(
          path: '/history/:id',
          builder: (context, state) => HistoryDetailScreen(
            sessionId: int.parse(state.pathParameters['id']!),
            workoutRepository: workoutRepo,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('База'));
    await tester.pumpAndSettle();

    expect(find.text('Детали тренировки'), findsOneWidget);
    expect(find.text('1. 8 повт × 20 кг'), findsOneWidget);
    expect(saved.session.id, isNotNull);
  });
}
