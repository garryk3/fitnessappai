import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
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

  Future<Exercise> createExercise(String name, ExerciseType type) {
    return exerciseRepository.create(
      Exercise(
        name: name,
        type: type,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
    );
  }

  Future<Program> createProgram(String name) {
    return programRepository.create(
      Program(
        name: name,
        daysCount: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0)],
    );
  }

  Future<int> addPosition(String exerciseName, ExerciseType type) async {
    final exercise = await createExercise(exerciseName, type);
    final program = await createProgram('Сплит');
    final days = await programRepository.getDays(program.id!);
    final item = await programRepository.addExerciseToDay(
      days[0].id!,
      exercise.id!,
    );
    return item.id!;
  }

  Future<void> pumpParams(WidgetTester tester, int positionId) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramDayExerciseParamsScreen(
          positionId: positionId,
          repository: programRepository,
          exerciseRepository: exerciseRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), value);
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('strength: набор полей по типу', (tester) async {
    final positionId = await addPosition('Жим штанги', ExerciseType.strength);

    await pumpParams(tester, positionId);

    expect(field('Подходы'), findsOneWidget);
    expect(field('Повторения'), findsOneWidget);
    expect(field('Вес (кг)'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Время (сек)'), findsNothing);
    expect(field('Дистанция (км)'), findsNothing);
  });

  testWidgets('plank: набор полей по типу', (tester) async {
    final positionId = await addPosition('Планка', ExerciseType.plank);

    await pumpParams(tester, positionId);

    expect(field('Подходы'), findsOneWidget);
    expect(field('Время (сек)'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Повторения'), findsNothing);
    expect(field('Вес (кг)'), findsNothing);
  });

  testWidgets('running: набор полей по типу', (tester) async {
    final positionId = await addPosition('Бег', ExerciseType.running);

    await pumpParams(tester, positionId);

    expect(field('Время (мин)'), findsOneWidget);
    expect(field('Дистанция (км)'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Подходы'), findsNothing);
    expect(field('Повторения'), findsNothing);
  });

  testWidgets('bodyweight: набор полей по типу', (tester) async {
    final positionId = await addPosition('Отжимания', ExerciseType.bodyweight);

    await pumpParams(tester, positionId);

    expect(field('Подходы'), findsOneWidget);
    expect(field('Повторения'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Вес (кг)'), findsNothing);
    expect(field('Время (сек)'), findsNothing);
  });

  testWidgets('сохранение bodyweight сохраняет повторы без веса', (
    tester,
  ) async {
    final positionId = await addPosition('Отжимания', ExerciseType.bodyweight);

    await pumpParams(tester, positionId);
    await enterField(tester, 'Подходы', '3');
    await enterField(tester, 'Повторения', '15');
    await enterField(tester, 'Отдых (сек)', '45');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final items = await _dayItems(programRepository, positionId);
    expect(items.sets, 3);
    expect(items.reps, 15);
    expect(items.weightKg, isNull);
    expect(items.restSeconds, 45);
  });

  testWidgets('валидация: пустые обязательные поля не сохраняются', (
    tester,
  ) async {
    final positionId = await addPosition('Жим штанги', ExerciseType.strength);

    await pumpParams(tester, positionId);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Заполните поле'), findsNWidgets(2));

    final items = await _dayItems(programRepository, positionId);
    expect(items.sets, isNull);
  });

  testWidgets('сохранение strength сохраняет метрики', (tester) async {
    final positionId = await addPosition('Жим штанги', ExerciseType.strength);

    await pumpParams(tester, positionId);
    await enterField(tester, 'Подходы', '3');
    await enterField(tester, 'Повторения', '10');
    await enterField(tester, 'Вес (кг)', '20.5');
    await enterField(tester, 'Отдых (сек)', '60');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final items = await _dayItems(programRepository, positionId);
    expect(items.sets, 3);
    expect(items.reps, 10);
    expect(items.weightKg, 20.5);
    expect(items.restSeconds, 60);
  });

  testWidgets('running: минуты и километры конвертируются', (tester) async {
    final positionId = await addPosition('Бег', ExerciseType.running);

    await pumpParams(tester, positionId);
    await enterField(tester, 'Время (мин)', '30');
    await enterField(tester, 'Дистанция (км)', '5');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final items = await _dayItems(programRepository, positionId);
    expect(items.durationSeconds, 1800);
    expect(items.distanceMeters, 5000);
    expect(items.sets, 1);
  });

  testWidgets('предзаполнение значениями существующей позиции', (tester) async {
    final exercise = await createExercise('Планка', ExerciseType.plank);
    final program = await createProgram('Сплит');
    final days = await programRepository.getDays(program.id!);
    final item = await programRepository.addExerciseToDay(
      days[0].id!,
      exercise.id!,
    );
    await programRepository.updateExercise(
      item.copyWith(sets: 4, durationSeconds: 45, restSeconds: 90),
    );

    await pumpParams(tester, item.id!);
    expect(
      tester.widget<TextFormField>(field('Подходы')).controller!.text,
      '4',
    );
    expect(
      tester.widget<TextFormField>(field('Время (сек)')).controller!.text,
      '45',
    );
    expect(
      tester.widget<TextFormField>(field('Отдых (сек)')).controller!.text,
      '90',
    );
  });

  testWidgets('значения после сохранения отображаются в списке дня', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);
    final program = await createProgram('Сплит');
    final days = await programRepository.getDays(program.id!);
    await programRepository.addExerciseToDay(days[0].id!, exercise.id!);

    final router = GoRouter(
      initialLocation: '/programs/${program.id}/day/0',
      routes: [
        GoRoute(
          path: '/programs/:id/day/:dayIndex',
          builder: (context, state) => ProgramDayBuilderScreen(
            programId: int.parse(state.pathParameters['id']!),
            dayIndex: int.parse(state.pathParameters['dayIndex']!),
            repository: programRepository,
            exerciseRepository: exerciseRepository,
          ),
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
        routerConfig: router,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Параметры не заданы'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await enterField(tester, 'Подходы', '3');
    await enterField(tester, 'Повторения', '10');
    await enterField(tester, 'Отдых (сек)', '60');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('3 × 10 · отдых 60 с'), findsOneWidget);
  });
}

Future<dynamic> _dayItems(ProgramRepository repository, int positionId) async {
  final dayId = (await repository.getExercise(positionId))!.dayId;
  return (await repository.getExercises(dayId)).first;
}
