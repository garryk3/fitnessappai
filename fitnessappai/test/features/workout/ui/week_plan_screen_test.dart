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
    // Русская локаль на устройствах даёт 24-часовой формат времени. Без него
    // Material принимает в часах только 1–12 («18» — уже ошибка ввода), а план
    // показывает HH:mm (48.10). Флаг ставится до сборки дерева: корневой View
    // кэширует MediaQueryData и пересчитывает её не при каждой сборке, поэтому
    // значение, выставленное после первого кадра, в дерево уже не попадает.
    TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .alwaysUse24HourFormatTestValue =
        true;
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

  /// Вводит время в открытом `TimePickerDialog` и подтверждает (48.10).
  ///
  /// Стандартный путь через циферблат в тестах недетерминирован, поэтому
  /// переключаемся в режим ручного ввода.
  Future<void> enterTime(
    WidgetTester tester, {
    required String hour,
    required String minute,
  }) async {
    final dialog = find.byType(TimePickerDialog);
    expect(dialog, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.byIcon(Icons.keyboard_outlined),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: dialog,
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2), reason: 'часы и минуты');
    await tester.enterText(fields.at(0), hour);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), minute);
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: dialog, matching: find.text('ОК')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
  }

  testWidgets('показывает пустое состояние без программ', (tester) async {
    await pumpPlan(tester);

    expect(find.text('Нет запланированных тренировок'), findsOneWidget);
  });

  testWidgets('переключение недели: назад есть, включается по границе (48.3)', (
    tester,
  ) async {
    await pumpPlan(tester);

    expect(find.byTooltip('Следующая неделя'), findsOneWidget);
    // Кнопка «назад» есть всегда: на текущей неделе данных для просмотра
    // прошлого нет (нет ни активной программы, ни сессий) — она выключена.
    expect(find.byTooltip('Предыдущая неделя'), findsOneWidget);
    expect(weekSwitcherArrow(tester, 'Предыдущая неделя').onPressed, isNull);
    expect(find.text('10–16 августа'), findsOneWidget);
    // Вид «Месяц» убран в 47.10 и не возвращается (48.3 возвращает только
    // просмотр прошлых недель).
    expect(find.text('Месяц'), findsNothing);
    // Сегмент «Неделя» тоже исчез: переключать режим больше нечем.
    expect(find.text('Неделя'), findsNothing);
  });

  testWidgets('вперёд и назад: стрелки включаются по границам недели (48.3)', (
    tester,
  ) async {
    await pumpPlan(tester);

    expect(weekSwitcherArrow(tester, 'Следующая неделя').onPressed, isNotNull);
    expect(weekSwitcherArrow(tester, 'Предыдущая неделя').onPressed, isNull);

    await tester.tap(find.byTooltip('Следующая неделя'));
    await tester.pumpAndSettle();

    expect(find.text('17–23 августа'), findsOneWidget);
    // Дальше вперёд некуда (47.10), но назад — на текущую неделю — можно.
    expect(weekSwitcherArrow(tester, 'Следующая неделя').onPressed, isNull);
    expect(weekSwitcherArrow(tester, 'Предыдущая неделя').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Предыдущая неделя'));
    await tester.pumpAndSettle();

    expect(find.text('10–16 августа'), findsOneWidget);
    expect(weekSwitcherArrow(tester, 'Предыдущая неделя').onPressed, isNull);
    expect(weekSwitcherArrow(tester, 'Следующая неделя').onPressed, isNotNull);
  });

  testWidgets(
    'прошлая неделя: только просмотр, действий и планирования нет (48.3)',
    (tester) async {
      // Программа активирована 01.01.2024 — нижняя граница навигации назад
      // позволяет уйти на прошлую неделю.
      await createDay(_weekdayAfter(fixedNow.weekday), name: 'Источник');
      await pumpPlan(tester);

      expect(
        weekSwitcherArrow(tester, 'Предыдущая неделя').onPressed,
        isNotNull,
      );
      await tester.tap(find.byTooltip('Предыдущая неделя'));
      await tester.pumpAndSettle();

      expect(find.text('3–9 августа'), findsOneWidget);

      // Тренировка прошедшей недели видна, но её статус только для просмотра:
      // кнопок «Начать»/«Перенести на сегодня» у неё нет.
      expect(find.text('Источник'), findsOneWidget);
      expect(find.text('Пропущено'), findsOneWidget);
      expect(find.text('Перенести на сегодня'), findsNothing);
      expect(find.text('Начать'), findsNothing);

      // Пустой день прошлой недели не даёт запланировать тренировку.
      await tester.tap(find.text('3').last);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.text('Нельзя запланировать тренировку на прошедший день'),
        findsOneWidget,
      );
    },
  );

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

  testWidgets('после тапа переноса день-источник остаётся (48.4)', (
    tester,
  ) async {
    final day = await createDay(
      _weekdayAfter(fixedNow.weekday),
      name: 'Источник',
    );
    await pumpPlan(tester);

    await tester.ensureVisible(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();

    // Экран подготовки открыт.
    expect(find.text('prepare-${day.id}'), findsOneWidget);

    // Возврат в план: тренировка не выполнена, поэтому день-источник пока не
    // пустеет — раньше он очищался сразу при тапе (задача 48.4).
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('Источник'), findsOneWidget);
    expect(find.text('Перенести на сегодня'), findsOneWidget);
  });

  testWidgets('после сохранения сессии день-источник пуст (47.3, 48.4)', (
    tester,
  ) async {
    final day = await createDay(
      _weekdayAfter(fixedNow.weekday),
      name: 'Источник',
    );
    await pumpPlan(tester);

    // Отметку переноса ставит экран выполнения после фактического сохранения
    // сессии (48.4) — здесь тот же шаг напрямую в репозитории.
    await workoutRepo.markRescheduled(day.id!, fixedNow);
    await tester.pumpAndSettle();

    expect(find.text('Источник'), findsNothing);
    expect(find.text('Перенести на сегодня'), findsNothing);
  });

  testWidgets(
    'тап переноса не убирает соседнюю тренировку того же дня (47.3, 48.4)',
    (tester) async {
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

      // Перенос ещё не выполнен: обе тренировки на месте, обе кнопки активны.
      expect(find.text('prepare-${first.id}'), findsNothing);
      expect(find.text('Первый'), findsOneWidget);
      expect(find.text('Второй'), findsOneWidget);
      expect(reschedules, findsNWidgets(2));
    },
  );

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
    // Сегодня — среда 12.08.2026, поэтому вторник 11 августа прошёл (guard
    // действует и в текущей неделе, и в прошлых — 48.3).
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

  testWidgets(
    'занятый день: лист действий показывает и тренировку, и планирование новой (48.9)',
    (tester) async {
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      // Существующие действия дня (47.1) не тронуты.
      expect(
        find.descendant(of: sheet, matching: find.text('Начать')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Пропустить')),
        findsOneWidget,
      );
      // Новый пункт планирования — отдельным разделителем в конце списка.
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Запланировать тренировку'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'тап по «Запланировать тренировку» открывает лист выбора программы (48.9)',
    (tester) async {
      await createDay(fixedNow.weekday, name: 'Сплит');
      await createDay(_weekdayAfter(fixedNow.weekday), name: 'Гибкость');
      await pumpPlan(tester);

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Запланировать тренировку'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      // Лист действий закрыт, открылось привычное планирование.
      expect(
        find.descendant(of: sheet, matching: find.text('Начать')),
        findsNothing,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Выберите программу')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Сплит')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Гибкость')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'прошедший день: пункт планирования закрыт той же защитой, что и у пустого дня (48.9)',
    (tester) async {
      // Понедельник 10 августа с тренировкой, «сегодня» — среда 12.08.2026.
      await createDay(1, name: 'Сплит');
      await pumpPlan(tester, now: DateTime(2026, 8, 12));

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Запланировать тренировку'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: sheet,
          matching: find.text('Запланировать тренировку'),
        ),
      );
      await tester.pumpAndSettle();

      // Лист закрывается, лист планирования не открывается, показывается guard.
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.text('Нельзя запланировать тренировку на прошедший день'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'уже назначенный день: сообщение «запланировано» и без создания дубля (48.9)',
    (tester) async {
      // Единственная программа — лист планирования сразу показывает её дни.
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Запланировать тренировку'),
        ),
      );
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('День 1')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.text('Этот день уже запланирован на эту дату'),
        findsOneWidget,
      );
      // День и так показан по привязке к дню недели — строка не создаётся.
      final rows = await planScheduleRepo.getForRange(fixedNow, fixedNow);
      expect(rows, isEmpty);
    },
  );

  testWidgets(
    'с нового пункта на занятый день назначается второй день программы (48.9)',
    (tester) async {
      await createDay(fixedNow.weekday, name: 'Сплит');
      final other = await createDay(
        _weekdayAfter(fixedNow.weekday),
        name: 'Гибкость',
      );
      await pumpPlan(tester);

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Запланировать тренировку'),
        ),
      );
      await tester.pumpAndSettle();

      // Две программы — лист выбора, авто-выбор не срабатывает.
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Гибкость'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('День 1'),
        ),
      );
      await tester.pumpAndSettle();

      // 48.10: после выбора дня — шаг времени; время можно не задать,
      // назначение подтверждается кнопкой.
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Время и напоминание'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Запланировать'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);

      // Назначение записано ровно один раз и привязано к нужному дню.
      final rows = await planScheduleRepo.getForRange(fixedNow, fixedNow);
      expect(rows, hasLength(1));
      expect(rows.single.programDayId, other.id);

      // Понедельник теперь показывает обе тренировки.
      expect(
        find.descendant(
          of: dayColumn(tester, '10'),
          matching: find.text('Гибкость'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('лист планирования: шаг времени перед назначением (48.10)', (
    tester,
  ) async {
    // Программа привязана к понедельнику — вторник 11 пуст.
    final day = await createDay(fixedNow.weekday, name: 'Постоянная');
    await pumpPlan(tester);

    await tester.tap(find.text('11'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    // Единственная программа выбрана сама — сразу список дней.
    await tester.tap(find.descendant(of: sheet, matching: find.text('День 1')));
    await tester.pumpAndSettle();

    // Шаг времени: время можно не задать.
    expect(
      find.descendant(of: sheet, matching: find.text('Время и напоминание')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Время тренировки')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Время не задано')),
      findsOneWidget,
    );
    final reminderSwitch = tester.widget<SwitchListTile>(
      find.descendant(of: sheet, matching: find.byType(SwitchListTile)),
    );
    expect(reminderSwitch.value, isFalse);
    expect(
      reminderSwitch.onChanged,
      isNull,
      reason: 'без времени напоминание не включить',
    );

    // Стрелка назад возвращает к списку дней.
    await tester.tap(
      find.descendant(of: sheet, matching: find.byIcon(Icons.arrow_back)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.text('День 1')),
      findsOneWidget,
    );
    await tester.tap(find.descendant(of: sheet, matching: find.text('День 1')));
    await tester.pumpAndSettle();

    // Назначение подтверждается и без времени — как до 48.10.
    await tester.tap(
      find.descendant(of: sheet, matching: find.text('Запланировать')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsNothing);
    final item = await planScheduleRepo.getFor(
      day.id!,
      fixedNow.add(const Duration(days: 1)),
    );
    expect(item, isNotNull);
    expect(item!.hasTime, isFalse);
    expect(item.reminderEnabled, isFalse);
  });

  testWidgets(
    'назначение со временем: часы и напоминание сохраняются (48.10)',
    (tester) async {
      final day = await createDay(fixedNow.weekday, name: 'Постоянная');
      await pumpPlan(tester);

      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('День 1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Время тренировки')),
      );
      await tester.pumpAndSettle();
      await enterTime(tester, hour: '18', minute: '30');

      expect(
        find.descendant(of: sheet, matching: find.text('18:30')),
        findsOneWidget,
      );
      // С временем переключатель напоминания включается.
      final switchTile = find.descendant(
        of: sheet,
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(switchTile);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(switchTile).value, isTrue);

      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Запланировать')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);
      final item = await planScheduleRepo.getFor(
        day.id!,
        fixedNow.add(const Duration(days: 1)),
      );
      expect(item, isNotNull);
      expect(item!.timeLabel, '18:30');
      expect(item.reminderEnabled, isTrue);

      // Карточка вторника: время в заголовке и на карточке + колокольчик.
      expect(
        find.descendant(
          of: dayColumn(tester, '11'),
          matching: find.text('18:30'),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: dayColumn(tester, '11'),
          matching: find.byIcon(Icons.notifications_active),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'тап по строке времени карточки: диалог и «Убрать время» (48.10)',
    (tester) async {
      final day = await createDay(fixedNow.weekday, name: 'Сплит');
      await planScheduleRepo.schedule(
        day.id!,
        fixedNow,
        hour: 9,
        minute: 0,
        reminderEnabled: true,
      );
      await pumpPlan(tester);

      await tester.tap(
        find.descendant(
          of: dayColumn(tester, '10'),
          matching: find.byIcon(Icons.access_time),
        ),
      );
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Время и напоминание')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('09:00')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.descendant(
                of: dialog,
                matching: find.byType(SwitchListTile),
              ),
            )
            .value,
        isTrue,
        reason: 'включённое напоминание переносится в диалог',
      );

      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Убрать время')),
      );
      await tester.pumpAndSettle();

      final item = await planScheduleRepo.getFor(day.id!, fixedNow);
      expect(item, isNotNull);
      expect(item!.hasTime, isFalse);
      expect(item.reminderEnabled, isFalse);
      // Назначение не тронуто — убрано только время.
      expect(await planScheduleRepo.isScheduled(day.id!, fixedNow), isTrue);
      expect(
        find.descendant(
          of: dayColumn(tester, '10'),
          matching: find.byIcon(Icons.access_time),
        ),
        findsNothing,
        reason: 'строка времени на карточке исчезла',
      );
    },
  );

  testWidgets(
    'пункт «Время и напоминание» задаёт время дню по привязке (48.10)',
    (tester) async {
      final day = await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Время и напоминание')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Время не задано')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Время и напоминание')),
      );
      await tester.pumpAndSettle();

      // Лист действий закрылся — открылся диалог правки.
      expect(find.byType(BottomSheet), findsNothing);
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Время тренировки')),
      );
      await tester.pumpAndSettle();
      await enterTime(tester, hour: '7', minute: '45');
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Сохранить')),
      );
      await tester.pumpAndSettle();

      final item = await planScheduleRepo.getFor(day.id!, fixedNow);
      expect(item, isNotNull);
      expect(item!.timeLabel, '07:45');
      expect(item.reminderEnabled, isFalse, reason: 'галочку не включали');

      // Для дня по привязке создаётся строка plan_schedule, но крестика
      // удаления и статуса ручного назначения не появляется (решение (2)).
      expect(
        find.descendant(
          of: dayColumn(tester, '10'),
          matching: find.byIcon(Icons.access_time),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dayColumn(tester, '10'),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('заголовок дня собирает времена всех тренировок (48.10)', (
    tester,
  ) async {
    final morning = await createDay(fixedNow.weekday, name: 'Утренняя');
    final evening = await createDay(fixedNow.weekday, name: 'Вечерняя');
    await planScheduleRepo.schedule(morning.id!, fixedNow, hour: 18, minute: 0);
    await planScheduleRepo.schedule(evening.id!, fixedNow, hour: 9, minute: 0);
    await pumpPlan(tester);

    // Сортировка по возрастанию времени, дублей в подписи нет.
    expect(find.text('09:00, 18:00'), findsOneWidget);
    expect(
      find.descendant(
        of: dayColumn(tester, '10'),
        matching: find.text('09:00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dayColumn(tester, '10'),
        matching: find.text('18:00'),
      ),
      findsOneWidget,
    );
    // Обе карточки показывают время — у каждой строки плана своё.
    expect(
      find.descendant(
        of: dayColumn(tester, '10'),
        matching: find.byIcon(Icons.access_time),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('правка времени на прошедшей дате закрыта защитой (48.10)', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    await planScheduleRepo.schedule(
      day.id!,
      fixedNow,
      hour: 9,
      minute: 0,
      reminderEnabled: true,
    );
    // Четверг 13.08: понедельник 10.08 в прошлом, но внутри недели.
    await pumpPlan(tester, now: DateTime(2026, 8, 13));

    await tester.tap(
      find.descendant(
        of: dayColumn(tester, '10'),
        matching: find.byIcon(Icons.access_time),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('Нельзя запланировать тренировку на прошедший день'),
      findsOneWidget,
    );
    final item = await planScheduleRepo.getFor(day.id!, fixedNow);
    expect(item!.timeLabel, '09:00', reason: 'время не изменилось');
  });
}

IconButton weekSwitcherArrow(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );

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
