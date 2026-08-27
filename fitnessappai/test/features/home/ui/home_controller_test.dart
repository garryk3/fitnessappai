import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/home/ui/home_controller.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepository;
  late ExerciseRepository exerciseRepository;
  late WorkoutRepository workoutRepository;
  late int programDayId;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepository = ProgramRepository(db);
    exerciseRepository = ExerciseRepository(db, MediaStore());
    workoutRepository = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertExercise(String name) async {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: ExerciseType.strength,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
  }

  Future<Program> createProgram({
    String name = 'Программа',
    List<int?> dayOfWeeks = const [1],
  }) async {
    final program = await programRepository.create(
      Program(
        name: name,
        daysCount: dayOfWeeks.length,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [
        for (var i = 0; i < dayOfWeeks.length; i++)
          ProgramDay(programId: 0, dayIndex: i, dayOfWeek: dayOfWeeks[i]),
      ],
    );
    return program;
  }

  Future<void> addExerciseToDay(
    Program program,
    int exerciseId, {
    int dayIndex = 0,
  }) async {
    final days = await programRepository.getDays(program.id!);
    await programRepository.addExerciseToDay(days[dayIndex].id!, exerciseId);
  }

  Future<void> saveSession(
    WorkoutSession session,
    List<String> exerciseNames,
  ) async {
    await workoutRepository.saveSession(session, [
      for (var i = 0; i < exerciseNames.length; i++)
        WorkoutSetResult(
          sessionId: 0,
          exerciseName: exerciseNames[i],
          exerciseType: ExerciseType.strength,
          setIndex: i + 1,
          reps: 10,
          completedAt: session.performedDate.add(Duration(minutes: i)),
        ),
    ]);
  }

  Future<int> createProgramDay() async {
    final program = await createProgram(name: 'База', dayOfWeeks: [1]);
    final days = await programRepository.getDays(program.id!);
    return days.single.id!;
  }

  WorkoutSession session({
    int dayIndex = 0,
    DateTime? performedDate,
    DateTime? startedAt,
    DateTime? endedAt,
  }) => WorkoutSession(
    programName: 'База',
    programDayId: programDayId,
    dayIndex: dayIndex,
    performedDate: performedDate ?? DateTime(2026, 8, 10),
    startedAt: startedAt ?? DateTime(2026, 8, 10, 18, 0),
    endedAt: endedAt ?? DateTime(2026, 8, 10, 18, 40),
  );

  test('без программ не показывает активную и список пуст', () async {
    final controller = HomeController(
      programRepository: programRepository,
      exerciseRepository: exerciseRepository,
      workoutRepository: workoutRepository,
      clock: () => DateTime(2026, 8, 10),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.isLoading.value, isFalse);
    expect(controller.hasPrograms.value, isFalse);
    expect(controller.activePrograms.value, isEmpty);
    expect(controller.recentWorkouts.value, isEmpty);
  });

  test('активная программа определяет ближайший день и упражнения', () async {
    final exId = await insertExercise('Жим штанги');
    final program = await createProgram(name: 'Силовая', dayOfWeeks: [2, 5]);
    await addExerciseToDay(program, exId);
    await programRepository.setActive(program.id!);

    // Понедельник (1): ближайший день с dayOfWeek >= 1 — вторник (2).
    final controller = HomeController(
      programRepository: programRepository,
      exerciseRepository: exerciseRepository,
      workoutRepository: workoutRepository,
      clock: () => DateTime(2026, 8, 10),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.hasPrograms.value, isTrue);
    expect(controller.activePrograms.value, hasLength(1));
    expect(controller.activePrograms.value.first.program.name, 'Силовая');
    expect(controller.activePrograms.value.first.upcomingDay?.dayOfWeek, 2);
    expect(controller.activePrograms.value.first.exerciseNames, ['Жим штанги']);
  });

  test('перенос ближайшего дня на начало недели', () async {
    final program = await createProgram(name: 'Силовая', dayOfWeeks: [2]);
    await programRepository.setActive(program.id!);

    // Суббота (6): день 2 уже прошёл — переносим на следующий вторник.
    final controller = HomeController(
      programRepository: programRepository,
      exerciseRepository: exerciseRepository,
      workoutRepository: workoutRepository,
      clock: () => DateTime(2026, 8, 15),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.activePrograms.value.first.upcomingDay?.dayOfWeek, 2);
  });

  test(
    'активная программа без привязанного дня недели — показывает непривязанный день',
    () async {
      final program = await createProgram(name: 'Силовая', dayOfWeeks: [null]);
      await programRepository.setActive(program.id!);

      final controller = HomeController(
        programRepository: programRepository,
        exerciseRepository: exerciseRepository,
        workoutRepository: workoutRepository,
        clock: () => DateTime(2026, 8, 10),
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.activePrograms.value.first.program.id, program.id);
      // Непривязанный день теперь отображается как ближайший.
      expect(controller.activePrograms.value.first.upcomingDay, isNotNull);
      expect(
        controller.activePrograms.value.first.upcomingDay?.dayOfWeek,
        isNull,
      );
      expect(controller.activePrograms.value.first.exerciseNames, isEmpty);
    },
  );

  test('recentWorkouts берёт три свежие сессии со статистикой', () async {
    programDayId = await createProgramDay();
    for (var i = 0; i < 4; i++) {
      await saveSession(
        session(dayIndex: i, performedDate: DateTime(2026, 8, 10 - i)),
        i.isEven ? ['Жим'] : ['Жим', 'Тяга'],
      );
    }

    final controller = HomeController(
      programRepository: programRepository,
      exerciseRepository: exerciseRepository,
      workoutRepository: workoutRepository,
      clock: () => DateTime(2026, 8, 10),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    final workouts = controller.recentWorkouts.value;
    expect(workouts, hasLength(3));
    expect(workouts.first.session.performedDate, DateTime(2026, 8, 10));
    expect(workouts.first.exercisesCount, 1);
    expect(workouts[1].exercisesCount, 2);
    expect(workouts.last.exercisesCount, 1);
  });

  test('не активна ни одна программа — подсказка через hasPrograms', () async {
    await createProgram(name: 'Силовая');

    final controller = HomeController(
      programRepository: programRepository,
      exerciseRepository: exerciseRepository,
      workoutRepository: workoutRepository,
      clock: () => DateTime(2026, 8, 10),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.hasPrograms.value, isTrue);
    expect(controller.activePrograms.value, isEmpty);
  });

  test(
    'две активные программы — обе отображаются с правильными днями',
    () async {
      final exId = await insertExercise('Жим штанги');
      // Программа 1: привязана к четвергу (4).
      final p1 = await createProgram(name: 'Силовая', dayOfWeeks: [4]);
      await addExerciseToDay(p1, exId);
      await programRepository.setActive(p1.id!);

      // Программа 2: привязана к среде (3) — сегодня среда.
      final p2 = await createProgram(name: 'Кардио', dayOfWeeks: [3]);
      await programRepository.setActive(p2.id!);

      // Среда (3): P2 (среда) приоритетнее P1 (четверг).
      final controller = HomeController(
        programRepository: programRepository,
        exerciseRepository: exerciseRepository,
        workoutRepository: workoutRepository,
        clock: () => DateTime(2026, 8, 12), // среда
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.hasPrograms.value, isTrue);
      expect(controller.activePrograms.value, hasLength(2));

      // P2 — среда (ближе к сегодня), P1 — четверг.
      final names = controller.activePrograms.value
          .map((i) => i.program.name)
          .toList();
      expect(names, containsAll(['Силовая', 'Кардио']));

      final p2Info = controller.activePrograms.value.firstWhere(
        (i) => i.program.name == 'Кардио',
      );
      expect(p2Info.upcomingDay?.dayOfWeek, 3);

      final p1Info = controller.activePrograms.value.firstWhere(
        (i) => i.program.name == 'Силовая',
      );
      expect(p1Info.upcomingDay?.dayOfWeek, 4);
    },
  );
}
