import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

class _FakeWakelock implements WakelockService {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
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
        filePicker: () async => null,
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
            wakelockService: wakelock,
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

    await tester.tap(find.text('Завершить тренировку'));
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
}
