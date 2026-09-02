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
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_view_settings_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;
  late PlanScheduleRepository planScheduleRepo;

  /// Фиксированная «сегодня»-дата (понедельник) для детерминированных тестов.
  final DateTime fixedNow = DateTime(2026, 8, 10);

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    workoutRepo = WorkoutRepository(db);
    planScheduleRepo = PlanScheduleRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpPlan(WidgetTester tester, {ThemeData? theme}) async {
    final router = GoRouter(
      initialLocation: '/plan',
      routes: [
        GoRoute(
          path: '/plan',
          builder: (context, state) => WeekPlanScreen(
            programRepository: programRepo,
            workoutRepository: workoutRepo,
            planViewSettingsRepository: PlanViewSettingsRepository(db),
            planScheduleRepository: planScheduleRepo,
            clock: () => fixedNow,
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
        theme: theme ?? AppTheme.dark(),
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
    isActive: true,
    activatedAt: DateTime(2024, 1, 1),
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
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    expect(find.text('Сплит'), findsOneWidget);
    expect(find.text('Запланировано'), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
  });

  testWidgets('после удаления программы айтем исчезает из плана', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
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
    final day = await createDay(_weekdayAfter(fixedNow.weekday));
    await pumpPlan(tester);

    expect(find.text('Перенести на сегодня'), findsOneWidget);

    await tester.ensureVisible(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();

    expect(find.text('prepare-${day.id}'), findsOneWidget);
  });

  testWidgets('пропуск и отмена пропуска меняют статус', (tester) async {
    await createDay(fixedNow.weekday);
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
    'прошлая неделя: невыполненная тренировка без кнопок «Пропущено»',
    (tester) async {
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      // Текущая неделя: день сегодня — активен.
      expect(find.text('Запланировано'), findsOneWidget);
      expect(find.text('Начать'), findsOneWidget);

      // Переходим на прошлую неделю — тренировка старше окна переноса.
      await tester.tap(find.byTooltip('Предыдущая неделя'));
      await tester.pumpAndSettle();

      expect(find.text('Пропущено'), findsOneWidget);
      expect(find.text('Начать'), findsNothing);
      expect(find.text('Перенести на сегодня'), findsNothing);
      expect(find.text('Пропустить'), findsNothing);
      expect(find.text('Отменить пропуск'), findsNothing);
    },
  );

  testWidgets('быстрый старт: кнопки нет на плане при pending-дне', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Быстрый старт'), findsNothing);
  });

  testWidgets('быстрый старт: кнопка скрыта без pending-дней', (tester) async {
    final weekday = fixedNow.weekday;
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
    await saveSession(workoutRepo, day, scheduledDate);

    await pumpPlan(tester);

    expect(find.text('Быстрый старт'), findsNothing);
    expect(find.text('Выполнено'), findsOneWidget);
  });

  testWidgets('сессия в закреплённый день даёт статус «Выполнено»', (
    tester,
  ) async {
    final weekday = fixedNow.weekday;
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
    await saveSession(workoutRepo, day, scheduledDate);

    await pumpPlan(tester);

    expect(find.text('Выполнено'), findsOneWidget);
    expect(find.text('Начать'), findsNothing);
  });

  testWidgets('сессия в другой день даёт статус «Перенесено»', (tester) async {
    final weekday = _weekdayAfter(fixedNow.weekday);
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
    await saveSession(
      workoutRepo,
      day,
      scheduledDate.add(const Duration(days: 1)),
    );

    await pumpPlan(tester);

    expect(find.text('Перенесено'), findsOneWidget);
    expect(find.text('Начать'), findsNothing);
  });

  for (final theme in [AppTheme.light(), AppTheme.dark()]) {
    final themeName = theme.brightness == Brightness.light
        ? 'светлая'
        : 'тёмная';

    Color badgeColor(WidgetTester tester, String label) {
      final text = tester.widget<Text>(find.text(label));
      return text.style!.color!;
    }

    testWidgets('бейдж «Запланировано» контрастен ($themeName)', (
      tester,
    ) async {
      await createDay(fixedNow.weekday);
      await pumpPlan(tester, theme: theme);

      final cs = Theme.of(
        tester.element(find.text('Запланировано')),
      ).colorScheme;
      expect(badgeColor(tester, 'Запланировано'), cs.onSurfaceVariant);
    });

    testWidgets('бейдж «Выполнено» контрастен ($themeName)', (tester) async {
      final weekday = fixedNow.weekday;
      final day = await createDay(weekday);
      final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
      await saveSession(workoutRepo, day, scheduledDate);
      await pumpPlan(tester, theme: theme);

      final cs = Theme.of(tester.element(find.text('Выполнено'))).colorScheme;
      expect(badgeColor(tester, 'Выполнено'), cs.onPrimary);
    });

    testWidgets('бейдж «Перенесено» контрастен ($themeName)', (tester) async {
      final weekday = _weekdayAfter(fixedNow.weekday);
      final day = await createDay(weekday);
      final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
      await saveSession(
        workoutRepo,
        day,
        scheduledDate.add(const Duration(days: 1)),
      );
      await pumpPlan(tester, theme: theme);

      final cs = Theme.of(tester.element(find.text('Перенесено'))).colorScheme;
      expect(badgeColor(tester, 'Перенесено'), cs.onTertiary);
    });

    testWidgets('бейдж «Пропущено» контрастен ($themeName)', (tester) async {
      await createDay(fixedNow.weekday);
      await pumpPlan(tester, theme: theme);

      await tester.ensureVisible(find.text('Пропустить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Пропустить'));
      await tester.pumpAndSettle();

      final cs = Theme.of(tester.element(find.text('Пропущено'))).colorScheme;
      expect(badgeColor(tester, 'Пропущено'), cs.onError);
    });
  }

  group('режим «Месяц»', () {
    testWidgets('тумблер переключает на месяц и показывает сетку', (
      tester,
    ) async {
      await pumpPlan(tester);

      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();

      expect(find.text('Август 2026'), findsOneWidget);
      // Дни месяца видны в сетке даже без тренировок.
      expect(find.text('10'), findsWidgets);
    });

    testWidgets('тап по дню с тренировкой открывает попап', (tester) async {
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      expect(find.text('Сплит'), findsOneWidget);
      expect(find.text('Начать'), findsOneWidget);
    });

    testWidgets('имя программы в попапе ограничено двумя строками', (
      tester,
    ) async {
      await createDay(
        fixedNow.weekday,
        name:
            'Очень длинное название тренировочной программы для проверки переноса',
      );
      await pumpPlan(tester);

      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(
        find.textContaining('Очень длинное название').first,
      );
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('день без тренировки открывает лист планирования', (
      tester,
    ) async {
      await pumpPlan(tester);

      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();

      // «15» августа — выходной без тренировки: тап открывает schedule sheet.
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('выбор «Месяц» сохраняется между открытиями', (tester) async {
      await pumpPlan(tester);
      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();
      expect(find.text('Август 2026'), findsOneWidget);

      await pumpPlan(tester);
      await tester.pumpAndSettle();
      expect(find.text('Август 2026'), findsOneWidget);
    });
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
