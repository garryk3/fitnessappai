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
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_builder_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository repository;
  late ExerciseRepository exerciseRepository;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repository = ProgramRepository(db);
    exerciseRepository = ExerciseRepository(db, MediaStore());
    locator.reset();
    locator.registerLazySingleton<WorkoutReminderRepository>(
      () => WorkoutReminderRepository(db),
    );
    locator.registerLazySingleton<ReminderService>(
      () =>
          ReminderService(repository: locator.get<WorkoutReminderRepository>()),
    );
    addTearDown(() => db.close());
  });

  Future<Exercise> createExercise(String name, ExerciseType type) {
    return exerciseRepository.create(
      Exercise(
        name: name,
        type: type,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
    );
  }

  Future<void> pumpBuilder(WidgetTester tester, {int? programId}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramBuilderScreen(
          repository: repository,
          programId: programId,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название'),
      name,
    );
  }

  Program program(String name, {int daysCount = 1}) {
    return Program(
      name: name,
      daysCount: daysCount,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  testWidgets('создание программы: выбор дней и день недели', (tester) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final router = GoRouter(
      initialLocation: '/programs/new',
      routes: [
        GoRoute(
          path: '/programs/new',
          builder: (context, state) =>
              ProgramBuilderScreen(repository: repository),
        ),
        GoRoute(
          path: '/programs/:id/day/:dayIndex',
          builder: (context, state) =>
              Scaffold(appBar: AppBar(title: const Text('Наполнение дня'))),
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

    expect(find.text('День 1'), findsOneWidget);
    expect(find.text('Без привязки'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    expect(find.text('День 1'), findsOneWidget);
    expect(find.text('День 2'), findsOneWidget);
    expect(find.text('День 3'), findsOneWidget);

    await tester.tap(find.text('День 1'));
    await tester.pumpAndSettle();
    expect(find.text('Настройка дня'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пн').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
    await tester.pumpAndSettle();

    await enterName(tester, 'Сплит');

    await tester.tap(find.byIcon(Icons.playlist_add).at(0));
    await tester.pumpAndSettle();
    expect(find.text('Наполнение дня'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    final programId = (await repository.getPrograms()).single.program.id!;
    final day = (await repository.getDays(programId)).first;
    await repository.addExerciseToDay(day.id!, exercise.id!);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    final programs = await repository.getPrograms();
    expect(programs, hasLength(1));
    final created = programs.single.program;
    expect(created.name, 'Сплит');
    expect(created.daysCount, 3);
    final days = await repository.getDays(created.id!);
    expect(days[0].dayOfWeek, 1);
    expect(days[0].dayIndex, 0);
    expect(days[1].dayOfWeek, isNull);
  });

  testWidgets(
    'пустая программа: диалог с ошибками, «Продолжить»/«Выйти» не сохраняют',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/home/programs/new',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Программы'))),
            routes: [
              GoRoute(
                path: 'programs/new',
                builder: (context, state) =>
                    ProgramBuilderScreen(repository: repository),
              ),
            ],
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

      await enterName(tester, 'Сплит');

      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('Недостаточно данных для сохранения'), findsOneWidget);
      expect(
        find.text('У дня 1 должно быть хотя бы одно основное упражнение'),
        findsOneWidget,
      );
      expect(find.text('Продолжить редактирование'), findsOneWidget);
      expect(find.text('Выйти'), findsOneWidget);
      expect(await repository.getPrograms(), isEmpty);

      await tester.tap(find.text('Продолжить редактирование'));
      await tester.pumpAndSettle();
      expect(find.text('Недостаточно данных для сохранения'), findsNothing);
      expect(find.text('День 1'), findsOneWidget);
      expect(await repository.getPrograms(), isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      expect(find.text('Программы'), findsOneWidget);
      expect(await repository.getPrograms(), isEmpty);
    },
  );

  testWidgets('валидация: пустое название блокирует сохранение', (
    tester,
  ) async {
    await pumpBuilder(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    expect(find.text('Введите название'), findsOneWidget);
    expect(await repository.getPrograms(), isEmpty);
  });

  testWidgets('редактирование: загружает и сохраняет изменения', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final created = await repository.create(program('Сплит', daysCount: 2), [
      ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 2),
      ProgramDay(programId: 0, dayIndex: 1, dayOfWeek: 4),
    ]);
    final createdDays = await repository.getDays(created.id!);
    await repository.addExerciseToDay(createdDays[0].id!, exercise.id!);
    await repository.addExerciseToDay(createdDays[1].id!, exercise.id!);

    await pumpBuilder(tester, programId: created.id);

    expect(find.text('День 1'), findsOneWidget);
    expect(find.text('День 2'), findsOneWidget);
    expect(find.text('Вт'), findsOneWidget);
    expect(find.text('Чт'), findsOneWidget);

    await tester.tap(find.text('День 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пт').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
    await tester.pumpAndSettle();

    await enterName(tester, 'Сплит 2');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    final updated = await repository.getById(created.id!);
    expect(updated!.name, 'Сплит 2');
    final days = await repository.getDays(created.id!);
    expect(days[1].dayOfWeek, 5);
  });

  testWidgets(
    'наполнение дней не создаёт дубликат программы и сохраняет дни недели',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/programs/new',
        routes: [
          GoRoute(
            path: '/programs/new',
            builder: (context, state) =>
                ProgramBuilderScreen(repository: repository),
          ),
          GoRoute(
            path: '/programs/:id/day/:dayIndex',
            builder: (context, state) =>
                Scaffold(appBar: AppBar(title: const Text('Наполнение дня'))),
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

      await enterName(tester, 'Сплит');
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('День 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Пн').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.playlist_add).at(0));
      await tester.pumpAndSettle();
      expect(find.text('Наполнение дня'), findsOneWidget);

      final afterFirst = await repository.getPrograms();
      expect(afterFirst, hasLength(1));
      final programId = afterFirst.single.program.id!;

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('День 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ср').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.playlist_add).at(1));
      await tester.pumpAndSettle();

      final programs = await repository.getPrograms();
      expect(programs, hasLength(1));
      expect(programs.single.program.id, programId);

      final days = await repository.getDays(programId);
      expect(days[0].dayOfWeek, 1);
      expect(days[1].dayOfWeek, 3);
    },
  );
}
