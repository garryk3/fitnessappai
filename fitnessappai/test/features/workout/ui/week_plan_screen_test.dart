import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_screen.dart';
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
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;
  late PlanScheduleRepository planScheduleRepo;
  late Directory tempDir;

  /// Фиксированная «сегодня»-дата (понедельник) для детерминированных тестов.
  final DateTime fixedNow = DateTime(2026, 8, 10);

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    workoutRepo = WorkoutRepository(db);
    planScheduleRepo = PlanScheduleRepository(db);
    tempDir = await Directory.systemTemp.createTemp('week_plan_screen_test');
    locator.reset();
    locator.registerLazySingleton<MediaCache>(() => MediaCache());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  late GoRouter router;

  Future<void> pumpPlan(
    WidgetTester tester, {
    ThemeData? theme,
    DateTime? now,
  }) async {
    router = GoRouter(
      initialLocation: '/plan',
      routes: [
        GoRoute(
          path: '/plan',
          builder: (context, state) => WeekPlanScreen(
            programRepository: programRepo,
            workoutRepository: workoutRepo,
            planScheduleRepository: planScheduleRepo,
            clock: () => now ?? fixedNow,
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

  Program program(String name, {String? imagePath}) => Program(
    name: name,
    daysCount: 1,
    imagePath: imagePath,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    isActive: true,
    activatedAt: DateTime(2024, 1, 1),
  );

  Future<ProgramDay> createDay(
    int dayOfWeek, {
    String name = 'База',
    String? imagePath,
  }) async {
    final created = await programRepo.create(
      program(name, imagePath: imagePath),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: dayOfWeek)],
    );
    return (await programRepo.getDays(created.id!)).first;
  }

  Future<ProgramDay> createManualDay({String name = 'Ручная'}) async {
    final created = await programRepo.create(program(name), [
      ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: null),
    ]);
    return (await programRepo.getDays(created.id!)).first;
  }

  DateTime mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: d.weekday - 1));
  }

  /// Карточка (колонка) дня недели с указанным номером.
  Finder dayColumn(WidgetTester tester, String dayNumber) =>
      find.ancestor(of: find.text(dayNumber), matching: find.byType(Card));

  testWidgets('показывает пустое состояние без программ', (tester) async {
    await pumpPlan(tester);

    expect(find.text('Нет запланированных тренировок'), findsOneWidget);
  });

  testWidgets('переключение недели: только вперёд (47.10)', (tester) async {
    await pumpPlan(tester);

    expect(find.byTooltip('Следующая неделя'), findsOneWidget);
    // Вид «Месяц» и переход на прошлые недели убраны (47.10).
    expect(find.byTooltip('Предыдущая неделя'), findsNothing);
    expect(find.text('Месяц'), findsNothing);
    // Сегмент «Неделя» тоже исчез: переключать режим больше нечем.
    expect(find.text('Неделя'), findsNothing);
  });

  testWidgets('после перехода на следующую неделю стрелка исчезает (47.10)', (
    tester,
  ) async {
    await pumpPlan(tester);

    IconButton arrow(String tooltip) => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );
    expect(arrow('Следующая неделя').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Следующая неделя'));
    await tester.pumpAndSettle();

    expect(arrow('Следующая неделя').onPressed, isNull);
    expect(find.byTooltip('Предыдущая неделя'), findsNothing);
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

  testWidgets(
    'изображение программы показывается на запланированной карточке',
    (tester) async {
      await tester.runAsync(() async {
        await File('${tempDir.path}/plan.png').writeAsBytes(_validPng);
      });
      await createDay(
        fixedNow.weekday,
        name: 'Сплит',
        imagePath: '${tempDir.path}/plan.png',
      );
      await pumpPlan(tester);

      final card = find.ancestor(
        of: find.text('Сплит'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: card, matching: find.byType(Image)),
        findsWidgets,
      );
    },
  );

  testWidgets('без изображения на запланированной карточке — заглушка', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    final card = find.ancestor(
      of: find.text('Сплит'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.fitness_center)),
      findsOneWidget,
    );
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

  testWidgets('после переноса день-источник пуст (47.3)', (tester) async {
    await createDay(_weekdayAfter(fixedNow.weekday), name: 'Источник');
    await pumpPlan(tester);

    await tester.ensureVisible(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();

    // Экран подготовки открыт; после возврата в план день источника пуст.
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('Источник'), findsNothing);
    expect(find.text('Перенести на сегодня'), findsNothing);
  });

  testWidgets('перенос не убирает соседнюю тренировку того же дня (47.3)', (
    tester,
  ) async {
    final weekday = _weekdayAfter(fixedNow.weekday);
    final first = await createDay(weekday, name: 'Первый');
    await createDay(weekday, name: 'Второй');
    await pumpPlan(tester);

    // Обе тренировки в дне — переносим одну, вторая остаётся.
    final reschedules = find.widgetWithText(
      FilledButton,
      'Перенести на сегодня',
    );
    expect(reschedules, findsNWidgets(2));
    await tester.ensureVisible(reschedules.first);
    await tester.pumpAndSettle();
    await tester.tap(reschedules.first);
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('prepare-${first.id}'), findsNothing);
    expect(find.text('Первый'), findsNothing);
    expect(find.text('Второй'), findsOneWidget);
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

  testWidgets('прошедший день своей недели: перенос доступен (47.2)', (
    tester,
  ) async {
    // fixedNow = 10.08.2026 (понедельник) — день сегодня, а не прошедший.
    // Чтобы получить прошедший день своей же недели, ведём план на воскресенье.
    await createDay(fixedNow.weekday);
    await pumpPlan(tester, now: DateTime(2026, 8, 13));

    expect(
      find.text(
        'Пропущенная тренировка — перенести можно только в рамках '
        'тренировочной недели',
      ),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();
    expect(find.text('Перенести на сегодня'), findsOneWidget);
  });

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
    final weekday = fixedNow.weekday;
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

  testWidgets(
    'будущий запланированный день с сессией в другой день остаётся «Запланировано»',
    (tester) async {
      final weekday = _weekdayAfter(fixedNow.weekday);
      final day = await createDay(weekday);
      final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
      await saveSession(
        workoutRepo,
        day,
        scheduledDate.add(const Duration(days: 1)),
      );

      await pumpPlan(tester);

      expect(find.text('Запланировано'), findsOneWidget);
      expect(find.text('Перенесено'), findsNothing);
    },
  );

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
      final weekday = fixedNow.weekday;
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
      expect(badgeColor(tester, 'Пропущено'), cs.onSurfaceVariant);
      // Пропуск — нейтральная отмена: outlined-чип с бордером outline (не error).
      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Пропущено'),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (badge.decoration! as BoxDecoration).border;
      expect(border, isA<Border>());
      expect((border! as Border).top.color, cs.outline);
    });
  }

  testWidgets('текущий день в неделе выделен цветом', (tester) async {
    // Нужна хотя бы одна запись, чтобы недельная сетка отобразилась.
    await createDay(fixedNow.weekday, name: 'Постоянная');
    await pumpPlan(tester);

    // fixedNow = понедельник 10.08.2026 — это «сегодня» в текущей неделе.
    final colorScheme = Theme.of(
      tester.element(find.text('10').first),
    ).colorScheme;
    expect(colorScheme, isNotNull);

    // Настоящий день имеет значение 10 с primary-цветом — выделен.
    final todayText = tester.widget<Text>(find.text('10').first);
    expect(todayText.style?.color, colorScheme.primary);
  });

  testWidgets('крестик удаления — только у ручного назначения (47.1)', (
    tester,
  ) async {
    // День программы на понедельник (сегодня): тренировка программы — старт и
    // пропуск, удаления нет.
    final day = await createDay(fixedNow.weekday, name: 'Разовое');
    // То же назначение вручную на среду — «кастомное»: только удаление.
    await planScheduleRepo.schedule(
      day.id!,
      fixedNow.add(const Duration(days: 2)),
    );
    await pumpPlan(tester);

    final today = dayColumn(tester, '10');
    expect(
      find.descendant(of: today, matching: find.text('Начать')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: today, matching: find.text('Пропустить')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: today, matching: find.byIcon(Icons.close)),
      findsNothing,
    );

    final wednesday = dayColumn(tester, '12');
    expect(
      find.descendant(of: wednesday, matching: find.byIcon(Icons.close)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: wednesday, matching: find.text('Начать')),
      findsNothing,
    );
    expect(
      find.descendant(of: wednesday, matching: find.text('Пропустить')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: wednesday,
        matching: find.text('Перенести на сегодня'),
      ),
      findsNothing,
    );
  });

  testWidgets('непривязанный день программы: удаления нет (47.1)', (
    tester,
  ) async {
    // Такой день показывается на «сегодня» автоматически, строки в
    // plan_schedule не имеет — крестик удаления был бы «мёртвой» кнопкой.
    await createManualDay(name: 'Ручная');
    await pumpPlan(tester);

    final today = dayColumn(tester, '10');
    expect(
      find.descendant(of: today, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    expect(
      find.descendant(of: today, matching: find.text('Начать')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: today, matching: find.text('Пропустить')),
      findsOneWidget,
    );
  });

  testWidgets('тренировка программы в будущем дне — только перенос (47.1)', (
    tester,
  ) async {
    await createDay(_weekdayAfter(fixedNow.weekday), name: 'Сплит');
    await pumpPlan(tester);

    final tomorrow = dayColumn(tester, '11');
    expect(
      find.descendant(
        of: tomorrow,
        matching: find.text('Перенести на сегодня'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tomorrow, matching: find.text('Начать')),
      findsNothing,
    );
    // Пропуск доступен только тренировкам текущего дня.
    expect(
      find.descendant(of: tomorrow, matching: find.text('Пропустить')),
      findsNothing,
    );
    expect(
      find.descendant(of: tomorrow, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
  });

  testWidgets('пропуск вчерашней тренировки виден, но не отменяется (47.1)', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    await workoutRepo.markSkipped(day.id!, mondayOf(fixedNow));
    // «Сегодня» — вторник: пропуск понедельника остаётся в статусе, но кнопки
    // отмены для прошедших дней нет (амендмент 47.1).
    await pumpPlan(tester, now: fixedNow.add(const Duration(days: 1)));

    expect(find.text('Пропущено'), findsOneWidget);
    expect(find.text('Отменить пропуск'), findsNothing);
    expect(find.text('Начать'), findsNothing);
  });

  testWidgets('тап по пустому дню недели открывает планирование', (
    tester,
  ) async {
    // Постоянная программа привязана к понедельнику — вторник 11 пуст.
    await createDay(fixedNow.weekday, name: 'Постоянная');
    await pumpPlan(tester);

    await tester.tap(find.text('11'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsWidgets);
  });

  testWidgets('тап по занятому дню недели открывает действия дня', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    // «10» — понедельник с тренировкой: тап по карточке открывает попап.
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('10 августа 2026')),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('Сплит'), findsWidgets);
    expect(find.text('Начать'), findsWidgets);
  });

  testWidgets('лист действий ручного назначения — только удаление (47.1)', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    // Ручное назначение того же дня программы на среду.
    await planScheduleRepo.schedule(
      day.id!,
      fixedNow.add(const Duration(days: 2)),
    );
    await pumpPlan(tester);

    await tester.tap(find.text('12').last);
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Удалить назначение')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Пропустить')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Перенести на сегодня')),
      findsNothing,
    );
  });

  testWidgets('карточка планирования показывает программу, день и дату', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    final dayCard = tester.widget<Text>(find.textContaining('День 1').first);
    expect(dayCard.data, 'День 1 · 10 августа 2026');
  });

  testWidgets('попап дня недели показывает программу, день и дату', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Сплит → День 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('10 августа 2026')),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets(
    'узкий экран: попап дня — дата и кнопки на своих строках, без вертикальной даты',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      // Заголовок даты — единственное место с датой, на своей строке.
      expect(
        find.descendant(of: sheet, matching: find.text('10 августа 2026')),
        findsOneWidget,
      );
      // Кнопка «Начать» видна и тапабельна (день 10.08 — сегодня).
      expect(
        find.descendant(of: sheet, matching: find.text('Начать')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find
            .descendant(of: sheet, matching: find.text('Пропустить'))
            .hitTestable(),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'пустая неделя: тап по пустому состоянию открывает планирование',
    (tester) async {
      await pumpPlan(tester);

      expect(find.text('Нет запланированных тренировок'), findsOneWidget);
      await tester.tap(find.text('Нет запланированных тренировок'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Запланировать тренировку'), findsOneWidget);
    },
  );

  testWidgets('запрет планирования на прошедшие даты (неделя)', (tester) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    // Сегодня — среда 12.08.2026, поэтому вторник 11 августа прошёл (47.10:
    // прошлые недели недоступны, guard проверяем внутри текущей).
    await pumpPlan(tester, now: DateTime(2026, 8, 12));

    // Прошедший пустой день — планирование не открывается, показывается SnackBar.
    await tester.tap(find.text('11').last);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.text('Нельзя запланировать тренировку на прошедший день'),
      findsOneWidget,
    );
  });

  testWidgets('занятый день на прошедшей дате всё же открывает действия дня', (
    tester,
  ) async {
    // Понедельник 10 августа с тренировкой, «сегодня» — среда 12.08.2026.
    await createDay(1, name: 'Сплит');
    await pumpPlan(tester, now: DateTime(2026, 8, 12));

    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets(
    'широкая раскладка: тап по занятому дню открывает действия дня (47.16)',
    (tester) async {
      // ≥ 840 px — сетка недели колонками, а не список карточек.
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('10 августа 2026')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Начать')),
        findsWidgets,
      );
    },
  );
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
