import 'dart:convert';

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
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programs;
  late ExerciseRepository exercises;
  late WorkoutRepository workouts;
  late LlmExportService service;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programs = ProgramRepository(db);
    exercises = ExerciseRepository(db, MediaStore());
    workouts = WorkoutRepository(db);
    service = LlmExportService(
      programRepository: programs,
      exerciseRepository: exercises,
      workoutRepository: workouts,
    );
    addTearDown(() => db.close());
  });

  Future<int> insertExercise({
    String name = 'Жим штанги',
    ExerciseType type = ExerciseType.strength,
  }) async {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: type,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
  }

  Program program(String name, {int daysCount = 1}) => Program(
    name: name,
    daysCount: daysCount,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  test('programToJson возвращает null для отсутствующей программы', () async {
    expect(await service.programToJson(999), isNull);
  });

  test('programToJson отдаёт валидный JSON с ожидаемыми полями', () async {
    final exId = await insertExercise();
    final created = await programs.create(program('Сплит', daysCount: 2), [
      ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 1),
      ProgramDay(programId: 0, dayIndex: 1),
    ]);
    final days = await programs.getDays(created.id!);
    await programs.addExerciseToDay(days.first.id!, exId);

    final source = await service.programToJson(created.id!);
    final decoded = jsonDecode(source!) as Map<String, dynamic>;

    expect(decoded['type'], 'program');
    expect(decoded['id'], created.id);
    expect(decoded['name'], 'Сплит');
    expect(decoded['daysCount'], 2);

    final exportedDays = decoded['days'] as List<dynamic>;
    expect(exportedDays, hasLength(2));
    final firstDay = exportedDays[0] as Map<String, dynamic>;
    expect(firstDay['dayIndex'], 0);
    expect(firstDay['dayOfWeek'], 1);

    final exportedExercises = firstDay['exercises'] as List<dynamic>;
    expect(exportedExercises, hasLength(1));
    final exercise = exportedExercises[0] as Map<String, dynamic>;
    expect(exercise['name'], 'Жим штанги');
    expect(exercise['exerciseId'], exId);
    expect(exercise['isAlternative'], isFalse);
  });

  test('historyToJson отдаёт сессии с датой, программой и подходами', () async {
    final session = WorkoutSession(
      programName: 'База',
      dayIndex: 0,
      performedDate: DateTime(2026, 8, 10, 18, 0),
      startedAt: DateTime(2026, 8, 10, 18, 0),
      endedAt: DateTime(2026, 8, 10, 18, 40),
    );
    await workouts.saveSession(session, [
      WorkoutSetResult(
        sessionId: 0,
        exerciseName: 'Приседания',
        exerciseType: ExerciseType.strength,
        setIndex: 1,
        reps: 8,
        weightKg: 20,
        completedAt: DateTime(2026, 8, 10, 18, 5),
      ),
      WorkoutSetResult(
        sessionId: 0,
        exerciseName: 'Приседания',
        exerciseType: ExerciseType.strength,
        setIndex: 2,
        reps: 8,
        weightKg: 22,
        completedAt: DateTime(2026, 8, 10, 18, 10),
      ),
      WorkoutSetResult(
        sessionId: 0,
        exerciseName: 'Планка',
        exerciseType: ExerciseType.plank,
        setIndex: 1,
        durationSeconds: 45,
        completedAt: DateTime(2026, 8, 10, 18, 15),
      ),
    ]);

    final source = await service.historyToJson();
    final decoded = jsonDecode(source) as Map<String, dynamic>;

    expect(decoded['type'], 'history');
    final exportedSessions = decoded['sessions'] as List<dynamic>;
    expect(exportedSessions, hasLength(1));

    final exported = exportedSessions.first as Map<String, dynamic>;
    expect(exported['programName'], 'База');
    expect(exported['dayIndex'], 0);
    expect(exported['variant'], 'main');
    expect(exported['performedDate'], '2026-08-10T18:00:00.000');

    final exportedExercises = exported['exercises'] as List<dynamic>;
    expect(exportedExercises, hasLength(2));

    final squats = exportedExercises[0] as Map<String, dynamic>;
    expect(squats['name'], 'Приседания');
    expect(squats['type'], 'strength');
    final sets = squats['sets'] as List<dynamic>;
    expect(sets, hasLength(2));
    expect((sets[0] as Map<String, dynamic>)['weightKg'], 20);
    expect((sets[1] as Map<String, dynamic>)['weightKg'], 22);

    final plank = exportedExercises[1] as Map<String, dynamic>;
    final plankSets = plank['sets'] as List<dynamic>;
    expect((plankSets[0] as Map<String, dynamic>)['durationSeconds'], 45);
  });

  test('programToJson отдаёт JSON с альтернативным набором', () async {
    final exId = await insertExercise();
    final created = await programs.create(program('Сплит'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final day = (await programs.getDays(created.id!)).first;
    await programs.addExerciseToDay(day.id!, exId, isAlternative: true);

    final source = await service.programToJson(created.id!);
    final decoded = jsonDecode(source!) as Map<String, dynamic>;
    final exportedDay =
        (decoded['days'] as List<dynamic>)[0] as Map<String, dynamic>;
    final exercise =
        (exportedDay['exercises'] as List<dynamic>)[0] as Map<String, dynamic>;

    expect(exercise['isAlternative'], isTrue);
  });
}
