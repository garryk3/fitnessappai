import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/ui/exercises_screen.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/programs/ui/program_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_exercise_params_screen.dart';
import 'package:fitnessappai/features/programs/ui/programs_screen.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
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

Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  bool stubPlatformServices = false,
  bool disableWakelock = false,
}) async {
  locator.reset();
  registerCoreServices(locator, database: db);
  locator.registerLazySingleton<SoundService>(() => StubSoundService());
  locator.registerLazySingleton<WakelockService>(
    () => disableWakelock
        ? _StubWakelockDisabledService()
        : _StubWakelockService(),
  );
  if (stubPlatformServices) {
    locator.registerLazySingleton<UpdateService>(() => _StubUpdateService());
    locator.registerLazySingleton<SyncService>(() => _StubSyncService());
  }
  await tester.pumpWidget(const FitnessAppAi());
  await tester.pumpAndSettle();
}

class _StubWakelockService implements WakelockService {
  @override
  bool get isEnabled => true;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

class _StubWakelockDisabledService implements WakelockService {
  @override
  bool get isEnabled => false;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

class _StubUpdateService implements UpdateService {
  @override
  Future<ReleaseInfo?> fetchLatestRelease() async => null;
}

class _StubSyncService implements SyncService {
  @override
  Future<String> export() async => 'stub-export.sqlite';

