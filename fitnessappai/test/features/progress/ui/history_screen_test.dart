import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/widgets/calendar/month_grid.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/progress/ui/history_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Заголовок месяца в шапке календаря — регистронезависимый поиск
/// (заголовок капитализируется, ожидания в тестах — в нижнем регистре).
Finder monthTitle(String monthName) =>
    find.textContaining(RegExp(monthName, caseSensitive: false));

void main() {
  late AppDatabase db;
  late WorkoutRepository workoutRepo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    workoutRepo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  WorkoutSession session({
    required DateTime performedDate,
    String programName = 'База',
    WorkoutVariant variant = WorkoutVariant.main,
    DateTime? startedAt,
    DateTime? endedAt,
  }) => WorkoutSession(
    programName: programName,
    dayIndex: 0,
    variant: variant,
    performedDate: performedDate,
    startedAt: startedAt ?? performedDate.add(const Duration(hours: 18)),
    endedAt:
        endedAt ?? performedDate.add(const Duration(hours: 18, minutes: 40)),
  );

  WorkoutSetResult setResult({
    String name = 'Приседания',
    ExerciseType type = ExerciseType.strength,
    int setIndex = 1,
    int? reps = 8,
    double? weightKg = 20,
    int? durationSeconds,
    double? distanceMeters,
    double? avgSpeed,
    double? avgPace,
    int? steps,
    String? side,
  }) => WorkoutSetResult(
    sessionId: 0,
    exerciseId: null,
    exerciseName: name,
    exerciseType: type,
    setIndex: setIndex,
    reps: reps,
    weightKg: weightKg,
    durationSeconds: durationSeconds,
    distanceMeters: distanceMeters,
    avgSpeed: avgSpeed,
    avgPace: avgPace,
    steps: steps,
    side: side,
    completedAt: DateTime(2026, 8, 10, 18, 5),
  );

  Future<void> pumpHistory(
    WidgetTester tester, {
    String location = '/history',
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              HistoryScreen(workoutRepository: workoutRepo),
        ),
        GoRoute(
          path: '/history/:id',
          builder: (context, state) => HistoryDetailScreen(
            sessionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
            workoutRepository: workoutRepo,
          ),
        ),
        GoRoute(
          path: '/progress/day',
          builder: (context, state) => const Scaffold(body: Text('day detail')),
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

  testWidgets('календарь показывает дни месяца и подсвечивает тренировки', (
    tester,
  ) async {
    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    // Календарь отображает день 10 текущего месяца.
    expect(find.text('10'), findsOneWidget);
    // Навигация на /progress/day при тапе.
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('day detail'), findsOneWidget);
  });

  testWidgets('тап по дню без тренировки ничего не делает', (tester) async {
    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    // День 5 текущего месяца — нет тренировки.
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    // Остались на экране истории.
    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets('переключение месяца', (tester) async {
    final now = DateTime.now();
    final monthName = DateFormat('LLLL', 'ru').format(now);
    final prevMonthName = DateFormat(
      'LLLL',
      'ru',
    ).format(DateTime(now.year, now.month - 1));
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month - 1, 15)),
      [setResult()],
    );
    await pumpHistory(tester);

    // Находим заголовок с текущим месяцем.
    expect(monthTitle(monthName), findsOneWidget);

    // Переключаем на предыдущий месяц.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(monthTitle(prevMonthName), findsOneWidget);
  });

  testWidgets('на текущем месяце переход вперёд заблокирован', (tester) async {
    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    final nextButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('на прошлом месяце переход вперёд разрешён', (tester) async {
    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month - 1, 15)),
      [setResult()],
    );
    await pumpHistory(tester);

    // Переходим на прошлый месяц.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    final nextButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(nextButton.onPressed, isNotNull);

    // Переход вперёд возвращает на текущий месяц.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(monthTitle(DateFormat('LLLL', 'ru').format(now)), findsOneWidget);
  });

  testWidgets('свайп вправо открывает предыдущий месяц', (tester) async {
    final now = DateTime.now();
    final monthName = DateFormat('LLLL', 'ru').format(now);
    final prevMonthName = DateFormat(
      'LLLL',
      'ru',
    ).format(DateTime(now.year, now.month - 1));
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month - 1, 15)),
      [setResult()],
    );
    await pumpHistory(tester);
    expect(monthTitle(monthName), findsOneWidget);

    await tester.drag(find.text('10'), const Offset(150, 0));
    await tester.pumpAndSettle();

    expect(monthTitle(prevMonthName), findsOneWidget);
  });

  testWidgets('свайп влево с прошлого месяца возвращает на текущий', (
    tester,
  ) async {
    final now = DateTime.now();
    final monthName = DateFormat('LLLL', 'ru').format(now);
    final prevMonthName = DateFormat(
      'LLLL',
      'ru',
    ).format(DateTime(now.year, now.month - 1));
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month - 1, 15)),
      [setResult()],
    );
    await pumpHistory(tester);

    await tester.drag(find.text('10'), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(monthTitle(prevMonthName), findsOneWidget);

    await tester.drag(find.text('15'), const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(monthTitle(monthName), findsOneWidget);
  });

  testWidgets('свайп влево на текущем месяце не уходит вперёд', (tester) async {
    final now = DateTime.now();
    final monthName = DateFormat('LLLL', 'ru').format(now);
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    await tester.drag(find.text('10'), const Offset(-150, 0));
    await tester.pumpAndSettle();

    expect(monthTitle(monthName), findsOneWidget);
    expect(
      monthTitle(
        DateFormat('LLLL', 'ru').format(DateTime(now.year, now.month + 1)),
      ),
      findsNothing,
    );
  });

  testWidgets('пустая история показывает сообщение', (tester) async {
    await pumpHistory(tester);

    expect(find.text('Пока нет тренировок'), findsOneWidget);
  });

  testWidgets('неизвестная сессия показывает сообщение', (tester) async {
    await pumpHistory(tester, location: '/history/999');

    expect(find.text('Тренировка не найдена'), findsOneWidget);
  });

  testWidgets('новая сессия подсвечивает день без переоткрытия', (
    tester,
  ) async {
    await pumpHistory(tester);
    expect(find.text('Пока нет тренировок'), findsOneWidget);

    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await tester.pumpAndSettle();

    expect(find.text('Пока нет тренировок'), findsNothing);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('«Скопировать JSON» копирует историю и показывает SnackBar', (
    tester,
  ) async {
    locator.registerInstance<LlmExportService>(
      _StubExportService(
        programRepository: ProgramRepository(db),
        exerciseRepository: ExerciseRepository(db, MediaStore()),
        workoutRepository: workoutRepo,
      ),
    );
    addTearDown(locator.reset);

    String? copiedJson;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedJson = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await workoutRepo.saveSession(
      session(performedDate: DateTime(2026, 8, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    await tester.tap(find.byTooltip('Скопировать историю в JSON'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('JSON скопирован в буфер обмена'), findsOneWidget);
    expect(copiedJson, isNotNull);
    expect(copiedJson, startsWith('{"type": "history"'));
  });

  testWidgets('детализация: дистанция с необязательными метриками (47.13)', (
    tester,
  ) async {
    // Экран деталей тянет превью программы из общего кэша медиа.
    locator.registerLazySingleton<MediaCache>(() => MediaCache());
    addTearDown(locator.reset);

    final detail = await workoutRepo
        .saveSession(session(performedDate: DateTime(2026, 8, 10)), [
          setResult(
            name: 'Бег',
            type: ExerciseType.distance,
            reps: null,
            weightKg: null,
            durationSeconds: 3600,
            distanceMeters: 20000,
            avgSpeed: 30,
            avgPace: 2.5,
            steps: 5400,
          ),
        ]);
    await pumpHistory(tester, location: '/history/${detail.session.id}');

    // Дистанция и время плюс те метрики, которые ввёл пользователь.
    expect(
      find.text('1. 20 км × 60 мин · 30 км/ч · 2.5 мин/км · 5400 шагов'),
      findsOneWidget,
    );
  });

  testWidgets('детализация: дистанция без метрик выводится без хвоста', (
    tester,
  ) async {
    locator.registerLazySingleton<MediaCache>(() => MediaCache());
    addTearDown(locator.reset);

    final detail = await workoutRepo
        .saveSession(session(performedDate: DateTime(2026, 8, 10)), [
          setResult(
            name: 'Вело',
            type: ExerciseType.distance,
            reps: null,
            weightKg: null,
            durationSeconds: 1800,
            distanceMeters: 5000,
          ),
        ]);
    await pumpHistory(tester, location: '/history/${detail.session.id}');

    expect(find.text('1. 5 км × 30 мин'), findsOneWidget);
  });

  testWidgets('календарь не обрезается на квадратном экране', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    // Последний день месяца должен быть виден (не обрезан).
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    expect(find.text('$lastDay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('календарь не обрезается и тапабелен на фолд-экране (~585×632)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(585, 632));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    expect(find.text('$lastDay'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Тап по тренировочному дню работает.
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('day detail'), findsOneWidget);
  });

  testWidgets('день с тренировкой выглядит как в плане (иконка в ячейке)', (
    tester,
  ) async {
    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 11)),
      [setResult()],
    );
    await pumpHistory(tester);

    // Иконка тренировки стоит в ячейках дней с попытками (как в плане).
    final icons = find.descendant(
      of: find.byType(MonthGridView),
      matching: find.byIcon(Icons.fitness_center),
    );
    expect(icons, findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('календарь не обрезается на низком фолд-экране (~585×520)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(585, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    expect(find.text('$lastDay'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('календарь на телефоне: квадратные ячейки, прижат к верху', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    // Ячейки квадратные (фикс 47.9), а не растянутые по высоте.
    final cell = tester.getSize(find.byType(MonthDayCell).first);
    expect(cell.width, closeTo(cell.height, 0.5));
    // Сетка прижата к верху под заголовком месяца: между переключателем
    // месяца и календарём нет пустого промежутка.
    final switcherBottom = tester.getBottomLeft(find.byType(MonthSwitcher)).dy;
    final gridTop = tester.getTopLeft(find.byType(MonthGridView)).dy;
    expect(gridTop - switcherBottom, lessThan(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('сжатый по высоте календарь: квадрат и сетка по центру', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    await workoutRepo.saveSession(
      session(performedDate: DateTime(now.year, now.month, 10)),
      [setResult()],
    );
    await pumpHistory(tester);

    // Квадрат: ячейки ужимаются по меньшей из сторон, а не растягиваются.
    final cell = tester.getSize(find.byType(MonthDayCell).first);
    expect(cell.width, closeTo(cell.height, 0.5));

    // При избытке ширины контейнер календаря уменьшается и центрируется
    // по горизонтали: шапка (строка «Пн … Вс») той же ширины, что и сетка.
    final gridRect = tester.getRect(find.byType(MonthGridView));
    const columnGap = 6;
    final gridRowWidth = 7 * cell.width + 6 * columnGap;
    final expectedGridLeft =
        gridRect.left + (gridRect.width - gridRowWidth) / 2;
    final mondayCenter = tester.getCenter(find.text('Пн'));
    expect(mondayCenter.dx, closeTo(expectedGridLeft + cell.width / 2, 1));

    expect(tester.takeException(), isNull);
  });
}

/// Сервис экспорта, возвращающий фиксированный JSON без обращения к БД.
class _StubExportService extends LlmExportService {
  _StubExportService({
    required super.programRepository,
    required super.exerciseRepository,
    required super.workoutRepository,
  });

  @override
  Future<String?> programToJson(int id) async =>
      '{"type": "program", "id": $id}';

  @override
  Future<String> historyToJson() async => '{"type": "history"}';
}
