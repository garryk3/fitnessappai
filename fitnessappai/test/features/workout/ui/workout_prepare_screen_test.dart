import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/ui/workout_prepare_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_warmup_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

class _FakeWakelock implements WakelockService {
  @override
  bool get isEnabled => true;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ProgramRepository programRepo;
  late ExerciseRepository exerciseRepo;
  late UserProfileRepository profileRepo;

  setUp(() async {
    locator.reset();
    locator.registerLazySingleton<WakelockService>(() => _FakeWakelock());
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('workout_prepare_test');
    programRepo = ProgramRepository(db);
    exerciseRepo = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: (fileType) async => null,
      ),
    );
    profileRepo = UserProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<int> insertExercise(
    String name, {
    ExerciseType type = ExerciseType.strength,
    bool hideOptional = false,
  }) {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: type,
            hideOptional: Value(hideOptional),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        );
  }

  Future<int> createDay({int mainCount = 1, int alternativeCount = 0}) async {
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
      (await programRepo.getExercises(
        day.id!,
      )).first.copyWith(sets: 3, reps: 8, weightKg: 20, restSeconds: 60),
    );
    for (var i = 0; i < alternativeCount; i++) {
      final altExId = await insertExercise('Альт $i');
      await programRepo.addExerciseToDay(day.id!, altExId, isAlternative: true);
    }
    return day.id!;
  }

  Future<void> pumpPrepare(WidgetTester tester, int dayId) async {
    final router = GoRouter(
      initialLocation: '/workout/prepare/$dayId',
      routes: [
        GoRoute(
          path: '/workout/prepare/:programDayId',
          builder: (context, state) => WorkoutPrepareScreen(
            programDayId: int.parse(state.pathParameters['programDayId']!),
            programRepository: programRepo,
            exerciseRepository: exerciseRepo,
            profileRepository: profileRepo,
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) => Scaffold(
            body: Text('run-${state.uri.queryParameters['variant']}'),
          ),
        ),
        GoRoute(
          path: '/workout/warmup',
          builder: (context, state) => WorkoutWarmupScreen(
            programDayId:
                int.tryParse(state.uri.queryParameters['programDayId'] ?? '') ??
                -1,
            warmupSeconds:
                int.tryParse(state.uri.queryParameters['seconds'] ?? '') ?? 0,
            variant: state.uri.queryParameters['variant'] == 'alternative'
                ? WorkoutVariant.alternative
                : WorkoutVariant.main,
            soundService: StubSoundService(),
          ),
        ),
        GoRoute(
          path: '/exercises/:id',
          builder: (context, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
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

  testWidgets('показывает программу и упражнение с параметрами', (
    tester,
  ) async {
    final dayId = await createDay();
    await pumpPrepare(tester, dayId);

    expect(find.text('База'), findsOneWidget);
    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('3 × 8 повт × 20 кг'), findsOneWidget);
    expect(find.text('Отдых 60 с'), findsOneWidget);
    expect(find.text('Начать тренировку'), findsOneWidget);
  });

  testWidgets('hideOptional скрывает параметры и отдых', (tester) async {
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
    final exId = await insertExercise('Приседания', hideOptional: true);
    await programRepo.addExerciseToDay(day.id!, exId);
    await programRepo.updateExercise(
      (await programRepo.getExercises(
        day.id!,
      )).first.copyWith(sets: 3, reps: 8, weightKg: 20, restSeconds: 60),
    );

    await pumpPrepare(tester, day.id!);

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('3 × 8 повт × 20 кг'), findsNothing);
    expect(find.text('Отдых 60 с'), findsNothing);
  });

  testWidgets('переключатель варианта меняет список упражнений', (
    tester,
  ) async {
    final dayId = await createDay(alternativeCount: 1);
    await pumpPrepare(tester, dayId);

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('Альт 0'), findsNothing);

    await tester.tap(find.text('Альтернативный набор'));
    await tester.pumpAndSettle();

    expect(find.text('Приседания'), findsNothing);
    expect(find.text('Альт 0'), findsOneWidget);
  });

  testWidgets('свой вес: параметры без веса', (tester) async {
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
    final exId = await insertExercise(
      'Отжимания',
      type: ExerciseType.bodyweight,
    );
    await programRepo.addExerciseToDay(day.id!, exId);
    await programRepo.updateExercise(
      (await programRepo.getExercises(
        day.id!,
      )).first.copyWith(sets: 3, reps: 15, restSeconds: 45),
    );
    await pumpPrepare(tester, day.id!);

    expect(find.text('3 × 15 повт'), findsOneWidget);
    expect(find.textContaining('кг'), findsNothing);
  });

  testWidgets('переключатель скрыт без альтернативного набора', (tester) async {
    final dayId = await createDay();
    await pumpPrepare(tester, dayId);

    expect(find.text('Альтернативный набор'), findsNothing);
    expect(find.byType(SegmentedButton<WorkoutVariant>), findsNothing);
  });

  testWidgets('старт переходит на тренировку с выбранным вариантом', (
    tester,
  ) async {
    final dayId = await createDay(alternativeCount: 1);
    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('run-main'), findsOneWidget);
  });

  testWidgets('день с разминкой открывает экран разминки перед тренировкой', (
    tester,
  ) async {
    final dayId = await createDay();
    final day = (await programRepo.getDays(dayId)).single;
    await programRepo.updateDay(day.copyWith(warmupMinutes: 5));
    await pumpPrepare(tester, dayId);

    expect(find.textContaining('разминка 5 мин'), findsOneWidget);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Разминка'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
    expect(find.text('run-main'), findsNothing);
  });

  testWidgets('неизвестный день показывает сообщение', (tester) async {
    await pumpPrepare(tester, 999);

    expect(find.text('День не найден'), findsOneWidget);
    expect(find.text('Начать тренировку'), findsNothing);
  });

  testWidgets('показывает диалог предупреждений при пересечении тегов', (
    tester,
  ) async {
    final dayId = await createDay();
    final tagId = (await db.select(db.contraindicationTags).get())
        .firstWhere((t) => t.key == 'knees')
        .id;
    final exerciseId = (await exerciseRepo.getAll()).single.id!;
    await exerciseRepo.setContraindications(exerciseId, [tagId]);
    await profileRepo.setContraindicationTags(['knees']);

    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Противопоказания'), findsOneWidget);
    expect(
      find.text('В программе есть упражнения с противопоказаниями:'),
      findsOneWidget,
    );
    expect(find.text('• Приседания — Колени'), findsOneWidget);

    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('run-main'), findsOneWidget);
  });

  testWidgets('«Отмена» в диалоге предупреждений не запускает тренировку', (
    tester,
  ) async {
    final dayId = await createDay();
    final tagId = (await db.select(db.contraindicationTags).get())
        .firstWhere((t) => t.key == 'knees')
        .id;
    final exerciseId = (await exerciseRepo.getAll()).single.id!;
    await exerciseRepo.setContraindications(exerciseId, [tagId]);
    await profileRepo.setContraindicationTags(['knees']);

    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Начать тренировку'), findsOneWidget);
    expect(find.textContaining('run-'), findsNothing);
  });

  testWidgets('без пересечения с профилем старт без диалога', (tester) async {
    final dayId = await createDay();
    final tagId = (await db.select(db.contraindicationTags).get())
        .firstWhere((t) => t.key == 'knees')
        .id;
    final exerciseId = (await exerciseRepo.getAll()).single.id!;
    await exerciseRepo.setContraindications(exerciseId, [tagId]);

    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Противопоказания'), findsNothing);
    expect(find.text('run-main'), findsOneWidget);
  });

  testWidgets('чекбокс «не показывать» скрывает диалог при повторном старте', (
    tester,
  ) async {
    final dayId = await createDay();
    final tagId = (await db.select(db.contraindicationTags).get())
        .firstWhere((t) => t.key == 'knees')
        .id;
    final exerciseId = (await exerciseRepo.getAll()).single.id!;
    await exerciseRepo.setContraindications(exerciseId, [tagId]);
    await profileRepo.setContraindicationTags(['knees']);

    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
    expect(find.text('Противопоказания'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('run-main'), findsOneWidget);

    final program = (await programRepo.getPrograms()).single;
    expect(await programRepo.isWarningDismissed(program.program.id!), isTrue);

    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Противопоказания'), findsNothing);
    expect(find.text('run-main'), findsOneWidget);
  });

  testWidgets('без чекбокса отметка не сохраняется', (tester) async {
    final dayId = await createDay();
    final tagId = (await db.select(db.contraindicationTags).get())
        .firstWhere((t) => t.key == 'knees')
        .id;
    final exerciseId = (await exerciseRepo.getAll()).single.id!;
    await exerciseRepo.setContraindications(exerciseId, [tagId]);
    await profileRepo.setContraindicationTags(['knees']);

    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    final program = (await programRepo.getPrograms()).single;
    expect(await programRepo.isWarningDismissed(program.program.id!), isFalse);
  });

  testWidgets('тап по карточке упражнения открывает описание', (tester) async {
    final dayId = await createDay();
    final exerciseId = (await exerciseRepo.getAll()).single.id!;

    await pumpPrepare(tester, dayId);

    await tester.tap(find.text('Приседания'));
    await tester.pumpAndSettle();

    expect(find.text('detail $exerciseId'), findsOneWidget);
  });
}