  @override
  Future<void> import(String sourcePath) async {
    throw UnimplementedError('import заглушен в e2e');
  }
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 200,
  String label = '',
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw StateError('Widget not found after $maxPumps pumps: $label');
}

Future<void> goToTab(WidgetTester tester, IconData icon) async {
  final navFinder = find.byType(NavigationBar);
  Finder? tabIcon;
  if (navFinder.evaluate().isNotEmpty) {
    tabIcon =
        _navIconIn(navFinder, icon) ?? _navIconIn(navFinder, _filledIcon(icon));
  } else {
    final railFinder = find.byType(NavigationRail);
    tabIcon =
        _navIconIn(railFinder, icon) ??
        _navIconIn(railFinder, _filledIcon(icon));
  }
  await tester.tap(tabIcon!.first);
  await tester.pumpAndSettle();
}

Finder? _navIconIn(Finder container, IconData icon) {
  final found = find.descendant(
    of: container,
    matching: find.byWidgetPredicate((w) => w is Icon && w.icon == icon),
  );
  return found.evaluate().isEmpty ? null : found;
}

IconData _filledIcon(IconData outlined) => switch (outlined) {
  Icons.home_outlined => Icons.home,
  Icons.fitness_center_outlined => Icons.fitness_center,
  Icons.calendar_month_outlined => Icons.calendar_month,
  Icons.event_note_outlined => Icons.event_note,
  Icons.bar_chart_outlined => Icons.bar_chart,
  Icons.person_outline => Icons.person,
  _ => outlined,
};

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

Future<void> enterWorkoutField(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await ensureFieldVisible(tester, finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> pullToRefreshExercises(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(ExercisesScreen),
      matching: find.byType(ListView),
    );
    if (list.evaluate().isNotEmpty) {
      await tester.fling(list, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      return;
    }
  }
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
  bool fixedWeight = false,
  bool perSide = false,
}) async {
  await tester.tap(find.byTooltip('Новое упражнение'));
  await tester.pumpAndSettle();

  final nameFinder = find.byType(TextFormField).first;

  await enterField(tester, nameFinder, name);

  final typeDropdown = find.byType(DropdownButtonFormField<ExerciseType>);
  await ensureFieldVisible(tester, typeDropdown);
  await tester.tap(typeDropdown);
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(switch (type) {
      ExerciseType.strength => 'Силовые',
      ExerciseType.bodyweight => 'Свой вес',
      ExerciseType.plank => 'Время',
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

  final primaryChip = find.text('Основная').first;
  await tester.scrollUntilVisible(
    primaryChip,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(primaryChip);
  await tester.pumpAndSettle();
  await tester.tap(primaryChip);
  await tester.pumpAndSettle();

  if (fixedWeight) {
    await _toggleFormCheckbox(tester, 'Фиксированный вес');
  }
  if (perSide) {
    await _toggleFormCheckbox(tester, 'Выполнение по сторонам (левая/правая)');
  }

  await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
  await tester.pumpAndSettle();
}

Future<void> _toggleFormCheckbox(WidgetTester tester, String label) async {
  final checkbox = find.widgetWithText(CheckboxListTile, label);
  await tester.scrollUntilVisible(
    checkbox,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(checkbox);
  await tester.pumpAndSettle();
  await tester.tap(checkbox);
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
  int? weekday, {
  required List<(String, Map<String, String>)> mainSets,
  required List<(String, Map<String, String>)> alternativeSets,
}) async {
  final dayLabel = find.text('День $dayIndex');
  await tester.scrollUntilVisible(
    dayLabel,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();

  final dayCard = find.ancestor(of: dayLabel, matching: find.byType(Card));
  if (weekday != null) {
    await tester.tap(
      find.descendant(of: dayCard, matching: find.byIcon(Icons.tune)),
    );
    await tester.pumpAndSettle();
    await selectWeekday(tester, weekdayLabel(weekday));
  }

  await tester.tap(dayLabel);
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

Future<void> enterWarmup(WidgetTester tester, String minutes) async {
  await enterField(
    tester,
    find.widgetWithText(TextFormField, 'Разминка, мин'),
    minutes,
  );
}

/// Закрывает попап «Сделать программу активной?», если он появился.
Future<void> dismissActivatePopupIfShown(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final dialog = find.byType(AlertDialog);
  if (dialog.evaluate().isNotEmpty) {
    final cancel = find.descendant(
      of: dialog,
      matching: find.byType(TextButton),
    );
    if (cancel.evaluate().isNotEmpty) {
      await tester.tap(cancel.first);
      await tester.pumpAndSettle();
    }
  }
}

/// Нажимает «Сохранить» в конструкторе программы и закрывает попап активации.
Future<void> saveProgramBuilder(WidgetTester tester) async {
  final programSave = find.descendant(
    of: find.byType(ProgramBuilderScreen),
    matching: find.widgetWithText(FilledButton, 'Сохранить'),
  );
  await tester.tap(programSave);
  // Ждём появления попапа (асинхронный сохранение в БД).
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    final dialog = find.byType(AlertDialog);
    if (dialog.evaluate().isNotEmpty) {
      final activate = find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, 'Сделать активной'),
      );
      if (activate.evaluate().isNotEmpty) {
        await tester.tap(activate.first);
        await tester.pumpAndSettle();
        return;
      }
    }
  }
  // Если попап не появился — просто дожидаемся стабилизации.
  await tester.pumpAndSettle();
}

/// Запускает тренировку из плана недели: «Начать» → подготовка →
/// «Начать тренировку» → (диалог противопоказаний) → (разминка).
///
/// После завершения тест остаётся на экране выполнения первого упражнения.
Future<void> startWorkout(
  WidgetTester tester, {
  bool expectContraindications = false,
  int? warmupMinutes,
}) async {
  await tester.tap(find.text('Начать'));
  await tester.pumpAndSettle();

  final startWorkoutBtn = find.widgetWithText(
    FilledButton,
    'Начать тренировку',
  );
  await pumpUntilFound(tester, startWorkoutBtn);
  await tester.tap(startWorkoutBtn);
  await tester.pumpAndSettle();

  if (expectContraindications) {
    final dialog = find.text('Противопоказания');
    await pumpUntilFound(tester, dialog);
    await tester.tap(find.widgetWithText(FilledButton, 'Продолжить'));
    await tester.pumpAndSettle();
  }

  if (warmupMinutes != null) {
    await pumpUntilFound(
      tester,
      find.widgetWithText(OutlinedButton, 'Пропустить'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Пропустить'));
    await tester.pumpAndSettle();
  }
}

Future<void> completeStrengthSet(
  WidgetTester tester, {
  required String repeats,
  required String weight,
}) async {
  await enterWorkoutField(
    tester,
    find.widgetWithText(TextFormField, 'Повторения'),
    repeats,
  );
  await enterWorkoutField(
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
  await enterWorkoutField(
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
  await enterWorkoutField(
    tester,
    find.widgetWithText(TextFormField, 'Время (мин)'),
    minutes,
  );
  await enterWorkoutField(
    tester,
    find.widgetWithText(TextFormField, 'Дистанция (км)'),
    distance,
  );
  final done = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, done);
  await tester.tap(done);
  await tester.pump();
}

Future<void> completePerSideSet(
  WidgetTester tester, {
  required String repeats,
  String? weight,
}) async {
  await enterWorkoutField(
    tester,
    find.widgetWithText(TextFormField, 'Повторения — левая'),
    repeats,
  );
  if (weight != null) {
    await enterWorkoutField(
      tester,
      find.widgetWithText(TextFormField, 'Вес (кг)'),
      weight,
    );
  }
  final leftDone = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, leftDone);
  await tester.tap(leftDone);
  await tester.pump();

  final sideRest = find.text('Отдых между сторонами');
  if (sideRest.evaluate().isNotEmpty) {
    await tester.tap(find.widgetWithText(FilledButton, 'Пропустить отдых'));
    await tester.pump();
  }

  await enterWorkoutField(
    tester,
    find.widgetWithText(TextFormField, 'Повторения — правая'),
    repeats,
  );
  if (weight != null) {
    await enterWorkoutField(
      tester,
      find.widgetWithText(TextFormField, 'Вес (кг)'),
      weight,
    );
  }
  final rightDone = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, rightDone);
  await tester.tap(rightDone);
  await tester.pump();
}

Future<void> completeBodyweightSet(
  WidgetTester tester, {
  required String repeats,
}) async {
  await enterWorkoutField(
    tester,
    find.widgetWithText(TextFormField, 'Повторения'),
    repeats,
  );
  expect(find.widgetWithText(TextFormField, 'Вес (кг)'), findsNothing);
  final done = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, done);
  await tester.tap(done);
  await tester.pump();
}

/// Планка по таймеру удержания: запуск кнопкой «Начать», без ручного ввода
/// времени — фактическое значение счётчика переносится в результат (13.5).
Future<void> completePlankHoldSet(WidgetTester tester) async {
  final start = find.widgetWithText(FilledButton, 'Начать');
  await ensureFieldVisible(tester, start);
  await tester.tap(start);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  final done = find.widgetWithText(FilledButton, 'Подход выполнен');
  await ensureFieldVisible(tester, done);
  await tester.tap(done);
  await tester.pump();
}

Future<void> skipRestIfShown(WidgetTester tester) async {
  final skip = find.widgetWithText(FilledButton, 'Пропустить отдых');
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> finishAndGoProgress(WidgetTester tester) async {
  await pumpUntilFound(tester, find.text('Тренировка завершена'));
  await tester.pumpAndSettle();
  await pumpUntilFound(tester, find.text('Тренировка сохранена'));
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
  await tester.tap(find.byTooltip('Предыдущая неделя'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Следующая неделя'));
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

    await goToTab(tester, Icons.fitness_center_outlined);

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

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);
    expect(find.text(_programName), findsOneWidget);

    await goToTab(tester, Icons.event_note_outlined);
    expect(find.text(_programName), findsWidgets);

    await startWorkout(tester);
    expect(find.widgetWithText(TextFormField, 'Повторения'), findsOneWidget);

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

    await goToTab(tester, Icons.fitness_center_outlined);

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

    await saveProgramBuilder(tester);
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
    await Future<void>.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Назад'));
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

    await saveProgramBuilder(tester);
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

    await goToTab(tester, Icons.fitness_center_outlined);

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

    await saveProgramBuilder(tester);
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

  testWidgets('флоу: тренировка по сторонам с фиксированным весом', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(
      tester,
      _squat,
      ExerciseType.strength,
      fixedWeight: true,
      perSide: true,
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
            'Повторения': '8',
            'Вес (кг)': '40',
            'Отдых (сек)': '10',
          },
        ),
      ],
      alternativeSets: const [],
    );

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await startWorkout(tester);

    final weightField = find.widgetWithText(TextFormField, 'Вес (кг)');
    expect(find.text('Повторения — левая'), findsOneWidget);
    expect(tester.widget<TextFormField>(weightField).controller!.text, '40');
    await tester.pump();

    await completePerSideSet(tester, repeats: '8', weight: '42.5');
    await skipRestIfShown(tester);

    await finishAndGoProgress(tester);
    await expectWorkoutCount(tester, '1');

    final sessions = await locator.get<WorkoutRepository>().getAllSessions();
    expect(sessions, hasLength(1));
    final detail = await locator.get<WorkoutRepository>().getSession(
      sessions.single.id!,
    );
    expect(detail, isNotNull);
    expect(detail!.results, hasLength(2));
    expect(detail.results[0].side, 'left');
    expect(detail.results[1].side, 'right');
    expect(detail.results[0].setIndex, 1);
    expect(detail.results[1].setIndex, 1);
    expect(detail.results[0].weightKg, 42.5);
    expect(detail.results[1].weightKg, 42.5);
    expect(detail.results[0].reps, 8);
    expect(detail.results[1].reps, 8);
  });

  testWidgets('прогресс и история после тренировки', (tester) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);
    await createExercise(tester, _running, ExerciseType.running);
    await pullToRefreshExercises(tester);

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

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await startWorkout(tester);

    await completeStrengthSet(tester, repeats: '10', weight: '40');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);

    final workoutsCard = find.ancestor(
      of: find.text('Тренировок'),
      matching: find.byType(Card),
    );
    expect(workoutsCard, findsOneWidget);

    await goToTab(tester, Icons.bar_chart_outlined);
    await tester.pumpAndSettle();
    expect(find.text('Тренировок'), findsOneWidget);
    expect(find.text('Дистанция'), findsOneWidget);
    expect(find.text('Время планки'), findsOneWidget);

    await goToTab(tester, Icons.home_outlined);
    await tester.pumpAndSettle();
    await tester.tap(find.text('К истории'));
    await tester.pumpAndSettle();
    expect(find.text(_programName), findsOneWidget);
    await tester.tap(find.text(_programName));
    await tester.pumpAndSettle();
    expect(find.text(_squat), findsOneWidget);
  });

