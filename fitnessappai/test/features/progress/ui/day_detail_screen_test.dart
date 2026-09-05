import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/progress/ui/day_detail_screen.dart';
import 'package:fitnessappai/features/progress/ui/history_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

// 1×1 PNG (валидные байты для декодирования в тестах).
final Uint8List _validPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0xDA,
  0x63,
  0xFC,
  0xCF,
  0xC0,
  0x50,
  0x0F,
  0x00,
  0x04,
  0x85,
  0x01,
  0x80,
  0x84,
  0xA9,
  0x8C,
  0x21,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late WorkoutRepository workoutRepo;
  late ProgramRepository programRepo;
  late ExerciseRepository exerciseRepo;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('day_detail_test');
    workoutRepo = WorkoutRepository(db);
    programRepo = ProgramRepository(db);
    exerciseRepo = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: (fileType) async => null,
      ),
    );
    locator.reset();
    locator.registerLazySingleton<MediaCache>(() => MediaCache());
    locator.registerLazySingleton<ProgramRepository>(() => programRepo);
    locator.registerLazySingleton<ExerciseRepository>(() => exerciseRepo);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  WorkoutSession session(
    DateTime performedDate, {
    String programName = 'База',
    int? programId,
    int? programDayId,
  }) => WorkoutSession(
    programName: programName,
    programId: programId,
    programDayId: programDayId,
    dayIndex: 0,
    performedDate: performedDate,
    startedAt: performedDate.add(const Duration(hours: 18)),
    endedAt: performedDate.add(const Duration(hours: 18, minutes: 40)),
  );

  WorkoutSetResult setResult({String name = 'Приседания', int? exerciseId}) =>
      WorkoutSetResult(
        sessionId: 0,
        exerciseId: exerciseId,
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

  testWidgets('изображение программы показывается на карточке сессии', (
    tester,
  ) async {
    late String imgPath;
    await tester.runAsync(() async {
      final file = File('${tempDir.path}/program.png');
      await file.writeAsBytes(_validPng);
      imgPath = file.path;
    });
    final program = await programRepo.create(
      Program(
        name: 'База',
        daysCount: 1,
        imagePath: imgPath,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0)],
    );
    final day = (await programRepo.getDays(program.id!)).single;
    await workoutRepo.saveSession(
      session(
        DateTime(2026, 8, 10),
        programId: program.id,
        programDayId: day.id,
      ),
      [setResult(name: 'Приседания')],
    );

    await pumpDayDetail(
      tester,
      start: DateTime(2026, 8, 10),
      end: DateTime(2026, 8, 11),
    );

    final card = find.ancestor(
      of: find.text('База'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: card, matching: find.byType(Image)),
      findsWidgets,
    );
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

  testWidgets('иконка упражнения показывается в деталях истории', (
    tester,
  ) async {
    late String thumbPath;
    await tester.runAsync(() async {
      final thumb = File('${tempDir.path}/thumb.png');
      await thumb.writeAsBytes(_validPng, flush: true);
      thumbPath = thumb.absolute.path;
    });
    final exercise = await exerciseRepo.create(
      Exercise(
        name: 'Приседания',
        type: ExerciseType.strength,
        thumbnailPath: thumbPath,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
    );
    final saved = await workoutRepo.saveSession(
      session(DateTime(2026, 8, 10)),
      [setResult(exerciseId: exercise.id)],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: HistoryDetailScreen(
          sessionId: saved.session.id!,
          workoutRepository: workoutRepo,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
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
