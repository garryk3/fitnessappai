import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_day_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_exercise_params_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepository;
  late ExerciseRepository exerciseRepository;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepository = ProgramRepository(db);
    exerciseRepository = ExerciseRepository(db, MediaStore());
    addTearDown(() => db.close());
  });

  Future<int> muscleId(String key) async {
    final groups = await exerciseRepository.getAllMuscleGroups();
    return groups.firstWhere((g) => g.key == key).id!;
  }

  Future<Exercise> createExercise(
    String name,
    ExerciseType type, {
    List<int> muscles = const [],
  }) {
    return exerciseRepository.create(
      Exercise(
        name: name,
        type: type,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [
        for (final id in muscles)
          ExerciseMuscle(
            exerciseId: 0,
            muscleGroupId: id,
            intensity: MuscleIntensity.primary,
          ),
      ],
    );
  }

  Future<Program> createProgram(String name, int daysCount) {
    return programRepository.create(
      Program(
        name: name,
        daysCount: daysCount,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [
        for (var i = 0; i < daysCount; i++)
          ProgramDay(programId: 0, dayIndex: i),
      ],
    );
  }

  Future<void> addValidExercise(int dayId, int exerciseId) async {
    final item = await programRepository.addExerciseToDay(dayId, exerciseId);
    await programRepository.updateExercise(
      item.copyWith(sets: 3, reps: 10, weightKg: 20, restSeconds: 60),
    );
  }

  Future<void> pumpDayBuilder(
    WidgetTester tester, {
    required int programId,
    int dayIndex = 0,
  }) async {
    final router = GoRouter(
      initialLocation: '/programs/$programId/edit/day/$dayIndex',
      routes: [
        GoRoute(
          path: '/programs/:id/edit',
          builder: (context, state) => const Scaffold(body: SizedBox()),
          routes: [
            GoRoute(
              path: 'day/:dayIndex',
              builder: (context, state) => ProgramDayBuilderScreen(
                programId: int.parse(state.pathParameters['id']!),
                dayIndex: int.parse(state.pathParameters['dayIndex']!),
                repository: programRepository,
                exerciseRepository: exerciseRepository,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/program-day/:id/exercise-params',
          builder: (context, state) => ProgramDayExerciseParamsScreen(
            positionId: int.parse(state.pathParameters['id']!),
            repository: programRepository,
            exerciseRepository: exerciseRepository,
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

  Future<void> addExercise(WidgetTester tester, String name) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  Future<void> closeParams(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  Future<void> addAndSaveStrength(
    WidgetTester tester,
    String name, {
    int sets = 3,
    int reps = 10,
  }) async {
    await addExercise(tester, name);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Подходы'),
      '$sets',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Повторения'),
      '$reps',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();
  }

  List<String> tileTitles(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => (tile.title as Text).data!)
      .toList();

  testWidgets('отображает упражнения сохранённого дня и прогресс', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final program = await createProgram('Сплит', 1);
    final days = await programRepository.getDays(program.id!);
    await addValidExercise(days[0].id!, exercise.id!);

    await pumpDayBuilder(tester, programId: program.id!);

    expect(find.text('День 1'), findsOneWidget);
    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Заполнено 1 из 1 дней'), findsOneWidget);
    expect(find.text('3 × 10 · 20 кг · отдых 60 с'), findsOneWidget);
  });

  testWidgets('сводка bodyweight без веса', (tester) async {
    final exercise = await createExercise('Отжимания', ExerciseType.bodyweight);
    final program = await createProgram('Сплит', 1);
    final days = await programRepository.getDays(program.id!);
    final item = await programRepository.addExerciseToDay(
      days[0].id!,
      exercise.id!,
    );
    await programRepository.updateExercise(
      item.copyWith(sets: 3, reps: 15, restSeconds: 45),
    );

    await pumpDayBuilder(tester, programId: program.id!);

    expect(find.text('Отжимания'), findsOneWidget);
    expect(find.text('3 × 15 · отдых 45 с'), findsOneWidget);
    expect(find.textContaining('кг'), findsNothing);
  });

  testWidgets(
    'добавление упражнения и выход без сохранения — упражнение не добавляется',
    (tester) async {
      final program = await createProgram('Сплит', 1);
      await createExercise('Приседания', ExerciseType.strength);

      await pumpDayBuilder(tester, programId: program.id!);
      expect(find.text('В этом дне пока нет упражнений'), findsOneWidget);

      await addExercise(tester, 'Приседания');

      expect(find.text('Параметры упражнения'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Подходы'), findsOneWidget);

      await closeParams(tester);

      expect(find.text('Приседания'), findsNothing);
      expect(find.text('Параметры не заданы'), findsNothing);
      expect(find.text('В этом дне пока нет упражнений'), findsOneWidget);

      final days = await programRepository.getDays(program.id!);
      final exercises = await programRepository.getExercises(days[0].id!);
      expect(exercises, isEmpty);
    },
  );

  testWidgets(
    'добавление упражнения и сохранение параметров — упражнение остаётся',
    (tester) async {
      final program = await createProgram('Сплит', 1);
      await createExercise('Приседания', ExerciseType.strength);

      await pumpDayBuilder(tester, programId: program.id!);
      await addExercise(tester, 'Приседания');

      expect(find.text('Параметры упражнения'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Подходы'),
        '3',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Повторения'),
        '10',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('Приседания'), findsOneWidget);
      expect(find.text('Параметры не заданы'), findsNothing);

      final days = await programRepository.getDays(program.id!);
      final exercises = await programRepository.getExercises(days[0].id!);
      expect(exercises, hasLength(1));
      expect(exercises.single.sets, 3);
      expect(exercises.single.reps, 10);
    },
  );

  testWidgets('альтернативный набор редактируется отдельно', (tester) async {
    final program = await createProgram('Сплит', 1);
    await createExercise('Приседания', ExerciseType.strength);
    await createExercise('Рывок гири', ExerciseType.strength);

    await pumpDayBuilder(tester, programId: program.id!);
    await addAndSaveStrength(tester, 'Приседания');

    await tester.tap(find.text('Альтернативный набор'));
    await tester.pumpAndSettle();
    await addAndSaveStrength(tester, 'Рывок гири');

    expect(find.text('Рывок гири'), findsOneWidget);
    expect(find.text('Приседания'), findsNothing);

    await tester.tap(find.text('Основной набор'));
    await tester.pumpAndSettle();
    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('Рывок гири'), findsNothing);
  });

  testWidgets('удаление упражнения из дня', (tester) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final program = await createProgram('Сплит', 1);
    final days = await programRepository.getDays(program.id!);
    await addValidExercise(days[0].id!, exercise.id!);

    await pumpDayBuilder(tester, programId: program.id!);
    expect(find.text('Жим штанги'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsNothing);
    expect(find.text('В этом дне пока нет упражнений'), findsOneWidget);
  });

  testWidgets('реордер упражнений дня', (tester) async {
    final squat = await createExercise('Приседания', ExerciseType.strength);
    final press = await createExercise('Жим штанги', ExerciseType.strength);
    final program = await createProgram('Сплит', 1);
    final days = await programRepository.getDays(program.id!);
    await addValidExercise(days[0].id!, squat.id!);
    await addValidExercise(days[0].id!, press.id!);

    await pumpDayBuilder(tester, programId: program.id!);
    expect(tileTitles(tester), ['Приседания', 'Жим штанги']);

    await tester.timedDrag(
      find.byIcon(Icons.drag_indicator).first,
      const Offset(0, 120),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(tileTitles(tester), ['Жим штанги', 'Приседания']);
  });

  testWidgets('невалидные позиции блокируют сохранение', (tester) async {
    final exercise = await createExercise('Приседания', ExerciseType.strength);
    final program = await createProgram('Сплит', 1);
    final days = await programRepository.getDays(program.id!);
    await programRepository.addExerciseToDay(days[0].id!, exercise.id!);

    await pumpDayBuilder(tester, programId: program.id!);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(
      find.text('Укажите параметры упражнения перед сохранением'),
      findsOneWidget,
    );
    final detail = await programRepository.getProgram(program.id!);
    final items = detail!.days[0].mainExercises;
    expect(items, hasLength(1));
    expect(items.single.sets, isNull);
    expect(items.single.reps, isNull);
  });

  testWidgets('сохранение валидного дня сохраняет упражнения', (tester) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final program = await createProgram('Сплит', 1);
    final days = await programRepository.getDays(program.id!);
    await addValidExercise(days[0].id!, exercise.id!);

    await pumpDayBuilder(tester, programId: program.id!);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final detail = await programRepository.getProgram(program.id!);
    final items = detail!.days[0].mainExercises;
    expect(items, hasLength(1));
    expect(items.single.exerciseId, exercise.id);
    expect(items.single.sets, 3);
  });

  testWidgets('пустой день в другой позиции не блокирует сохранение текущего', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final program = await createProgram('Сплит', 2);
    final days = await programRepository.getDays(program.id!);
    await addValidExercise(days[0].id!, exercise.id!);

    await pumpDayBuilder(tester, programId: program.id!, dayIndex: 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Недостаточно данных для сохранения'), findsNothing);
    expect(find.byType(ProgramDayBuilderScreen), findsNothing);

    final detail = await programRepository.getProgram(program.id!);
    expect(detail!.days[0].mainExercises, hasLength(1));
    expect(detail.days[1].mainExercises, isEmpty);
  });

  testWidgets('новое упражнение: параметры задаются сразу и день сохраняется', (
    tester,
  ) async {
    final exercise = await createExercise('Приседания', ExerciseType.strength);
    final program = await createProgram('Сплит', 1);

    await pumpDayBuilder(tester, programId: program.id!);

    await addExercise(tester, 'Приседания');

    expect(find.text('Параметры упражнения'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Подходы'), '3');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Повторения'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Вес (кг)'),
      '20',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Отдых (сек)'),
      '60',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Параметры упражнения'), findsNothing);
    expect(find.text('Приседания'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final detail = await programRepository.getProgram(program.id!);
    final items = detail!.days[0].mainExercises;
    expect(items, hasLength(1));
    expect(items.single.exerciseId, exercise.id);
    expect(items.single.sets, 3);
    expect(items.single.reps, 10);
  });

  testWidgets('фильтр диалога выбора по мышечной группе', (tester) async {
    final chest = await muscleId('chest');
    final quads = await muscleId('quads');
    await createExercise('Жим штанги', ExerciseType.strength, muscles: [chest]);
    await createExercise('Приседания', ExerciseType.strength, muscles: [quads]);
    final program = await createProgram('Сплит', 1);

    await pumpDayBuilder(tester, programId: program.id!);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Приседания'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<MuscleGroup?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Грудь').last);
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Приседания'), findsNothing);
  });

  testWidgets('фильтр диалога выбора по категории', (tester) async {
    await createExercise('Жим штанги', ExerciseType.strength);
    await createExercise('Подтягивания', ExerciseType.bodyweight);
    await createExercise('Бег трусцой', ExerciseType.running);
    final program = await createProgram('Сплит', 1);

    await pumpDayBuilder(tester, programId: program.id!);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Подтягивания'), findsOneWidget);
    expect(find.text('Бег трусцой'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<ExerciseType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бег').last);
    await tester.pumpAndSettle();

    expect(find.text('Бег трусцой'), findsOneWidget);
    expect(find.text('Жим штанги'), findsNothing);
    expect(find.text('Подтягивания'), findsNothing);
  });

  testWidgets('фильтр выбора: категория комбинируется с мышцами', (
    tester,
  ) async {
    final chest = await muscleId('chest');
    final quads = await muscleId('quads');
    await createExercise('Жим штанги', ExerciseType.strength, muscles: [chest]);
    await createExercise('Приседания', ExerciseType.strength, muscles: [quads]);
    await createExercise('Бег трусцой', ExerciseType.running, muscles: [chest]);
    final program = await createProgram('Сплит', 1);

    await pumpDayBuilder(tester, programId: program.id!);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<MuscleGroup?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Грудь').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<ExerciseType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Силовые').last);
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Бег трусцой'), findsNothing);
    expect(find.text('Приседания'), findsNothing);
  });

  testWidgets('чекбокс «Только свои упражнения» фильтрует список', (
    tester,
  ) async {
    final program = await createProgram('Сплит', 1);
    await createExercise('Жим штанги', ExerciseType.strength);
    await exerciseRepository.create(
      Exercise(
        name: 'Мой жим',
        type: ExerciseType.strength,
        isCustom: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
    );

    await pumpDayBuilder(tester, programId: program.id!);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Мой жим'), findsOneWidget);

    await tester.tap(find.text('Только свои упражнения'));
    await tester.pumpAndSettle();

    expect(find.text('Мой жим'), findsOneWidget);
    expect(find.text('Жим штанги'), findsNothing);
  });

  testWidgets('список выбора упражнения содержит разделители', (tester) async {
    final program = await createProgram('Сплит', 1);
    await createExercise('Жим штанги', ExerciseType.strength);
    await createExercise('Приседания', ExerciseType.strength);

    await pumpDayBuilder(tester, programId: program.id!);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('Сохранить заблокирован, пока в дне нет упражнений', (
    tester,
  ) async {
    final program = await createProgram('Сплит', 1);
    await createExercise('Жим штанги', ExerciseType.strength);

    await pumpDayBuilder(tester, programId: program.id!);

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Сохранить'),
    );
    expect(saveButton().onPressed, isNull);

    await addExercise(tester, 'Жим штанги');
    await tester.pumpAndSettle();

    expect(saveButton().onPressed, isNotNull);
  });
}
