import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    workoutRepo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpPlan(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/plan',
      routes: [
        GoRoute(
          path: '/plan',
          builder: (context, state) => WeekPlanScreen(
            programRepository: programRepo,
            workoutRepository: workoutRepo,
          ),
        ),
        GoRoute(
          path: '/workout/prepare/:programDayId',
          builder: (context, state) => Scaffold(
            body: Text('prepare-${state.pathParameters['programDayId']}'),
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
  }

  Program program(String name) => Program(
    name: name,
    daysCount: 1,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  Future<ProgramDay> createDay(int dayOfWeek, {String name = 'База'}) async {
    final created = await programRepo.create(program(name), [
      ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: dayOfWeek),
    ]);
    return (await programRepo.getDays(created.id!)).first;
  }

  DateTime mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: d.weekday - 1));
  }

  testWidgets('показывает пустое состояние без программ', (tester) async {
    await pumpPlan(tester);

    expect(find.text('Нет запланированных тренировок'), findsOneWidget);
  });

  testWidgets('тултипы переключения недели на русском', (tester) async {
    await pumpPlan(tester);

    expect(find.byTooltip('Предыдущая неделя'), findsOneWidget);
    expect(find.byTooltip('Следующая неделя'), findsOneWidget);
  });

  testWidgets('показывает запланированный день со статусом и действиями', (
    tester,
  ) async {
    await createDay(DateTime.now().weekday, name: 'Сплит');
    await pumpPlan(tester);

    expect(find.text('Сплит'), findsOneWidget);
    expect(find.text('Запланировано'), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
  });

  testWidgets('после удаления программы айтем исчезает из плана', (
    tester,
  ) async {
    final day = await createDay(DateTime.now().weekday, name: 'Сплит');
    await pumpPlan(tester);
    expect(find.text('Сплит'), findsOneWidget);

    await programRepo.delete(day.programId);
    await tester.pumpAndSettle();

    expect(find.text('Сплит'), findsNothing);
    expect(find.text('Нет запланированных тренировок'), findsOneWidget);
  });

  testWidgets('перенос на сегодня запускает подготовку к тренировке', (
    tester,
  ) async {
    final day = await createDay(_weekdayAfter(DateTime.now().weekday));
    await pumpPlan(tester);

    expect(find.text('Перенести на сегодня'), findsOneWidget);

    await tester.ensureVisible(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();

    expect(find.text('prepare-${day.id}'), findsOneWidget);
  });

  testWidgets('пропуск и отмена пропуска меняют статус', (tester) async {
    await createDay(DateTime.now().weekday);
    await pumpPlan(tester);

    await tester.ensureVisible(find.text('Пропустить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();

    expect(find.text('Пропущено'), findsOneWidget);
    expect(find.text('Отменить пропуск'), findsOneWidget);
    expect(find.text('Начать'), findsNothing);

    await tester.ensureVisible(find.text('Отменить пропуск'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отменить пропуск'));
    await tester.pumpAndSettle();

    expect(find.text('Запланировано'), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
  });

  testWidgets(
    'быстрый старт: кнопка видна при pending-дне и открывает подготовку',
    (tester) async {
      final day = await createDay(DateTime.now().weekday, name: 'Сплит');
      await pumpPlan(tester);

      expect(find.text('Быстрый старт'), findsOneWidget);

      await tester.tap(find.text('Быстрый старт'));
      await tester.pumpAndSettle();

      expect(find.text('prepare-${day.id}'), findsOneWidget);
    },
  );

  testWidgets('быстрый старт: кнопка скрыта без pending-дней', (tester) async {
    final weekday = DateTime.now().weekday;
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(
      DateTime.now(),
    ).add(Duration(days: weekday - 1));
    await saveSession(workoutRepo, day, scheduledDate);

    await pumpPlan(tester);

    expect(find.text('Быстрый старт'), findsNothing);
    expect(find.text('Выполнено'), findsOneWidget);
  });

  testWidgets('сессия в закреплённый день даёт статус «Выполнено»', (
    tester,
  ) async {
    final weekday = DateTime.now().weekday;
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(
      DateTime.now(),
    ).add(Duration(days: weekday - 1));
    await saveSession(workoutRepo, day, scheduledDate);

    await pumpPlan(tester);

    expect(find.text('Выполнено'), findsOneWidget);
    expect(find.text('Начать'), findsNothing);
  });

  testWidgets('сессия в другой день даёт статус «Перенесено»', (tester) async {
    final weekday = _weekdayAfter(DateTime.now().weekday);
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(
      DateTime.now(),
    ).add(Duration(days: weekday - 1));
    await saveSession(
      workoutRepo,
      day,
      scheduledDate.add(const Duration(days: 1)),
    );

    await pumpPlan(tester);

    expect(find.text('Перенесено'), findsOneWidget);
    expect(find.text('Начать'), findsNothing);
  });
}

Future<void> saveSession(
  WorkoutRepository repo,
  ProgramDay day,
  DateTime performedDate,
) async {
  await repo.saveSession(
    WorkoutSession(
      programName: 'База',
      programDayId: day.id,
      dayIndex: day.dayIndex,
      performedDate: performedDate,
      startedAt: performedDate,
      endedAt: performedDate.add(const Duration(minutes: 40)),
    ),
    const [],
  );
}

int _weekdayAfter(int weekday) => weekday >= 7 ? 1 : weekday + 1;
