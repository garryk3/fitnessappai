import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/ui/exercises_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_exercise_params_screen.dart';
import 'package:fitnessappai/features/programs/ui/programs_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/main.dart' hide main;

const _programName = 'Тест Сплит';
const _squat = 'Тест Приседания';
const _plank = 'Тест Планка';
const _running = 'Тест Бег';

String weekdayLabel(int weekday) => switch (weekday) {
  1 => 'Пн',
  2 => 'Вт',
  3 => 'Ср',
  4 => 'Чт',
  5 => 'Пт',
  6 => 'Сб',
  7 => 'Вс',
  _ => '',
};

int day2Weekday(int today) =>
    today == DateTime.sunday ? DateTime.saturday : today + 1;

Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
  locator.reset();
  registerCoreServices(locator, database: db);
  await tester.pumpWidget(const FitnessAppAi());
  await tester.pumpAndSettle();
}

Future<void> goToTab(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pumpAndSettle();
}

Future<void> ensureFieldVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> enterField(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await ensureFieldVisible(tester, finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> pullToRefreshExercises(WidgetTester tester) async {
  final list = find.descendant(
    of: find.byType(ExercisesScreen),
    matching: find.byType(ListView),
  );
  await tester.fling(list, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
}

Future<void> pullToRefreshPrograms(WidgetTester tester) async {
  final list = find.descendant(
    of: find.byType(ProgramsScreen),
    matching: find.byType(ListView),
  );
  await tester.fling(list, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
}

Future<void> createExercise(
  WidgetTester tester,
  String name,
  ExerciseType type, {
  String? contraindication,
}) async {
  await tester.tap(find.byTooltip('Новое упражнение'));
  await tester.pumpAndSettle();

  await enterField(
    tester,
    find.widgetWithText(TextFormField, 'Название'),
    name,
  );

  final typeDropdown = find.byType(DropdownButtonFormField<ExerciseType>);
  await ensureFieldVisible(tester, typeDropdown);
  await tester.tap(typeDropdown);
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(switch (type) {
      ExerciseType.strength => 'Силовые',
      ExerciseType.plank => 'Планка',
      ExerciseType.running => 'Бег',
    }).last,
  );
  await tester.pumpAndSettle();

  if (contraindication != null) {
    final chip = find.text(contraindication);
    await tester.scrollUntilVisible(
      chip,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
  await tester.pumpAndSettle();
}

Future<void> addDayExercise(
  WidgetTester tester,
  String name,
  Map<String, String> params,
) async {
  final fab = find.descendant(
    of: find.byType(ProgramDayBuilderScreen),
    matching: find.byTooltip('Добавить упражнение'),
  );
  await tester.tap(fab);
  await tester.pumpAndSettle();

  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text(name)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(ListTile, name));
  await tester.pumpAndSettle();

  for (final entry in params.entries) {
    await enterField(
      tester,
      find.widgetWithText(TextFormField, entry.key),
      entry.value,
    );
  }

  final save = find.descendant(
    of: find.byType(ProgramDayExerciseParamsScreen),
    matching: find.widgetWithText(FilledButton, 'Сохранить'),
  );
  await ensureFieldVisible(tester, save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> selectWeekday(WidgetTester tester, String label) async {
  final dialog = find.byType(AlertDialog);
  final dropdown = find.descendant(
    of: dialog,
    matching: find.byType(DropdownButtonFormField<int?>),
  );
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();

  final save = find.descendant(
    of: dialog,
    matching: find.widgetWithText(FilledButton, 'Сохранить'),
  );
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> configureDay(
  WidgetTester tester,
  int dayIndex,
  int weekday, {
  required List<(String, Map<String, String>)> mainSets,
  required List<(String, Map<String, String>)> alternativeSets,
}) async {
  await tester.tap(find.text('День $dayIndex'));
  await tester.pumpAndSettle();
  await selectWeekday(tester, weekdayLabel(weekday));

  await tester.tap(find.byIcon(Icons.playlist_add).at(dayIndex - 1));
  await tester.pumpAndSettle();

  for (final (name, params) in mainSets) {
    await addDayExercise(tester, name, params);
  }
  if (alternativeSets.isNotEmpty) {
    await tester.tap(find.text('Альтернативный набор'));
    await tester.pumpAndSettle();
    for (final (name, params) in alternativeSets) {
      await addDayExercise(tester, name, params);
    }
  }

  final save = find.descendant(
    of: find.byType(ProgramDayBuilderScreen),
    matching: find.widgetWithText(FilledButton, 'Сохранить'),
  );
  await ensureFieldVisible(tester, save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> completeStrengthSet(
  WidgetTester tester, {
  required String repeats,
  required String weight,
}) async {
  await enterField(
    tester,
    find.widgetWithText(TextFormField, 'Повторения'),
    repeats,
  );
  await enterField(
    tester,
    find.widgetWithText(TextFormField, 'Вес (кг)'),
    weight,
  );
  final done = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, done);
  await tester.tap(done);
  await tester.pump();
}

Future<void> completePlankSet(
  WidgetTester tester, {
  required String seconds,
}) async {
  await enterField(
    tester,
    find.widgetWithText(TextFormField, 'Время (сек)'),
    seconds,
  );
  final done = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, done);
  await tester.tap(done);
  await tester.pump();
}

Future<void> completeRunningSet(
  WidgetTester tester, {
  required String minutes,
  required String distance,
}) async {
  await enterField(
    tester,
    find.widgetWithText(TextFormField, 'Время (мин)'),
    minutes,
  );
  await enterField(
    tester,
    find.widgetWithText(TextFormField, 'Дистанция (км)'),
    distance,
  );
  final done = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, done);
  await tester.tap(done);
  await tester.pump();
}

Future<void> skipRestIfShown(WidgetTester tester) async {
  final skip = find.widgetWithText(FilledButton, 'Пропустить отдых');
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await tester.pumpAndSettle();
  }
}

Future<void> finishAndGoProgress(WidgetTester tester) async {
  expect(find.text('Тренировка завершена'), findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton, 'Завершить тренировку'));
  await tester.pumpAndSettle();
  expect(find.text('Тренировка сохранена'), findsOneWidget);
  await tester.tap(find.text('К прогрессу'));
  await tester.pumpAndSettle();
}

Future<void> expectWorkoutCount(WidgetTester tester, String count) async {
  final card = find.ancestor(
    of: find.text('Тренировок'),
    matching: find.byType(Card),
  );
  expect(card, findsOneWidget);
  expect(find.descendant(of: card, matching: find.text(count)), findsOneWidget);
}

Future<void> reloadWeekPlan(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Предыдущий месяц'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Следующий месяц'));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('полный флоу: упражнения, программа, основная тренировка', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);
    expect(find.text(_squat), findsOneWidget);

    await createExercise(tester, _plank, ExerciseType.plank);
    await pullToRefreshExercises(tester);
    expect(find.text(_plank), findsOneWidget);

    await createExercise(tester, _running, ExerciseType.running);
    await pullToRefreshExercises(tester);
    expect(find.text(_running), findsOneWidget);

    final today = DateTime.now().weekday;
    final tomorrow = day2Weekday(today);

    await goToTab(tester, Icons.calendar_month_outlined);
    await tester.tap(find.byTooltip('Новая программа'));
    await tester.pumpAndSettle();
    await enterField(
      tester,
      find.widgetWithText(TextFormField, 'Название'),
      _programName,
    );

    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await configureDay(
      tester,
      1,
      today,
      mainSets: [
        (
          _squat,
          {
            'Подходы': '1',
            'Повторения': '10',
            'Вес (кг)': '40',
            'Отдых (сек)': '10',
          },
        ),
        (_plank, {'Подходы': '1', 'Время (сек)': '30', 'Отдых (сек)': '10'}),
        (
          _running,
          {'Время (мин)': '20', 'Дистанция (км)': '5', 'Отдых (сек)': '10'},
        ),
      ],
      alternativeSets: [
        (
          _squat,
          {
            'Подходы': '1',
            'Повторения': '12',
            'Вес (кг)': '50',
            'Отдых (сек)': '10',
          },
        ),
      ],
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await configureDay(
      tester,
      2,
      tomorrow,
      mainSets: [
        (
          _running,
          {'Время (мин)': '15', 'Дистанция (км)': '3', 'Отдых (сек)': '10'},
        ),
      ],
      alternativeSets: const [],
    );

    final programSave = find.descendant(
      of: find.byType(ProgramBuilderScreen),
      matching: find.widgetWithText(FilledButton, 'Сохранить'),
    );
    await ensureFieldVisible(tester, programSave);
    await tester.tap(programSave);
    await tester.pumpAndSettle();
    await pullToRefreshPrograms(tester);
    expect(find.text(_programName), findsOneWidget);

    await goToTab(tester, Icons.event_note_outlined);
    expect(find.text(_programName), findsWidgets);

    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Начать тренировку'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text(_squat), findsOneWidget);
    await completeStrengthSet(tester, repeats: '10', weight: '40');
    await skipRestIfShown(tester);

    await completePlankSet(tester, seconds: '30');
    await skipRestIfShown(tester);

    await completeRunningSet(tester, minutes: '20', distance: '5');
    await skipRestIfShown(tester);

    await finishAndGoProgress(tester);

    await expectWorkoutCount(tester, '1');

    final sessions = await locator.get<WorkoutRepository>().getAllSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.programName, _programName);
    expect(sessions.single.variant, WorkoutVariant.main);
    final detail = await locator.get<WorkoutRepository>().getSession(
      sessions.single.id!,
    );
    expect(detail, isNotNull);
    expect(detail!.results, hasLength(3));
  });

  testWidgets('флоу: перенос дня и тренировка альтернативного набора', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);
    await createExercise(tester, _running, ExerciseType.running);
    await pullToRefreshExercises(tester);

    final today = DateTime.now().weekday;
    final tomorrow = day2Weekday(today);

    await goToTab(tester, Icons.calendar_month_outlined);
    await tester.tap(find.byTooltip('Новая программа'));
    await tester.pumpAndSettle();
    await enterField(
      tester,
      find.widgetWithText(TextFormField, 'Название'),
      _programName,
    );

    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await configureDay(
      tester,
      1,
      today,
      mainSets: [
        (
          _squat,
          {
            'Подходы': '1',
            'Повторения': '10',
            'Вес (кг)': '40',
            'Отдых (сек)': '10',
          },
        ),
      ],
      alternativeSets: const [],
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await configureDay(
      tester,
      2,
      tomorrow,
      mainSets: [
        (
          _running,
          {'Время (мин)': '15', 'Дистанция (км)': '3', 'Отдых (сек)': '10'},
        ),
      ],
      alternativeSets: [
        (
          _squat,
          {
            'Подходы': '1',
            'Повторения': '12',
            'Вес (кг)': '50',
            'Отдых (сек)': '10',
          },
        ),
      ],
    );

    final programSave = find.descendant(
      of: find.byType(ProgramBuilderScreen),
      matching: find.widgetWithText(FilledButton, 'Сохранить'),
    );
    await ensureFieldVisible(tester, programSave);
    await tester.tap(programSave);
    await tester.pumpAndSettle();
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Перенести на сегодня'), findsOneWidget);

    await tester.tap(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Альтернативный набор'));
    await tester.pumpAndSettle();
    expect(find.text(_squat), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    await completeStrengthSet(tester, repeats: '12', weight: '50');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);

    await expectWorkoutCount(tester, '1');

    final sessions = await locator.get<WorkoutRepository>().getAllSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.programName, _programName);
    expect(sessions.single.variant, WorkoutVariant.alternative);
    final detail = await locator.get<WorkoutRepository>().getSession(
      sessions.single.id!,
    );
    expect(detail, isNotNull);
    expect(detail!.results, hasLength(1));
    expect(detail.results.single.reps, 12);
    expect(detail.results.single.weightKg, 50);
  });

  testWidgets('противопоказания: предупреждение при старте и продолжение', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.person_outline);
    final healthLink = find.text('Противопоказания');
    await ensureFieldVisible(tester, healthLink);
    await tester.tap(healthLink);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Колени'));
    await tester.pumpAndSettle();
    final saveHealth = find.widgetWithText(FilledButton, 'Сохранить');
    await ensureFieldVisible(tester, saveHealth);
    await tester.tap(saveHealth);
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(
      tester,
      _squat,
      ExerciseType.strength,
      contraindication: 'Колени',
    );
    await pullToRefreshExercises(tester);
    expect(find.text(_squat), findsOneWidget);

    final today = DateTime.now().weekday;

    await goToTab(tester, Icons.calendar_month_outlined);
    await tester.tap(find.byTooltip('Новая программа'));
    await tester.pumpAndSettle();
    await enterField(
      tester,
      find.widgetWithText(TextFormField, 'Название'),
      _programName,
    );

    await configureDay(
      tester,
      1,
      today,
      mainSets: [
        (
          _squat,
          {
            'Подходы': '1',
            'Повторения': '10',
            'Вес (кг)': '40',
            'Отдых (сек)': '10',
          },
        ),
      ],
      alternativeSets: const [],
    );

    final programSave = find.descendant(
      of: find.byType(ProgramBuilderScreen),
      matching: find.widgetWithText(FilledButton, 'Сохранить'),
    );
    await ensureFieldVisible(tester, programSave);
    await tester.tap(programSave);
    await tester.pumpAndSettle();
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Противопоказания'), findsOneWidget);
    expect(find.text('• Тест Приседания — Колени'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Продолжить'));
    await tester.pumpAndSettle();

    await completeStrengthSet(tester, repeats: '10', weight: '40');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);
    await expectWorkoutCount(tester, '1');
  });

  testWidgets('план недели: пропуск, отмена пропуска и перенос дня', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await createExercise(tester, _running, ExerciseType.running);
    await pullToRefreshExercises(tester);

    final tomorrow = day2Weekday(DateTime.now().weekday);

    await goToTab(tester, Icons.calendar_month_outlined);
    await tester.tap(find.byTooltip('Новая программа'));
    await tester.pumpAndSettle();
    await enterField(
      tester,
      find.widgetWithText(TextFormField, 'Название'),
      _programName,
    );

    await configureDay(
      tester,
      1,
      tomorrow,
      mainSets: [
        (
          _running,
          {'Время (мин)': '15', 'Дистанция (км)': '3', 'Отдых (сек)': '10'},
        ),
      ],
      alternativeSets: const [],
    );

    final programSave = find.descendant(
      of: find.byType(ProgramBuilderScreen),
      matching: find.widgetWithText(FilledButton, 'Сохранить'),
    );
    await ensureFieldVisible(tester, programSave);
    await tester.tap(programSave);
    await tester.pumpAndSettle();
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    expect(find.text('Запланировано'), findsOneWidget);
    expect(find.text('Перенести на сегодня'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();
    expect(find.text('Пропущено'), findsOneWidget);
    expect(find.text('Отменить пропуск'), findsOneWidget);

    await tester.tap(find.text('Отменить пропуск'));
    await tester.pumpAndSettle();
    expect(find.text('Запланировано'), findsOneWidget);

    await tester.tap(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    await completeRunningSet(tester, minutes: '15', distance: '3');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);
    await expectWorkoutCount(tester, '1');

    await goToTab(tester, Icons.event_note_outlined);
    await reloadWeekPlan(tester);
    expect(find.text('Перенесено'), findsOneWidget);
  });
}
