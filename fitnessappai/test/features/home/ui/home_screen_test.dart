import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/home/ui/home_screen.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late Directory tempDir;

  /// Фиксированная «сегодня»-дата (понедельник) для детерминированных тестов.
  final DateTime fixedNow = DateTime(2026, 8, 10);

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db, clock: () => fixedNow);
    exerciseRepo = ExerciseRepository(db, MediaStore());
    workoutRepo = WorkoutRepository(db);
    tempDir = await Directory.systemTemp.createTemp('home_screen_test');
    locator.reset();
    locator.registerLazySingleton<MediaCache>(() => MediaCache());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            programRepository: programRepo,
            exerciseRepository: exerciseRepo,
            workoutRepository: workoutRepo,
            clock: () => fixedNow,
          ),
        ),
        GoRoute(
          path: '/programs',
          builder: (context, state) =>
              const Scaffold(body: Text('programs-route')),
        ),
        GoRoute(
          path: '/programs/:id/edit',
          builder: (context, state) =>
              const Scaffold(body: Text('program-edit-route')),
        ),
        GoRoute(
          path: '/history/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('history-route')),
        ),
        GoRoute(
          path: '/workout/prepare/:programDayId',
          builder: (context, state) => Scaffold(
            body: Text('prepare-${state.pathParameters['programDayId']}'),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: Text('settings-route')),
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

  Future<int> insertExercise(String name) async {
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

  Future<Program> createProgram({
    String name = 'Силовая',
    int? dayOfWeek = 1,
    String? imagePath,
  }) async {
    final program = await programRepo.create(
      Program(
        name: name,
        daysCount: 1,
        imagePath: imagePath,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: dayOfWeek)],
    );
    return program;
  }

  Future<String> writeValidImage(String fileName) async {
    const png = <int>[
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
    ];
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(Uint8List.fromList(png));
    return file.path;
  }

  testWidgets('изображение программы показывается на карточке', (tester) async {
    late String path;
    await tester.runAsync(() async {
      path = await writeValidImage('program.png');
    });
    final program = await createProgram(
      name: 'С изображением',
      imagePath: path,
    );
    await programRepo.setActive(program.id!);

    await pumpHome(tester);

    final card = find.ancestor(
      of: find.text('С изображением'),
      matching: find.byType(Card),
    );
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byType(Image)),
      findsWidgets,
    );
  });

  testWidgets('без изображения на карточке показывается заглушка', (
    tester,
  ) async {
    final program = await createProgram(name: 'Без изображения');
    await programRepo.setActive(program.id!);

    await pumpHome(tester);

    final card = find.ancestor(
      of: find.text('Без изображения'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.fitness_center)),
      findsOneWidget,
    );
  });

  Future<int> saveSession(String programName) async {
    final program = await createProgram(name: programName);
    final day = (await programRepo.getDays(program.id!)).single;
    final detail = await workoutRepo.saveSession(
      WorkoutSession(
        programName: programName,
        programDayId: day.id!,
        dayIndex: 0,
        performedDate: DateTime(2026, 8, 9),
        startedAt: DateTime(2026, 8, 9, 18, 0),
        endedAt: DateTime(2026, 8, 9, 18, 35),
      ),
      [
        WorkoutSetResult(
          sessionId: 0,
          exerciseName: 'Жим',
          exerciseType: ExerciseType.strength,
          setIndex: 1,
          reps: 10,
          completedAt: DateTime(2026, 8, 9, 18, 5),
        ),
      ],
    );
    return detail.session.id!;
  }

  testWidgets('без программ показывает пустое состояние', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Нет программ'), findsOneWidget);
    expect(find.text('К программам'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('переход к программам из пустого состояния', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.text('К программам'));
    await tester.pumpAndSettle();

    expect(find.text('programs-route'), findsOneWidget);
  });

  testWidgets('активная программа и ближайший день отображаются', (
    WidgetTester tester,
  ) async {
    final exId = await insertExercise('Жим штанги');
    final program = await createProgram(name: 'Силовая', dayOfWeek: 1);
    final day = (await programRepo.getDays(program.id!)).single;
    await programRepo.addExerciseToDay(day.id!, exId);
    await programRepo.setActive(program.id!);

    await pumpHome(tester);

    expect(find.text('Силовая'), findsOneWidget);
    expect(find.text('Жим штанги'), findsOneWidget);
    // Понедельник = день тренировки: показывается бейдж «Запланировано».
    expect(find.textContaining('Запланировано'), findsOneWidget);
  });

  testWidgets(
    'активная программа без привязки дня — показывает «не назначен»',
    (WidgetTester tester) async {
      final exId = await insertExercise('Жим штанги');
      await createProgram(name: 'Силовая', dayOfWeek: null);
      final program = (await programRepo.getPrograms()).single.program;
      final day = (await programRepo.getDays(program.id!)).single;
      await programRepo.addExerciseToDay(day.id!, exId);
      await programRepo.setActive(program.id!);

      await pumpHome(tester);

      expect(find.text('Силовая'), findsOneWidget);
      expect(find.text('Жим штанги'), findsOneWidget);
      expect(
        find.textContaining('Ближайший день: не назначен'),
        findsOneWidget,
      );
    },
  );

  testWidgets('карточка активной программы открывает редактирование', (
    WidgetTester tester,
  ) async {
    final program = await createProgram(name: 'Силовая', dayOfWeek: 1);
    await programRepo.setActive(program.id!);

    await pumpHome(tester);

    await tester.tap(find.text('Силовая'));
    await tester.pumpAndSettle();

    expect(find.text('program-edit-route'), findsOneWidget);
  });

  testWidgets('последние тренировки и переход к деталям', (
    WidgetTester tester,
  ) async {
    await saveSession('База');

    await pumpHome(tester);

    expect(find.text('Последние тренировки'), findsOneWidget);
    expect(find.text('База'), findsOneWidget);

    await tester.tap(find.text('База'));
    await tester.pumpAndSettle();

    expect(find.text('history-route'), findsOneWidget);
  });

  testWidgets('иконка play на карточке открывает подготовку тренировки', (
    WidgetTester tester,
  ) async {
    final program = await createProgram(name: 'Силовая', dayOfWeek: 1);
    await programRepo.setActive(program.id!);

    await pumpHome(tester);

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    final day = (await programRepo.getDays(program.id!)).single;
    expect(find.text('prepare-${day.id}'), findsOneWidget);
  });

  testWidgets('рядом с активной программой есть кнопка «К программам»', (
    WidgetTester tester,
  ) async {
    final program = await createProgram(name: 'Силовая', dayOfWeek: 1);
    await programRepo.setActive(program.id!);

    await pumpHome(tester);

    expect(find.text('Силовая'), findsOneWidget);
    // Кнопка «К программам» рядом с заголовком «Активная программа».
    expect(find.text('К программам'), findsWidgets);

    await tester.tap(find.text('К программам').first);
    await tester.pumpAndSettle();

    expect(find.text('programs-route'), findsOneWidget);
  });

  testWidgets('иконка настроек в AppBar ведёт на экран настроек', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('settings-route'), findsOneWidget);
  });

  testWidgets(
    'бейдж «Запланировано» на карточке когда сегодня день тренировки',
    (WidgetTester tester) async {
      final exId = await insertExercise('Жим штанги');
      final program = await createProgram(name: 'Сила', dayOfWeek: 1);
      final day = (await programRepo.getDays(program.id!)).single;
      await programRepo.addExerciseToDay(day.id!, exId);
      await programRepo.setActive(program.id!);

      // fixedNow = Aug 10 2026, понедельник = dayOfWeek 1.
      await pumpHome(tester);

      expect(find.text('Сила'), findsOneWidget);
      expect(find.text('Запланировано'), findsOneWidget);
    },
  );

  testWidgets('бейдж «Выполнено» на карточке когда тренировка завершена', (
    WidgetTester tester,
  ) async {
    final program = await createProgram(name: 'Сила', dayOfWeek: 1);
    final day = (await programRepo.getDays(program.id!)).single;
    await programRepo.setActive(program.id!);

    // Выполняем тренировку Aug 10 (сегодня).
    await workoutRepo.saveSession(
      WorkoutSession(
        programName: 'Сила',
        programDayId: day.id!,
        dayIndex: 0,
        performedDate: DateTime(2026, 8, 10),
        startedAt: DateTime(2026, 8, 10, 10),
        endedAt: DateTime(2026, 8, 10, 11),
      ),
      [
        WorkoutSetResult(
          sessionId: 0,
          exerciseName: 'Жим',
          exerciseType: ExerciseType.strength,
          setIndex: 1,
          reps: 10,
          completedAt: DateTime(2026, 8, 10, 10),
        ),
      ],
    );

    await pumpHome(tester);

    expect(find.text('Сила'), findsWidgets);
    expect(find.text('Выполнено'), findsOneWidget);
  });

  testWidgets('текст «Ближайший день» когда сегодня не день тренировки', (
    WidgetTester tester,
  ) async {
    // Программа привязана к среде (3), fixedNow = понедельник (1).
    final program = await createProgram(name: 'Кардио', dayOfWeek: 3);
    await programRepo.setActive(program.id!);

    await pumpHome(tester);

    expect(find.text('Кардио'), findsOneWidget);
    expect(find.textContaining('Ближайший день'), findsOneWidget);
  });
}