  testWidgets('главный экран: активная программа и быстрый старт', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);

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

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    // Программа уже активна (saveProgramBuilder активирует по умолчанию).
    await goToTab(tester, Icons.home_outlined);
    await tester.pumpAndSettle();
    expect(find.text('Активная программа'), findsOneWidget);
    expect(find.text(_programName), findsWidgets);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Начать тренировку'),
      findsOneWidget,
    );
  });

  testWidgets('настройки: тема, звук и проверка обновления', (tester) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db, stubPlatformServices: true);

    await goToTab(tester, Icons.home_outlined);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);

    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);

    final soundSwitch = find.widgetWithText(SwitchListTile, 'Звук таймеров');
    final initialSound = tester.widget<SwitchListTile>(soundSwitch).value;
    await tester.tap(soundSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(soundSwitch).value, !initialSound);

    await tester.tap(find.text('Проверить обновление'));
    await pumpUntilFound(tester, find.text('Релизы ещё не опубликованы'));
  });

  testWidgets('тип «свой вес» и разминка перед тренировкой', (tester) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.bodyweight);
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
    await enterWarmup(tester, '1');

    await configureDay(
      tester,
      1,
      today,
      mainSets: [
        (_squat, {'Подходы': '1', 'Повторения': '12', 'Отдых (сек)': '10'}),
      ],
      alternativeSets: const [],
    );

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    expect(find.text(_programName), findsWidgets);

    await startWorkout(tester, warmupMinutes: 1);

    expect(find.widgetWithText(TextFormField, 'Повторения'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Вес (кг)'), findsNothing);

    await completeBodyweightSet(tester, repeats: '12');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);

    final sessions = await locator.get<WorkoutRepository>().getAllSessions();
    expect(sessions, hasLength(1));
    final detail = await locator.get<WorkoutRepository>().getSession(
      sessions.single.id!,
    );
    expect(detail, isNotNull);
    expect(detail!.results, hasLength(1));
    expect(detail.results.single.reps, 12);
    expect(detail.results.single.weightKg, isNull);
  });

  testWidgets(
    'редактирование и удаление: блокировка, активность, план недели',
    (tester) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(() => db.close());
      await pumpApp(tester, db);

      await goToTab(tester, Icons.fitness_center_outlined);
      await createExercise(tester, _squat, ExerciseType.strength);
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

      await saveProgramBuilder(tester);
      await pullToRefreshPrograms(tester);
      expect(find.text(_programName), findsOneWidget);

      // Программа уже активна (saveProgramBuilder активирует по умолчанию).
      await goToTab(tester, Icons.calendar_month_outlined);
      await tester.pumpAndSettle();
      expect(find.text('Активная'), findsOneWidget);

      await goToTab(tester, Icons.fitness_center_outlined);
      await tester.tap(find.text(_squat));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Удалить'));
      await tester.pumpAndSettle();
      expect(find.text('Нельзя удалить «$_squat»'), findsOneWidget);
      expect(
        find.text('Упражнение используется в программах:'),
        findsOneWidget,
      );
      expect(find.text('• $_programName'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'ОК'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(_squat), findsOneWidget);

      await goToTab(tester, Icons.calendar_month_outlined);
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Редактировать'));
      await tester.pumpAndSettle();
      final nameField = find.widgetWithText(TextFormField, 'Название');
      await enterField(tester, nameField, '$_programName 2');
      await saveProgramBuilder(tester);
      await pullToRefreshPrograms(tester);
      expect(find.text('$_programName 2'), findsOneWidget);

      await goToTab(tester, Icons.home_outlined);
      await tester.pumpAndSettle();
      expect(find.text('Активная программа'), findsOneWidget);
      expect(find.text('$_programName 2'), findsWidgets);

      await goToTab(tester, Icons.calendar_month_outlined);
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(find.text('Удалить программу «$_programName 2»?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Удалить').last);
      await tester.pumpAndSettle();
      await pullToRefreshPrograms(tester);
      expect(find.text('$_programName 2'), findsNothing);

      await goToTab(tester, Icons.event_note_outlined);
      await reloadWeekPlan(tester);
      expect(find.text('$_programName 2'), findsNothing);
      expect(find.text('Нет запланированных тренировок'), findsOneWidget);
    },
  );

  testWidgets('замеры тела: добавление, текущие значения и график', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.person_outline);
    expect(find.text('Текущие значения'), findsNothing);
    expect(find.text('Пока нет замеров тела'), findsOneWidget);

    await tester.tap(find.text('Добавить замер'));
    await tester.pumpAndSettle();
    await enterField(tester, find.widgetWithText(TextFormField, 'Рост'), '180');
    await enterField(tester, find.widgetWithText(TextFormField, 'Вес'), '80');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Текущие значения'), findsOneWidget);
    expect(find.text('180 см'), findsOneWidget);
    expect(find.text('80 кг'), findsWidgets);

    await tester.tap(find.text('Добавить замер'));
    await tester.pumpAndSettle();
    await enterField(tester, find.widgetWithText(TextFormField, 'Рост'), '181');
    await enterField(tester, find.widgetWithText(TextFormField, 'Вес'), '79');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('181 см'), findsOneWidget);
    expect(find.text('79 кг'), findsWidgets);

    final metricDropdown = find.byType(DropdownButton<BodyMetric>);
    expect(metricDropdown, findsOneWidget);
  });

  testWidgets('противопоказания: «больше не показывать» для программы', (
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
    await Future<void>.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Назад'));
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

    await configureDay(
      tester,
      2,
      day2Weekday(today),
      mainSets: [
        (
          _squat,
          {
            'Подходы': '1',
            'Повторения': '12',
            'Вес (кг)': '42.5',
            'Отдых (сек)': '10',
          },
        ),
      ],
      alternativeSets: const [],
    );

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();
    final startWorkoutBtn = find.widgetWithText(
      FilledButton,
      'Начать тренировку',
    );
    await pumpUntilFound(tester, startWorkoutBtn);
    await tester.tap(startWorkoutBtn);
    await tester.pumpAndSettle();

    expect(find.text('Противопоказания'), findsOneWidget);
    final dontShow = find.widgetWithText(
      CheckboxListTile,
      'Больше не показывать для этой программы',
    );
    expect(dontShow, findsOneWidget);
    await tester.tap(dontShow);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Продолжить'));
    await tester.pumpAndSettle();

    await completeStrengthSet(tester, repeats: '10', weight: '40');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await tester.tap(find.text('Перенести на сегодня'));
    await tester.pumpAndSettle();
    final startWorkoutBtn2 = find.widgetWithText(
      FilledButton,
      'Начать тренировку',
    );
    await pumpUntilFound(tester, startWorkoutBtn2);
    await tester.tap(startWorkoutBtn2);
    await tester.pumpAndSettle();
    expect(find.text('Противопоказания'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Повторения'), findsOneWidget);
  });

  testWidgets('непривязанный день: быстрый старт из плана недели', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);
    expect(find.text(_squat), findsOneWidget);

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
      null,
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

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await tester.pumpAndSettle();
    expect(find.text(_programName), findsWidgets);
    expect(find.text('Запланировано'), findsOneWidget);

    await goToTab(tester, Icons.home_outlined);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Начать тренировку'),
      findsOneWidget,
    );
  });

  testWidgets('планка по таймеру: цель, кнопка «Начать», фактическое время', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _plank, ExerciseType.plank);
    await pullToRefreshExercises(tester);
    expect(find.text(_plank), findsOneWidget);

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
        (_plank, {'Подходы': '1', 'Время (сек)': '30', 'Отдых (сек)': '10'}),
      ],
      alternativeSets: const [],
    );

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await startWorkout(tester);

    expect(find.text('Цель: 30 с'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Начать'), findsOneWidget);

    await completePlankHoldSet(tester);
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);

    final sessions = await locator.get<WorkoutRepository>().getAllSessions();
    expect(sessions, hasLength(1));
    final detail = await locator.get<WorkoutRepository>().getSession(
      sessions.single.id!,
    );
    expect(detail, isNotNull);
    expect(detail!.results, hasLength(1));
    final result = detail.results.single;
    expect(result.durationSeconds, isNotNull);
    expect(result.durationSeconds!, greaterThan(0));
    expect(result.weightKg, isNull);
  });

  testWidgets(
    'конструктор дня: схема мышц показывает задействованные и незадействованные',
    (tester) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(() => db.close());
      await pumpApp(tester, db);

      await goToTab(tester, Icons.fitness_center_outlined);
      await createExercise(tester, _squat, ExerciseType.strength);
      await pullToRefreshExercises(tester);

      await goToTab(tester, Icons.calendar_month_outlined);
      await tester.tap(find.byTooltip('Новая программа'));
      await tester.pumpAndSettle();
      await enterField(
        tester,
        find.widgetWithText(TextFormField, 'Название'),
        _programName,
      );

      final dayLabel = find.text('День 1');
      await tester.ensureVisible(dayLabel);
      await tester.pumpAndSettle();
      await tester.tap(dayLabel);
      await tester.pumpAndSettle();

      await addDayExercise(tester, _squat, {
        'Подходы': '1',
        'Повторения': '10',
        'Вес (кг)': '40',
        'Отдых (сек)': '10',
      });

      final save = find.descendant(
        of: find.byType(ProgramDayBuilderScreen),
        matching: find.widgetWithText(FilledButton, 'Сохранить'),
      );
      await ensureFieldVisible(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('настройки: кнопка прослушивания звука', (tester) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db, stubPlatformServices: true);

    await goToTab(tester, Icons.home_outlined);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final listenButton = find.byIcon(Icons.play_arrow);
    await tester.scrollUntilVisible(
      listenButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(listenButton);
    await tester.pumpAndSettle();
    await tester.tap(listenButton);
    await tester.pumpAndSettle();
  });

  testWidgets('прогресс: тап по карточке «Тренировок» открывает историю', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);

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

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await startWorkout(tester);
    await completeStrengthSet(tester, repeats: '10', weight: '40');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);

    await goToTab(tester, Icons.bar_chart_outlined);
    await tester.pumpAndSettle();

    final workoutsCard = find.ancestor(
      of: find.text('Тренировок'),
      matching: find.byType(Card),
    );
    expect(workoutsCard, findsOneWidget);

    final inkWell = find.descendant(
      of: workoutsCard,
      matching: find.byType(InkWell),
    );
    expect(inkWell, findsOneWidget);
    await tester.tap(inkWell);
    await tester.pumpAndSettle();

    expect(find.text(_programName), findsOneWidget);
  });

  testWidgets('завершение тренировки: показывает список упражнений и мышц', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);
    await createExercise(tester, _plank, ExerciseType.plank);
    await pullToRefreshExercises(tester);

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
        (_plank, {'Подходы': '1', 'Время (сек)': '20', 'Отдых (сек)': '10'}),
      ],
      alternativeSets: const [],
    );

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await startWorkout(tester);

    await completeStrengthSet(tester, repeats: '10', weight: '40');
    await skipRestIfShown(tester);
    await completePlankSet(tester, seconds: '20');
    await skipRestIfShown(tester);

    await pumpUntilFound(tester, find.text('Тренировка завершена'));

    expect(find.text('Упражнения'), findsOneWidget);
    expect(find.text(_squat), findsOneWidget);
    expect(find.text(_plank), findsOneWidget);

    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Тренировка сохранена'));
  });

  testWidgets('предупреждение wake lock: ОК скрывает баннер на сессию', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db, disableWakelock: true);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);

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

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);

    await goToTab(tester, Icons.event_note_outlined);
    await startWorkout(tester);

    expect(find.byType(MaterialBanner), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'ОК'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsNothing);

    await completeStrengthSet(tester, repeats: '10', weight: '40');
    await skipRestIfShown(tester);
    await finishAndGoProgress(tester);
  });

  testWidgets('привязка дня недели в конструкторе дня: создание → заполнение → '
      'привязка → возврат', (tester) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(() => db.close());
    await pumpApp(tester, db);

    await goToTab(tester, Icons.fitness_center_outlined);
    await createExercise(tester, _squat, ExerciseType.strength);
    await pullToRefreshExercises(tester);
    expect(find.text(_squat), findsOneWidget);

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

    final dayLabel1 = find.text('День 1');
    await tester.scrollUntilVisible(
      dayLabel1,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final dayCard1 = find.ancestor(of: dayLabel1, matching: find.byType(Card));
    await tester.tap(dayLabel1);
    await tester.pumpAndSettle();

    await addDayExercise(tester, _squat, {
      'Подходы': '1',
      'Повторения': '10',
      'Вес (кг)': '40',
      'Отдых (сек)': '10',
    });

    expect(find.byType(ProgramDayBuilderScreen), findsOneWidget);

    final today = DateTime.now().weekday;
    final todayLabel = weekdayLabel(today);
    final chip = find.widgetWithText(ChoiceChip, todayLabel);
    await tester.scrollUntilVisible(
      chip,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    final selectedChip = tester.widget<ChoiceChip>(chip);
    expect(selectedChip.selected, isTrue);

    final save = find.descendant(
      of: find.byType(ProgramDayBuilderScreen),
      matching: find.widgetWithText(FilledButton, 'Сохранить'),
    );
    await ensureFieldVisible(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byType(ProgramBuilderScreen), findsOneWidget);

    final daySubtitle = find.descendant(
      of: dayCard1,
      matching: find.byType(Text),
    );
    final subtitleTexts = daySubtitle.evaluate().map((e) {
      final widget = e.widget as Text;
      return widget.data ?? '';
    }).toList();
    expect(
      subtitleTexts.any((t) => t.contains(todayLabel)),
      isTrue,
      reason: 'Day tile should show bound weekday label "$todayLabel"',
    );

    final dayLabel2 = find.text('День 2');
    await tester.scrollUntilVisible(
      dayLabel2,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(dayLabel2);
    await tester.pumpAndSettle();

    await addDayExercise(tester, _squat, {
      'Подходы': '1',
      'Повторения': '10',
      'Вес (кг)': '40',
      'Отдых (сек)': '10',
    });

    expect(find.byType(ProgramDayBuilderScreen), findsOneWidget);

    final save2 = find.descendant(
      of: find.byType(ProgramDayBuilderScreen),
      matching: find.widgetWithText(FilledButton, 'Сохранить'),
    );
    await ensureFieldVisible(tester, save2);
    await tester.tap(save2);
    await tester.pumpAndSettle();

    expect(find.byType(ProgramBuilderScreen), findsOneWidget);

    await saveProgramBuilder(tester);
    await pullToRefreshPrograms(tester);
    expect(find.text(_programName), findsOneWidget);
  });
}
