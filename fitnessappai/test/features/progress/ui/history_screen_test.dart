import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/progress/ui/history_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
    expect(find.textContaining(monthName), findsOneWidget);

    // Переключаем на предыдущий месяц.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.textContaining(prevMonthName), findsOneWidget);
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
