// ignore_for_file: type=lint
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/widgets/calendar/month_grid.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_screen.dart';
import 'package:fitnessappai/app/localization_delegates.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;
  late PlanScheduleRepository planScheduleRepo;

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
    locator.reset();
    locator.registerLazySingleton<MediaCache>(() => MediaCache());
  });

  tearDown(() async {
    await db.close();
  });

  late GoRouter router;

  Future<void> pumpPlan(
    WidgetTester tester, {
    ThemeData? theme,
    DateTime? now,
    ProgramRepository? programRepository,
    ExerciseRepository? exerciseRepository,
  }) async {
    router = GoRouter(
      initialLocation: '/plan',
      routes: [
        GoRoute(
          path: '/plan',
          builder: (context, state) => WeekPlanScreen(
            programRepository: programRepository ?? programRepo,
            workoutRepository: workoutRepo,
            planScheduleRepository: planScheduleRepo,
            exerciseRepository: exerciseRepository,
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
        localizationsDelegates: appLocalizationsDelegates,
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

  Future<ProgramDay> createManualDay({String name = 'Ручная'}) async {
    final created = await programRepo.create(program(name), [
      ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: null),
    ]);
    return (await programRepo.getDays(created.id!)).first;
  }

  Future<int> insertExercise(String name) {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: ExerciseType.strength,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        );
  }

  DateTime mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: d.weekday - 1));
  }

  /// Ячейка месяца с тренировочной заливкой (primaryContainer)?
  bool hasTrainingBackground(WidgetTester tester, Finder number) {
    final cs = Theme.of(tester.element(number)).colorScheme;
    final containers = tester.widgetList<AppContainer>(
      find.ancestor(of: number, matching: find.byType(AppContainer)),
    );
    return containers.any(
      (c) =>
          c.decoration is BoxDecoration &&
          (c.decoration! as BoxDecoration).color == cs.primaryContainer,
    );
  }

  /// Открывает дравер дня тапом по ячейке месяца.
  Future<void> openDayDrawer(WidgetTester tester, String dayNumber) async {
    await tester.tap(find.text(dayNumber).last);
    await tester.pumpAndSettle();
  }

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

  testWidgets('показывает календарь месяца — единственный вид (59.5.а)', (
    tester,
  ) async {
    await pumpPlan(tester);

    expect(find.byType(MonthGridView), findsOneWidget);
    expect(find.text('Август 2026'), findsOneWidget);
    // Нижняя карточка дня и пустое состояние недели удалены (59.5.б).
    expect(find.text('Нет запланированных тренировок'), findsNothing);
  });

  testWidgets(
    'навигация месяцами: назад заблокирована на текущем, вперёд без ограничения (59.5.в, 51.2)',
    (tester) async {
      await pumpPlan(tester);

      expect(monthArrow(tester, 'Следующий месяц').onPressed, isNotNull);
      // На текущем месяце — нижняя граница: кнопка «назад» есть, но выключена.
      expect(monthArrow(tester, 'Предыдущий месяц').onPressed, isNull);

      await tester.tap(find.byTooltip('Следующий месяц'));
      await tester.pumpAndSettle();
      expect(find.text('Сентябрь 2026'), findsOneWidget);
      expect(monthArrow(tester, 'Предыдущий месяц').onPressed, isNotNull);

      // Вперёд — без ограничения (59.5.в).
      await tester.tap(find.byTooltip('Следующий месяц'));
      await tester.pumpAndSettle();
      expect(find.text('Октябрь 2026'), findsOneWidget);
      expect(monthArrow(tester, 'Следующий месяц').onPressed, isNotNull);

      await tester.tap(find.byTooltip('Предыдущий месяц'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Предыдущий месяц'));
      await tester.pumpAndSettle();
      expect(find.text('Август 2026'), findsOneWidget);
      expect(monthArrow(tester, 'Предыдущий месяц').onPressed, isNull);
    },
  );

  testWidgets(
    'прошлый месяц недоступен даже при старой программе и сессии (51.2)',
    (tester) async {
      // Программа активирована 01.01.2024 и есть тренировка в понедельник, но
      // с 51.2 прошлое в плане не открывается — оно доступно в «Истории».
      await createDay(fixedNow.weekday, name: 'Источник');
      await pumpPlan(tester);

      expect(monthArrow(tester, 'Предыдущий месяц').onPressed, isNull);
      expect(find.text('Август 2026'), findsOneWidget);
      expect(find.text('Июль 2026'), findsNothing);
    },
  );

  testWidgets('тренировочный день: тап по ячейке открывает действия дня', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    // Ячейка тренировочного дня залита primaryContainer…
    expect(hasTrainingBackground(tester, find.text('10')), isTrue);

    // …тап по ней открывает дравер: дата, тренировка, статус и действия.
    await openDayDrawer(tester, '10');
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('10 августа 2026')),
      findsAtLeastNWidgets(1),
    );
    expect(
      find.descendant(of: sheet, matching: find.textContaining('Сплит')),
      findsOneWidget,
      reason: 'заголовок-композит «Сплит → День 1»',
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Пропустить')),
      findsOneWidget,
    );
  });

  testWidgets('редизайн 55.3: «Начать» — pill-CTA AppGradientButton', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');

    // Primary-действие дня — градиентная пилюля (AppGradientButton оборачивает
    // ElevatedButton — контракт finder'ов).
    expect(find.widgetWithText(ElevatedButton, 'Начать'), findsOneWidget);
    // Кнопка «Начать» больше не FilledButton.tonalIcon (55.3).
    expect(find.widgetWithText(FilledButton, 'Начать'), findsNothing);
  });

  testWidgets('после удаления программы ячейка перестаёт быть тренировочной', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);
    expect(hasTrainingBackground(tester, find.text('10')), isTrue);

    await programRepo.delete(day.programId);
    await tester.pumpAndSettle();

    expect(hasTrainingBackground(tester, find.text('10')), isFalse);
  });

  testWidgets('пропуск и отмена пропуска меняют статус', (tester) async {
    await createDay(fixedNow.weekday);
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');
    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();
    // Действие закрывает дравер; статус виден при повторном открытии.
    expect(find.byType(BottomSheet), findsNothing);

    await openDayDrawer(tester, '10');
    var sheet = find.byType(BottomSheet);
    // Сегоднешний пропущенный день показывает кнопку отмены (а не бейдж).
    expect(
      find.descendant(of: sheet, matching: find.text('Отменить пропуск')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );

    await tester.tap(find.text('Отменить пропуск'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);

    await openDayDrawer(tester, '10');
    sheet = find.byType(BottomSheet);
    // После отмены пропуска сегодняшний день — pending с действиями:
    // показываются кнопки, а не бейдж статуса.
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsOneWidget,
    );
  });

  testWidgets('быстрый старт: кнопки нет на плане при pending-дне', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    // На календаре кнопок нет — действия дня живут в дравере.
    expect(find.text('Начать'), findsNothing);
    expect(find.text('Быстрый старт'), findsNothing);
  });

  testWidgets('быстрый старт: кнопка скрыта без pending-дней', (tester) async {
    final weekday = fixedNow.weekday;
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
    await saveSession(workoutRepo, day, scheduledDate);

    await pumpPlan(tester);

    expect(find.text('Быстрый старт'), findsNothing);
  });

  testWidgets('сессия в закреплённый день даёт статус «Выполнено»', (
    tester,
  ) async {
    final weekday = fixedNow.weekday;
    final day = await createDay(weekday);
    final scheduledDate = mondayOf(fixedNow).add(Duration(days: weekday - 1));
    await saveSession(workoutRepo, day, scheduledDate);

    await pumpPlan(tester);
    await openDayDrawer(tester, '10');

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Выполнено')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );
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

    // Сегодня — среда: понедельник 10.08 прошёл (59.5.г).
    await pumpPlan(tester, now: DateTime(2026, 8, 12));
    await openDayDrawer(tester, '10');

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Перенесено')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );
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
      await openDayDrawer(tester, '11');

      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Запланировано')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Перенесено')),
        findsNothing,
      );
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
      // Будущий день без действий рисует бейдж статуса вместо кнопок.
      await createDay(_weekdayAfter(fixedNow.weekday));
      await pumpPlan(tester, theme: theme);
      await openDayDrawer(tester, '11');

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
      await openDayDrawer(tester, '10');

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
      // Сегодня — среда: понедельник 10.08 прошёл, чужая сессия даёт
      // «Перенесено» (59.5.г: для сегодняшнего дня день ещё не прошёл).
      await pumpPlan(tester, theme: theme, now: DateTime(2026, 8, 12));
      await openDayDrawer(tester, '10');

      final cs = Theme.of(tester.element(find.text('Перенесено'))).colorScheme;
      expect(badgeColor(tester, 'Перенесено'), cs.onTertiary);
    });

    testWidgets('бейдж «Пропущено» контрастен ($themeName)', (tester) async {
      final day = await createDay(fixedNow.weekday);
      await workoutRepo.markSkipped(day.id!, mondayOf(fixedNow));
      // Сегодня — среда: понедельник 10.08 прошёл; пропущенный прошедший
      // день без действий показывает бейдж, а не кнопку отмены.
      await pumpPlan(tester, theme: theme, now: DateTime(2026, 8, 12));
      await openDayDrawer(tester, '10');

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

  testWidgets('сегодняшний день в календаре выделен', (tester) async {
    await pumpPlan(tester);

    // fixedNow = понедельник 10.08.2026 — номер «сегодня» подсвечен primary.
    final todayText = tester.widget<Text>(find.text('10').first);
    final colorScheme = Theme.of(
      tester.element(find.text('10').first),
    ).colorScheme;
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

    await openDayDrawer(tester, '10');
    var sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Пропустить')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();
    expect(find.text('prepare-${day.id}'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    await openDayDrawer(tester, '12');
    sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.byIcon(Icons.close)),
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
  });

  testWidgets('непривязанный день программы: удаления нет (47.1)', (
    tester,
  ) async {
    // Такой день показывается на «сегодня» автоматически, строки в
    // plan_schedule не имеет — крестик удаления был бы «мёртвой» кнопкой.
    await createManualDay(name: 'Ручная');
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Пропустить')),
      findsOneWidget,
    );
  });

  testWidgets('тренировка в будущем дне — без действий (59.5.д)', (
    tester,
  ) async {
    await createDay(_weekdayAfter(fixedNow.weekday), name: 'Сплит');
    await pumpPlan(tester);

    await openDayDrawer(tester, '11');
    final sheet = find.byType(BottomSheet);
    // «Перенести на сегодня» удалено; «Начать» и «Пропустить» — только
    // для сегодняшнего дня.
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Пропустить')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    // Правка времени и напоминания остаётся доступной.
    expect(
      find.descendant(of: sheet, matching: find.text('Время и напоминание')),
      findsOneWidget,
    );
  });

  testWidgets('пропуск вчерашней тренировки виден, но не отменяется (59.5.г)', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    await workoutRepo.markSkipped(day.id!, mondayOf(fixedNow));
    // «Сегодня» — вторник: понедельник прошёл; пропуск остаётся в статусе,
    // но кнопки отмены для прошедших дней нет (амендмент 47.1).
    await pumpPlan(tester, now: fixedNow.add(const Duration(days: 1)));

    await openDayDrawer(tester, '10');
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Пропущено')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Отменить пропуск')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );
  });

  testWidgets('тап по пустому дню открывает планирование', (tester) async {
    // Постоянная программа привязана к понедельнику — вторник 11 пуст.
    await createDay(fixedNow.weekday, name: 'Постоянная');
    await pumpPlan(tester);

    await openDayDrawer(tester, '11');

    expect(find.byType(BottomSheet), findsWidgets);
  });

  testWidgets('тап по занятому дню открывает действия дня', (tester) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('10 августа 2026')),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('Сплит'), findsWidgets);
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

    await openDayDrawer(tester, '12');

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
  });

  testWidgets('лист планирования: день с кастомным названием (без «Дня N»)', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    await (programRepo as dynamic).updateDay(day.copyWith(title: 'Грудь'));
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Запланировать тренировку'),
      ),
    );
    await tester.pumpAndSettle();

    // Ряд дня листа показывает кастомное название вместо «День 1».
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Грудь')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('День 1')),
      findsNothing,
    );
    expect(day.id, isNotNull);
  });

  testWidgets('попап дня показывает программу, день и дату', (tester) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    await (programRepo as dynamic).updateDay(day.copyWith(title: 'Грудь'));
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');

    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Сплит → Грудь')),
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

      await openDayDrawer(tester, '10');

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

  testWidgets('запрет планирования на прошедшие даты (месяц)', (tester) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    // Сегодня — среда 12.08.2026, поэтому вторник 11 августа прошёл: guard
    // действует на прошедшие даты текущего месяца (51.2 — прошлые месяцы
    // недоступны).
    await pumpPlan(tester, now: DateTime(2026, 8, 12));

    // Прошедший пустой день — планирование не открывается, показывается SnackBar.
    await openDayDrawer(tester, '11');

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

    await openDayDrawer(tester, '10');

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('широкая раскладка: тап по занятому дню открывает действия дня', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');

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
  });

  testWidgets(
    'занятый день: лист действий показывает и тренировку, и планирование новой (48.9)',
    (tester) async {
      await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await openDayDrawer(tester, '10');

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

      await openDayDrawer(tester, '10');

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

      await openDayDrawer(tester, '10');

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

      await openDayDrawer(tester, '10');

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

      await openDayDrawer(tester, '10');

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

      // Дравер понедельника теперь показывает обе тренировки.
      await openDayDrawer(tester, '10');
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('Гибкость'),
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

    await openDayDrawer(tester, '11');

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

      await openDayDrawer(tester, '11');

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

      // Дравер вторника: время в пункте «Время и напоминание» (59.5.е).
      await openDayDrawer(tester, '11');
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('18:30'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'пункт «Время и напоминание» задаёт время дню по привязке (48.10)',
    (tester) async {
      final day = await createDay(fixedNow.weekday, name: 'Сплит');
      await pumpPlan(tester);

      await openDayDrawer(tester, '10');

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
      await openDayDrawer(tester, '10');
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('07:45'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );
    },
  );

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
    // Четверг 13.08: понедельник 10.08 в прошлом, но внутри месяца.
    await pumpPlan(tester, now: DateTime(2026, 8, 13));

    await openDayDrawer(tester, '10');
    await tester.tap(find.text('Время и напоминание'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('Нельзя запланировать тренировку на прошедший день'),
      findsOneWidget,
    );
    final item = await planScheduleRepo.getFor(day.id!, fixedNow);
    expect(item!.timeLabel, '09:00', reason: 'время не изменилось');
  });

  testWidgets(
    'лист планирования: склонение «1 упражнение» вместо «1 упражнений» (53.3)',
    (tester) async {
      final day = await createDay(fixedNow.weekday, name: 'Сплит');
      final exId = await insertExercise('Жим лёжа');
      await programRepo.addExerciseToDay(day.id!, exId);
      // Вторая программа отключает auto-select (лист остаётся на списке).
      await createDay(_weekdayAfter(fixedNow.weekday), name: 'Гибкость');
      await pumpPlan(tester);

      // Среда 12.08 пуста — открываем лист (вт занят «Гибкостью», пн — «Сплит»).
      await openDayDrawer(tester, '12');

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('Сплит')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('1 упражнение')),
        findsOneWidget,
        reason: 'plural-ключ l10n, а не голая склейка',
      );
      expect(
        find.descendant(of: sheet, matching: find.text('1 упражнений')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'лист планирования: непривязанный день — «Без привязки» из l10n (53.3)',
    (tester) async {
      await createManualDay(name: 'Сплит');
      await pumpPlan(tester);

      // Вторник 11.08 пуст — открываем лист и выбираем программу.
      await openDayDrawer(tester, '11');

      final sheet = find.byType(BottomSheet);
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Сплит')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: sheet, matching: find.text('Без привязки')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ошибка загрузки плана: явное состояние с повтором вместо пустого месяца (53.3)',
    (tester) async {
      final flaky = _FlakyProgramRepository(programRepo)..failActive = true;
      await pumpPlan(tester, programRepository: flaky);

      expect(find.text('Не удалось загрузить план'), findsOneWidget);
      expect(find.byType(MonthGridView), findsNothing);

      // «БД починилась» — повтор восстанавливает план.
      flaky.failActive = false;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить план'), findsNothing);
      expect(find.byType(MonthGridView), findsOneWidget);
    },
  );

  testWidgets(
    'лист планирования: ошибка загрузки программ — текст и повтор (53.3)',
    (tester) async {
      final flaky = _FlakyProgramRepository(programRepo)..failList = true;
      await pumpPlan(tester, programRepository: flaky);

      // Программ нет — любой пустой день открывает лист планирования напрямую.
      await openDayDrawer(tester, '11');

      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Не удалось загрузить список программ'),
        ),
        findsOneWidget,
      );

      flaky.failList = false;
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Повторить')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Не удалось загрузить список программ'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Нет программ для назначения'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('месяц: сетка будней и индикация тренировочных дней', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    // Ряд будней по образцу календаря.
    for (final weekday in const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']) {
      expect(find.text(weekday), findsOneWidget);
    }

    // Понедельник 10.08 (тренировочный день) залит primaryContainer…
    expect(hasTrainingBackground(tester, find.text('10')), isTrue);
    // …а пустой вторник 25.08 — нет.
    expect(hasTrainingBackground(tester, find.text('25')), isFalse);
  });

  testWidgets('месяц: ячейки тренировочных дней показывают иконки групп', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    final exId = await insertExercise('Жим лёжа');
    final chest = await (db.select(
      db.muscleGroups,
    )..where((t) => t.key.equals('chest'))).getSingle();
    await db
        .into(db.exerciseMuscles)
        .insert(
          ExerciseMusclesCompanion.insert(
            exerciseId: exId,
            muscleGroupId: chest.id,
            intensity: MuscleIntensity.primary,
          ),
        );
    await programRepo.addExerciseToDay(day.id!, exId);
    await pumpPlan(
      tester,
      exerciseRepository: ExerciseRepository(db, MediaStore()),
    );

    // Понедельники августа (3, 10, 17, 24, 31) — по иконке «грудь» в ячейке.
    expect(find.byType(MuscleGroupIcon), findsNWidgets(5));
  });

  testWidgets('месяц: навигация вперёд без ограничения (59.5.в)', (
    tester,
  ) async {
    await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    expect(find.text('Август 2026'), findsOneWidget);
    expect(monthArrow(tester, 'Предыдущий месяц').onPressed, isNull);
    expect(monthArrow(tester, 'Следующий месяц').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Следующий месяц'));
    await tester.pumpAndSettle();

    expect(find.text('Сентябрь 2026'), findsOneWidget);
    expect(monthArrow(tester, 'Предыдущий месяц').onPressed, isNotNull);
    expect(monthArrow(tester, 'Следующий месяц').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Предыдущий месяц'));
    await tester.pumpAndSettle();

    expect(find.text('Август 2026'), findsOneWidget);
    expect(monthArrow(tester, 'Предыдущий месяц').onPressed, isNull);
  });

  testWidgets('дравер дня: выполненный день — бейдж без действий (47.1)', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    final scheduledDate = mondayOf(
      fixedNow,
    ).add(Duration(days: fixedNow.weekday - 1));
    await saveSession(workoutRepo, day, scheduledDate);
    await pumpPlan(tester);

    await openDayDrawer(tester, '10');

    // Строка информационная: статус на месте, действий нет —
    // дубль-сессии из плана не создать (гейтинг dayActionsFor, 47.1).
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Выполнено')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );
  });

  testWidgets('дравер дня: будущий день — время, но без старта (59.5.д)', (
    tester,
  ) async {
    final day = await createDay(fixedNow.weekday, name: 'Сплит');
    await pumpPlan(tester);

    // Следующий понедельник 17.08: будущий день — без «Перенести на сегодня»
    // и без старта; остаётся правка времени и напоминания.
    await openDayDrawer(tester, '17');

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('17 августа 2026')),
      findsAtLeastNWidgets(1),
    );
    expect(
      find.descendant(of: sheet, matching: find.textContaining('Сплит')),
      findsOneWidget,
    );
    // Будущий день без действий — бейдж «Запланировано» вместо кнопок.
    expect(
      find.descendant(of: sheet, matching: find.text('Запланировано')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Начать')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Время и напоминание')),
      findsOneWidget,
    );
    expect(day.id, isNotNull);
  });
}

IconButton monthArrow(WidgetTester tester, String tooltip) =>
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

/// Репозиторий программ с переключаемыми сбоями (53.3): имитирует сбой чтения
/// БД для контроллера (`failActive`) и списка программ листа (`failList`).
class _FlakyProgramRepository implements ProgramRepository {
  _FlakyProgramRepository(this.inner);

  final ProgramRepository inner;

  /// Сбой загрузки плана: `getActivePrograms` бросает.
  bool failActive = false;

  /// Сбой загрузки списка программ листа: `getPrograms` бросает.
  bool failList = false;

  @override
  Future<List<Program>> getActivePrograms() {
    if (failActive) throw Exception('db down');
    return inner.getActivePrograms();
  }

  @override
  Future<List<ProgramSummary>> getPrograms() {
    if (failList) throw Exception('db down');
    return inner.getPrograms();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
