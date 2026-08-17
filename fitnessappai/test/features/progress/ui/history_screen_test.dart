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

  testWidgets('список сессий: свежие сверху, программа, дата, метрики', (
    tester,
  ) async {
    await workoutRepo.saveSession(
      session(performedDate: DateTime(2026, 8, 10)),
      [setResult(), setResult(name: 'Тяга', setIndex: 2)],
    );
    await workoutRepo.saveSession(
      session(
        performedDate: DateTime(2026, 8, 12),
        programName: 'Кардио',
        variant: WorkoutVariant.alternative,
      ),
      [setResult(name: 'Бег')],
    );

    await pumpHistory(tester);

    final fmt = DateFormat('d MMMM yyyy', 'ru');
    final firstDate = fmt.format(DateTime(2026, 8, 12));
    final secondDate = fmt.format(DateTime(2026, 8, 10));

    expect(find.text('Кардио'), findsOneWidget);
    expect(find.text('База'), findsOneWidget);
    expect(find.text(firstDate), findsOneWidget);
    expect(find.text(secondDate), findsOneWidget);
    expect(find.text('Альтернативный набор'), findsOneWidget);
    expect(find.text('1 упражнение · 40 мин'), findsOneWidget);
    expect(find.text('2 упражнения · 40 мин'), findsOneWidget);

    final firstCenter = tester.getCenter(find.text(firstDate));
    final secondCenter = tester.getCenter(find.text(secondDate));
    expect(firstCenter.dy, lessThan(secondCenter.dy));
  });

  testWidgets('тап по сессии открывает детали с подходами', (tester) async {
    await workoutRepo
        .saveSession(session(performedDate: DateTime(2026, 8, 10)), [
          setResult(reps: 8, weightKg: 20),
          setResult(setIndex: 2, reps: 6, weightKg: 25),
          setResult(
            name: 'Планка',
            type: ExerciseType.plank,
            reps: null,
            weightKg: null,
            durationSeconds: 45,
          ),
          setResult(
            name: 'Бег',
            type: ExerciseType.running,
            reps: null,
            weightKg: null,
            durationSeconds: 900,
            distanceMeters: 3000,
          ),
          setResult(
            name: 'Отжимания',
            type: ExerciseType.bodyweight,
            reps: 15,
            weightKg: null,
            setIndex: 3,
          ),
        ]);

    await pumpHistory(tester);
    await tester.tap(find.text('База'));
    await tester.pumpAndSettle();

    expect(find.text('Детали тренировки'), findsOneWidget);
    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('1. 8 повт × 20 кг'), findsOneWidget);
    expect(find.text('2. 6 повт × 25 кг'), findsOneWidget);
    expect(find.text('1. 45 с'), findsOneWidget);
    expect(find.text('1. 3 км × 15 мин'), findsOneWidget);
    expect(find.text('3. 15 повт'), findsOneWidget);
    expect(find.textContaining('40 мин'), findsOneWidget);
  });

  testWidgets('результаты «по сторонам» помечаются л/п', (tester) async {
    await workoutRepo
        .saveSession(session(performedDate: DateTime(2026, 8, 10)), [
          setResult(setIndex: 1, side: 'left', reps: 8, weightKg: 20),
          setResult(setIndex: 1, side: 'right', reps: 6, weightKg: 20),
          setResult(setIndex: 2, side: 'left', reps: 10, weightKg: 20),
        ]);
    await pumpHistory(tester);
    await tester.tap(find.text('База'));
    await tester.pumpAndSettle();

    expect(find.text('1л. 8 повт × 20 кг'), findsOneWidget);
    expect(find.text('1п. 6 повт × 20 кг'), findsOneWidget);
    expect(find.text('2л. 10 повт × 20 кг'), findsOneWidget);
  });

  testWidgets('пустая история показывает сообщение', (tester) async {
    await pumpHistory(tester);

    expect(find.text('Пока нет тренировок'), findsOneWidget);
  });

  testWidgets('неизвестная сессия показывает сообщение', (tester) async {
    await pumpHistory(tester, location: '/history/999');

    expect(find.text('Тренировка не найдена'), findsOneWidget);
  });

  testWidgets('новая сессия появляется без повторного открытия экрана', (
    tester,
  ) async {
    await pumpHistory(tester);
    expect(find.text('Пока нет тренировок'), findsOneWidget);

    await workoutRepo.saveSession(
      session(performedDate: DateTime(2026, 8, 10)),
      [setResult()],
    );
    await tester.pumpAndSettle();

    expect(find.text('Пока нет тренировок'), findsNothing);
    expect(find.text('База'), findsOneWidget);
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
