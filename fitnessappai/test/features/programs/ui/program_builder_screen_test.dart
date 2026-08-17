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
import 'package:fitnessappai/features/programs/ui/program_day_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_exercise_params_screen.dart';
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

    await enterName(tester, 'Сплит');

    await tester.tap(find.text('День 1'));
    await tester.pumpAndSettle();
    expect(find.text('Наполнение дня'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune).at(0));
    await tester.pumpAndSettle();
    expect(find.text('Настройка дня'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пн').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.playlist_add).at(0));
    await tester.pumpAndSettle();
    expect(find.text('Наполнение дня'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Заполнить день 1'), findsOneWidget);

    final programId = (await repository.getPrograms()).single.program.id!;
    final days = await repository.getDays(programId);
    for (final day in days) {
      await repository.addExerciseToDay(day.id!, exercise.id!);
    }

    await tester.tap(find.text('Заполнить день 1'));
    await tester.pumpAndSettle();
    expect(find.text('Наполнение дня'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    expect(find.text('Программы'), findsOneWidget);

    final programs = await repository.getPrograms();
    expect(programs, hasLength(1));
    final created = programs.single.program;
    expect(created.name, 'Сплит');
    expect(created.daysCount, 3);
    final savedDays = await repository.getDays(created.id!);
    expect(savedDays[0].dayOfWeek, 1);
    expect(savedDays[0].dayIndex, 0);
    expect(savedDays[1].dayOfWeek, isNull);
  });

  testWidgets(
    'пустая программа: кнопка «Заполнить день 1», без названия не открывает наполнение',
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

      expect(find.text('Заполнить день 1'), findsOneWidget);
      expect(find.text('Сохранить'), findsNothing);

      await tester.tap(find.text('Заполнить день 1'));
      await tester.pumpAndSettle();

      expect(find.text('Введите название'), findsOneWidget);
      expect(find.text('Наполнение дня'), findsNothing);
      expect(await repository.getPrograms(), isEmpty);
    },
  );

  testWidgets('валидация: пустое название блокирует сохранение', (
    tester,
  ) async {
    await pumpBuilder(tester);

    await tester.tap(find.text('Заполнить день 1'));
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

    await tester.tap(find.byIcon(Icons.tune).at(1));
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

  testWidgets('редактирование активной программы не сбрасывает активность', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final created = await repository.create(program('Сплит', daysCount: 1), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final createdDays = await repository.getDays(created.id!);
    await repository.addExerciseToDay(createdDays.single.id!, exercise.id!);
    await repository.setActive(created.id!);
    expect((await repository.getActiveProgram())!.id, created.id);

    await pumpBuilder(tester, programId: created.id);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect((await repository.getActiveProgram())!.id, created.id);
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

      await tester.tap(find.byIcon(Icons.tune).at(0));
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

      await tester.tap(find.byIcon(Icons.tune).at(1));
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

  testWidgets(
    'незаполненный день: кнопка «Заполнить день N», после заполнения — «Сохранить»',
    (tester) async {
      final exercise = await createExercise(
        'Жим штанги',
        ExerciseType.strength,
      );
      final created = await repository.create(program('Сплит', daysCount: 2), [
        ProgramDay(programId: 0, dayIndex: 0),
        ProgramDay(programId: 0, dayIndex: 1),
      ]);
      final createdDays = await repository.getDays(created.id!);
      await repository.addExerciseToDay(createdDays[0].id!, exercise.id!);

      final router = GoRouter(
        initialLocation: '/programs/edit',
        routes: [
          GoRoute(
            path: '/programs/edit',
            builder: (context, state) => ProgramBuilderScreen(
              repository: repository,
              programId: created.id,
            ),
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

      expect(find.text('Заполнить день 2'), findsOneWidget);
      expect(find.text('Сохранить'), findsNothing);

      await tester.tap(find.text('Заполнить день 2'));
      await tester.pumpAndSettle();
      expect(find.text('Наполнение дня'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Заполнить день 2'), findsOneWidget);

      await repository.addExerciseToDay(createdDays[1].id!, exercise.id!);
      await tester.tap(find.text('Заполнить день 2'));
      await tester.pumpAndSettle();
      expect(find.text('Наполнение дня'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Заполнить день 2'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Сохранить'), findsOneWidget);
    },
  );

  testWidgets(
    'реордер дней не ломает статус заполненности: кнопка ведёт к пустому дню',
    (tester) async {
      final exercise = await createExercise(
        'Жим штанги',
        ExerciseType.strength,
      );
      final created = await repository.create(program('Сплит', daysCount: 3), [
        ProgramDay(programId: 0, dayIndex: 0),
        ProgramDay(programId: 0, dayIndex: 1),
        ProgramDay(programId: 0, dayIndex: 2),
      ]);
      final createdDays = await repository.getDays(created.id!);
      await repository.addExerciseToDay(createdDays[0].id!, exercise.id!);

      final router = GoRouter(
        initialLocation: '/programs/edit',
        routes: [
          GoRoute(
            path: '/programs/edit',
            builder: (context, state) => ProgramBuilderScreen(
              repository: repository,
              programId: created.id,
            ),
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

      // День 1 заполнен, следующие — нет.
      expect(find.text('Заполнить день 2'), findsOneWidget);

      // Переносим заполненный день 1 (позиция 0) в конец списка.
      await tester.timedDrag(
        find.byIcon(Icons.drag_indicator).at(0),
        const Offset(0, 220),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();

      // Заполненность следует за днём: на позиции 0 остался пустой день.
      expect(find.text('Заполнить день 1'), findsOneWidget);
      expect(find.text('Заполнить день 2'), findsNothing);
    },
  );

  testWidgets(
    'после возврата из наполнения дня ни одно поле конструктора не в фокусе',
    (tester) async {
      final created = await repository.create(program('Сплит', daysCount: 1), [
        ProgramDay(programId: 0, dayIndex: 0),
      ]);
      final router = GoRouter(
        initialLocation: '/programs/edit',
        routes: [
          GoRoute(
            path: '/programs/edit',
            builder: (context, state) => ProgramBuilderScreen(
              repository: repository,
              programId: created.id,
            ),
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

      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, isNotNull);

      await tester.tap(find.text('Заполнить день 1'));
      await tester.pumpAndSettle();
      expect(find.text('Наполнение дня'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      final focusedEditable = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>();
      expect(focusedEditable, isNull);
    },
  );

  testWidgets('ошибка валидации названия очищается при вводе', (tester) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final created = await repository.create(program('Название', daysCount: 1), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final createdDays = await repository.getDays(created.id!);
    await repository.addExerciseToDay(createdDays.single.id!, exercise.id!);

    await pumpBuilder(tester, programId: created.id);

    // Невалидное сохранение: ошибка названия видна.
    await enterName(tester, '');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Введите название'), findsOneWidget);

    // Ввод названия убирает ошибку без повторного нажатия кнопки.
    await enterName(tester, 'Сплит');
    await tester.pumpAndSettle();
    expect(find.text('Введите название'), findsNothing);
  });

  testWidgets(
    'заполненный день: кнопка ведёт к следующему незаполненному дню',
    (tester) async {
      await createExercise('Жим штанги', ExerciseType.strength);
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
          GoRoute(
            path: '/programs/:id/day/:dayIndex',
            builder: (context, state) => ProgramDayBuilderScreen(
              programId: int.parse(state.pathParameters['id']!),
              dayIndex: int.parse(state.pathParameters['dayIndex']!),
              repository: repository,
              exerciseRepository: exerciseRepository,
            ),
          ),
          GoRoute(
            path: '/program-day/:id/exercise-params',
            builder: (context, state) => ProgramDayExerciseParamsScreen(
              positionId: int.parse(state.pathParameters['id']!),
              repository: repository,
              exerciseRepository: exerciseRepository,
            ),
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
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      // Заполняем первый день через реальный флоу day-builder.
      await tester.tap(find.text('Заполнить день 1'));
      await tester.pumpAndSettle();
      expect(find.text('День 1'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Жим штанги'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Подходы'),
        '3',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Повторения'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Вес (кг)'),
        '20',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();

      // День сохранён в БД через параметры, но структурно программа неполная:
      // валидатор просит заполнить остальные дни. Пользователь выходит.
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();

      // В конструкторе кнопка ведёт к следующему незаполненному дню.
      expect(find.text('Заполнить день 2'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Сохранить'), findsNothing);
    },
  );
}
