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
import 'package:fitnessappai/features/workout/data/plan_view_settings_repository.dart';
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

      expect(find.textContaining('Сплит'), findsWidgets);
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

    testWidgets('после +1 недели стрелка вперёд отключается', (tester) async {
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
      expect(find.byTooltip('Предыдущая неделя'), findsOneWidget);
    });

    testWidgets('свайп вправо открывает предыдущий месяц', (tester) async {
      await pumpPlan(tester);
      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();
      expect(find.text('Август 2026'), findsOneWidget);

      await tester.drag(find.text('10'), const Offset(150, 0));
      await tester.pumpAndSettle();

      expect(find.text('Июль 2026'), findsOneWidget);
    });

    testWidgets('свайп влево открывает следующий месяц', (tester) async {
      await pumpPlan(tester);
      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();

      await tester.drag(find.text('10'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      expect(find.text('Сентябрь 2026'), findsOneWidget);
    });

    testWidgets('свайп за предел ±1 месяц не срабатывает', (tester) async {
      await pumpPlan(tester);
      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();

      // Вперёд до предела (сентябрь).
      await tester.drag(find.text('10'), const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(find.text('Сентябрь 2026'), findsOneWidget);

      // Дальше вперёд нельзя: свайп влево ничего не меняет.
      await tester.drag(find.text('1'), const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(find.text('Сентябрь 2026'), findsOneWidget);

      // Назад до предела (июль).
      await tester.drag(find.text('1'), const Offset(150, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.text('1'), const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(find.text('Июль 2026'), findsOneWidget);
    });
  });

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

  testWidgets('крестик отмены только для ручных назначений', (tester) async {
    // Постоянная программа привязана к среде (не перекрывается с понедельником).
    await createDay(DateTime.wednesday, name: 'Постоянная');
    // Ручное назначение (dayOfWeek == null) — показывается на «сегодня».
    await createManualDay(name: 'Ручная');
    await pumpPlan(tester);

    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'Ручная'),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'Постоянная'),
        matching: find.byIcon(Icons.close),
      ),
      findsNothing,
    );
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

  testWidgets('карточка планирования показывает программу, день и дату', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    final dayCard = tester.widget<Text>(find.textContaining('День 1').first);
    expect(dayCard.data, 'День 1 · 10 августа 2026');
  });

  testWidgets('попап месяца показывает программу, день и дату', (tester) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    await tester.tap(find.text('Месяц'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10'));
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
    'узкий экран: попап месяца — дата и кнопки на своих строках, без вертикальной даты',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await tester.tap(find.text('Месяц'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10'));
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
    await pumpPlan(tester);

    // Переходим на предыдущую неделю (3–9 августа — прошлые дни).
    await tester.tap(find.byTooltip('Предыдущая неделя'));
    await tester.pumpAndSettle();

    // Прошедший пустой день — планирование не открывается, показывается SnackBar.
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.text('Нельзя запланировать тренировку на прошедший день'),
      findsOneWidget,
    );
  });

  testWidgets('запрет планирования на прошедшие даты (месяц)', (tester) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    await tester.tap(find.text('Месяц'));
    await tester.pumpAndSettle();

    // «1» августа — прошедший день при fixedNow = 10.08.2026.
    await tester.tap(find.text('1'));
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
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    // Прошедшая неделя: понедельник 3 августа с тренировкой.
    await tester.tap(find.byTooltip('Предыдущая неделя'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
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
