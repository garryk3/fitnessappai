import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
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
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_exercise_params_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

// 1×1 PNG (валидные байты для декодирования в тестах изображений).
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
  late ProgramRepository repository;
  late ExerciseRepository exerciseRepository;
  late MediaStore mediaStore;
  late MediaCache mediaCache;
  late Directory tempDir;
  XFile? lastPicked;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    repository = ProgramRepository(db);
    tempDir = await Directory.systemTemp.createTemp('program_builder_test');
    mediaStore = MediaStore(
      directoryProvider: () async => tempDir,
      assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
      filePicker: (fileType) async => lastPicked,
    );
    mediaCache = MediaCache();
    exerciseRepository = ExerciseRepository(db, MediaStore());
    locator.reset();
    locator.registerLazySingleton<WorkoutReminderRepository>(
      () => WorkoutReminderRepository(db),
    );
    locator.registerLazySingleton<ReminderService>(
      () =>
          ReminderService(repository: locator.get<WorkoutReminderRepository>()),
    );
    locator.registerLazySingleton<MediaStore>(() => mediaStore);
    locator.registerLazySingleton<MediaCache>(() => mediaCache);
    addTearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });
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

  Future<void> pumpBuilder(
    WidgetTester tester, {
    int? programId,
    MediaFilePicker? picker,
    MediaStore? store,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramBuilderScreen(
          repository: repository,
          exerciseRepository: exerciseRepository,
          programId: programId,
          mediaStore: store ?? mediaStore,
          mediaCache: mediaCache,
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
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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

    await tester.ensureVisible(find.text('3'));
    await tester.tap(find.text('3').last);
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

    await tester.ensureVisible(find.byIcon(Icons.tune).at(0));
    await tester.tap(find.byIcon(Icons.tune).at(0));
    await tester.pumpAndSettle();
    expect(find.text('Настройка дня'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пн').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('День 1').last);
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
    await tester.pump(const Duration(milliseconds: 500));
    // Новая программа — попап «Сделать активной?».
    await tester.tap(find.text('Отмена'));
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
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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

  testWidgets('разминка на экране программы сохраняется для всех дней', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final created = await repository.create(program('Сплит', daysCount: 1), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final createdDays = await repository.getDays(created.id!);
    await repository.addExerciseToDay(createdDays.single.id!, exercise.id!);

    await pumpBuilder(tester, programId: created.id);

    // Поле разминки теперь на основном экране, а не в модалке.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Разминка, мин'),
      '5',
    );
    await tester.pumpAndSettle();

    final warmupText = find.textContaining('разминка 5 мин');
    if (warmupText.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        warmupText,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }
    expect(warmupText, findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    final savedDay = (await repository.getDays(created.id!)).single;
    expect(savedDay.warmupMinutes, 5);
  });

  testWidgets('отдых между упражнениями сохраняется для программы', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final created = await repository.create(program('Сплит', daysCount: 1), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final createdDays = await repository.getDays(created.id!);
    await repository.addExerciseToDay(createdDays.single.id!, exercise.id!);

    await pumpBuilder(tester, programId: created.id);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Отдых между упражнениями, сек'),
      '90',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    final saved = (await repository.getById(created.id!))!;
    expect(saved.exerciseRestSeconds, 90);
  });

  testWidgets(
    'наполнение дней не создаёт дубликат программы и сохраняет дни недели',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      final segment2 = find.descendant(
        of: find.byType(SegmentedButton<int>),
        matching: find.text('2'),
      );
      await tester.ensureVisible(segment2);
      await tester.tap(segment2);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.tune).at(0));
      await tester.tap(find.byIcon(Icons.tune).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Пн').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('День 1').last);
      await tester.tap(find.text('День 1').last);
      await tester.pumpAndSettle();
      expect(find.text('Наполнение дня'), findsOneWidget);

      final afterFirst = await repository.getPrograms();
      expect(afterFirst, hasLength(1));
      final programId = afterFirst.single.program.id!;

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.tune).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ср').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('День 2').last);
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
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
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
      await tester.ensureVisible(find.byIcon(Icons.drag_indicator).at(0));
      await tester.pumpAndSettle();
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
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
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

      // День сохранён в БД через параметры; экран дня закрывается и
      // возвращает в конструктор, где кнопка ведёт к следующему незаполненному
      // дню (валидация всей программы выполняется только при её сохранении).
      expect(find.text('Заполнить день 2'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Сохранить'), findsNothing);
    },
  );

  testWidgets('при сохранении новой программы показывается попап активации', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final created = await repository.create(program('Новая'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final days = await repository.getDays(created.id!);
    await repository.addExerciseToDay(days.single.id!, exercise.id!);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramBuilderScreen(
          repository: repository,
          exerciseRepository: exerciseRepository,
          programId: created.id,
          forceInitiallyNew: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await enterName(tester, 'Новая');

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Сделать программу активной?'), findsOneWidget);
    expect(find.text('Сделать активной'), findsOneWidget);
  });

  testWidgets('выбор «Сделать активной» в попапе активирует программу', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final created = await repository.create(program('Новая'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final days = await repository.getDays(created.id!);
    await repository.addExerciseToDay(days.single.id!, exercise.id!);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramBuilderScreen(
          repository: repository,
          exerciseRepository: exerciseRepository,
          programId: created.id,
          forceInitiallyNew: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await enterName(tester, 'Новая');

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('Сделать активной'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final programs = await repository.getPrograms();
    expect(programs, hasLength(1));
    expect(programs.first.program.isActive, isTrue);
  });

  testWidgets(
    'копирование дня дублирует упражнения и увеличивает количество дней',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final exercise = await createExercise(
        'Жим штанги',
        ExerciseType.strength,
      );
      final created = await repository.create(program('Новая'), [
        ProgramDay(programId: 0, dayIndex: 0),
      ]);
      final days = await repository.getDays(created.id!);
      await repository.addExerciseToDay(days.single.id!, exercise.id!);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: ProgramBuilderScreen(
            repository: repository,
            programId: created.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Иконка копирования видна при 1 дне.
      expect(find.byIcon(Icons.content_copy), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.content_copy));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.content_copy));
      await tester.pumpAndSettle();

      // Стало 2 дня.
      expect(find.text('День 2'), findsOneWidget);
      final programs = await repository.getPrograms();
      expect(programs.single.program.daysCount, 2);
      final allDays = await repository.getDays(created.id!);
      expect(allDays, hasLength(2));
    },
  );

  testWidgets('при 7 днях иконка копирования скрыта', (tester) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final dayList = [
      for (var i = 0; i < 7; i++) ProgramDay(programId: 0, dayIndex: i),
    ];
    final created = await repository.create(
      program('Семёрка', daysCount: 7),
      dayList,
    );
    final days = await repository.getDays(created.id!);
    for (final day in days) {
      await repository.addExerciseToDay(day.id!, exercise.id!);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramBuilderScreen(
          repository: repository,
          programId: created.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.content_copy), findsNothing);
  });

  testWidgets(
    'новая пустая программа удаляется при выходе без заполнения дней',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
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

      await enterName(tester, 'Пустая');
      expect(await repository.getPrograms(), isEmpty);

      await tester.ensureVisible(find.text('День 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('День 1'));
      await tester.pumpAndSettle();
      expect(find.text('Наполнение дня'), findsOneWidget);
      // Скаффолд уже персистится при открытии дня.
      expect(await repository.getPrograms(), hasLength(1));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Размонтируем конструктор — программа без единого упражнения удаляется.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(await repository.getPrograms(), isEmpty);
    },
  );

  testWidgets('выход из редактора показывает диалог подтверждения', (
    tester,
  ) async {
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

    await enterName(tester, 'Черновик');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Выйти из редактора?'), findsOneWidget);
    expect(find.text('Изменения не сохранятся. Выйти?'), findsOneWidget);

    // Отмена оставляет на экране редактора.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Выйти из редактора?'), findsNothing);
    expect(find.text('Черновик'), findsOneWidget);

    // Подтверждение выхода возвращает на список программ.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.text('Программы'), findsOneWidget);
  });

  testWidgets('выход без изменений не показывает диалог', (tester) async {
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

    // Ничего не меняем — выходим сразу.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Выйти из редактора?'), findsNothing);
    expect(find.text('Программы'), findsOneWidget);
  });

  testWidgets('редактирование без изменений не показывает диалог', (
    tester,
  ) async {
    final created = await repository.create(program('Существующая'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final router = GoRouter(
      initialLocation: '/home/programs/edit',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Программы'))),
          routes: [
            GoRoute(
              path: 'programs/edit',
              builder: (context, state) => ProgramBuilderScreen(
                repository: repository,
                programId: created.id,
              ),
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

    // Ничего не меняем — выходим сразу, диалог не показывается.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Выйти из редактора?'), findsNothing);
    expect(find.text('Программы'), findsOneWidget);
  });

  testWidgets('режим удаления дней: кнопка в AppBar переключает режим', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final created = await repository.create(program('Сплит', daysCount: 3), [
      ProgramDay(programId: 0, dayIndex: 0),
      ProgramDay(programId: 0, dayIndex: 1),
      ProgramDay(programId: 0, dayIndex: 2),
    ]);

    await pumpBuilder(tester, programId: created.id);

    // В обычном режиме кнопки удаления нет — она появляется только в AppBar.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Входим в режим удаления.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Появляются чекбоксы вместо drag-индикаторов.
    expect(find.byType(Checkbox), findsNWidgets(3));

    // Кнопка «Удалить выбранное» внизу заблокирована (ничего не выбрано).
    expect(find.text('Удалить выбранное'), findsOneWidget);

    // Выбираем два дня.
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();

    // Удаляем.
    await tester.tap(find.text('Удалить выбранное'));
    await tester.pumpAndSettle();

    // Остался 1 день.
    expect(find.textContaining('День 1'), findsOneWidget);
    expect(find.textContaining('День 2'), findsNothing);
    expect(find.textContaining('День 3'), findsNothing);
  });

  testWidgets('режим удаления дней: нельзя удалить последний день', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final created = await repository.create(program('Однодневка'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);

    await pumpBuilder(tester, programId: created.id);

    // Кнопка удаления в AppBar не показывается, когда дней 1.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('режим удаления дней: отмена выходит из режима', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final created = await repository.create(program('Сплит', daysCount: 3), [
      ProgramDay(programId: 0, dayIndex: 0),
      ProgramDay(programId: 0, dayIndex: 1),
      ProgramDay(programId: 0, dayIndex: 2),
    ]);

    await pumpBuilder(tester, programId: created.id);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNWidgets(3));

    // Нажимаем крестик (отмена).
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Чекбоксов больше нет — вышли из режима.
    expect(find.byType(Checkbox), findsNothing);
    // Три дня на месте.
    expect(find.textContaining('День 1'), findsOneWidget);
    expect(find.textContaining('День 2'), findsOneWidget);
    expect(find.textContaining('День 3'), findsOneWidget);
  });

  testWidgets('выбор изображения программы сохраняет imagePath', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    lastPicked = XFile('${tempDir.path}/program.webp');
    await tester.runAsync(
      () => File('${tempDir.path}/program.webp').writeAsBytes(_validPng),
    );

    // Программа с заполненным днём, чтобы кнопка «Сохранить» была доступна.
    final exercise = await createExercise('Жим', ExerciseType.strength);
    final created = await repository.create(program('С изображением'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final day = (await repository.getDays(created.id!)).first;
    await repository.addExerciseToDay(day.id!, exercise.id!);

    await pumpBuilder(tester, programId: created.id);

    // Секция изображения отображается, картинки ещё нет.
    expect(find.text('Изображение программы'), findsOneWidget);
    expect(find.byTooltip('Удалить изображение'), findsNothing);

    // Выбираем изображение.
    await tester.runAsync(() async {
      await tester.tap(find.text('Выбрать изображение'));
      for (var i = 0; i < 200; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (find.byTooltip('Удалить изображение').evaluate().isNotEmpty) {
          return;
        }
      }
    });
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Удалить изображение'), findsOneWidget);

    // Сохраняем.
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final updated = await repository.getById(created.id!);
    expect(updated!.imagePath, isNotNull);
  });

  testWidgets('удаление изображения программы обнуляет imagePath', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final imgPath = '${tempDir.path}/existing.webp';
    await tester.runAsync(() => File(imgPath).writeAsBytes(_validPng));
    final imageDesc = await createExercise('Тяга', ExerciseType.strength);
    final created = await repository.create(
      program('С изображением').copyWith(imagePath: imgPath),
      [ProgramDay(programId: 0, dayIndex: 0)],
    );
    final day = (await repository.getDays(created.id!)).first;
    await repository.addExerciseToDay(day.id!, imageDesc.id!);

    await pumpBuilder(tester, programId: created.id);

    // Изображение загружено, кнопка удаления есть.
    expect(find.byTooltip('Удалить изображение'), findsOneWidget);

    // Удаляем изображение.
    await tester.tap(find.byTooltip('Удалить изображение'));
    await tester.pump();
    expect(find.byTooltip('Удалить изображение'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final updated = await repository.getById(created.id!);
    expect(updated!.imagePath, isNull);
  });
}
