import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertProgram(String name) async {
    return db
        .into(db.programs)
        .insert(
          ProgramsCompanion.insert(
            name: name,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
  }

  Future<int> insertDay(int programId, int dayIndex) async {
    return db
        .into(db.programDays)
        .insert(
          ProgramDaysCompanion.insert(programId: programId, dayIndex: dayIndex),
        );
  }

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

  group('каскадное удаление', () {
    test('удаление программы удаляет её дни', () async {
      final programId = await insertProgram('PPL');
      final dayId = await insertDay(programId, 0);

      await (db.delete(db.programs)..where((t) => t.id.equals(programId))).go();

      expect(
        await (db.select(
          db.programDays,
        )..where((t) => t.id.equals(dayId))).get(),
        isEmpty,
      );
    });

    test(
      'удаление дня удаляет упражнения дня, напоминания и отметки',
      () async {
        final programId = await insertProgram('PPL');
        final dayId = await insertDay(programId, 0);
        final exerciseId = await insertExercise('Жим');

        await db
            .into(db.programDayExercises)
            .insert(
              ProgramDayExercisesCompanion.insert(
                dayId: dayId,
                exerciseId: Value(exerciseId),
                orderIndex: 0,
              ),
            );
        await db
            .into(db.workoutReminders)
            .insert(
              WorkoutRemindersCompanion.insert(
                programDayId: dayId,
                hour: 9,
                minute: 0,
              ),
            );
        await db
            .into(db.scheduleMarks)
            .insert(
              ScheduleMarksCompanion.insert(
                programDayId: dayId,
                weekStart: DateTime(2026, 3, 9),
                status: ScheduleMarkStatus.skipped,
              ),
            );

        await (db.delete(
          db.programDays,
        )..where((t) => t.id.equals(dayId))).go();

        expect(
          await (db.select(
            db.programDayExercises,
          )..where((t) => t.dayId.equals(dayId))).get(),
          isEmpty,
        );
        expect(
          await (db.select(
            db.workoutReminders,
          )..where((t) => t.programDayId.equals(dayId))).get(),
          isEmpty,
        );
        expect(
          await (db.select(
            db.scheduleMarks,
          )..where((t) => t.programDayId.equals(dayId))).get(),
          isEmpty,
        );
      },
    );

    test('удаление сессии удаляет результаты подходов', () async {
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              programName: 'Push',
              dayIndex: 0,
              variant: WorkoutVariant.main,
              performedDate: DateTime(2026, 3, 3),
              startedAt: DateTime(2026, 3, 3, 9),
              endedAt: DateTime(2026, 3, 3, 9, 30),
            ),
          );
      await db
          .into(db.workoutSetResults)
          .insert(
            WorkoutSetResultsCompanion.insert(
              sessionId: sessionId,
              exerciseName: 'Жим',
              exerciseType: ExerciseType.strength,
              setIndex: 0,
              completedAt: DateTime(2026, 3, 3, 9, 10),
            ),
          );

      await (db.delete(
        db.workoutSessions,
      )..where((t) => t.id.equals(sessionId))).go();

      expect(
        await (db.select(
          db.workoutSetResults,
        )..where((t) => t.sessionId.equals(sessionId))).get(),
        isEmpty,
      );
    });

    test(
      'удаление упражнения удаляет привязки мышц и противопоказаний',
      () async {
        final muscleGroupId = await db
            .into(db.muscleGroups)
            .insert(
              MuscleGroupsCompanion.insert(
                key: 'fk_test_chest',
                labelRu: 'Грудь (fk)',
                view: MuscleView.front,
                regionKey: 'chest',
              ),
            );
        final tagId = await db
            .into(db.contraindicationTags)
            .insert(
              ContraindicationTagsCompanion.insert(
                key: 'fk_test_knees',
                labelRu: 'Колени (fk)',
              ),
            );
        final exerciseId = await insertExercise('Жим');

        await db
            .into(db.exerciseMuscles)
            .insert(
              ExerciseMusclesCompanion.insert(
                exerciseId: exerciseId,
                muscleGroupId: muscleGroupId,
                intensity: MuscleIntensity.primary,
              ),
            );
        await db
            .into(db.exerciseContraindications)
            .insert(
              ExerciseContraindicationsCompanion.insert(
                exerciseId: exerciseId,
                contraindicationTagId: tagId,
              ),
            );

        await (db.delete(
          db.exercises,
        )..where((t) => t.id.equals(exerciseId))).go();

        expect(
          await (db.select(
            db.exerciseMuscles,
          )..where((t) => t.exerciseId.equals(exerciseId))).get(),
          isEmpty,
        );
        expect(
          await (db.select(
            db.exerciseContraindications,
          )..where((t) => t.exerciseId.equals(exerciseId))).get(),
          isEmpty,
        );
      },
    );

    test('удаление пользователя удаляет его противопоказания', () async {
      final tagId = await db
          .into(db.contraindicationTags)
          .insert(
            ContraindicationTagsCompanion.insert(
              key: 'fk_test_back',
              labelRu: 'Спина (fk)',
            ),
          );
      final userId = await db
          .into(db.userProfiles)
          .insert(UserProfilesCompanion.insert(name: Value('Иван')));

      await db
          .into(db.userContraindications)
          .insert(
            UserContraindicationsCompanion.insert(
              userId: userId,
              contraindicationTagId: tagId,
            ),
          );

      await (db.delete(
        db.userProfiles,
      )..where((t) => t.id.equals(userId))).go();

      expect(
        await (db.select(
          db.userContraindications,
        )..where((t) => t.userId.equals(userId))).get(),
        isEmpty,
      );
    });
  });

  group('обнуление ссылок при удалении', () {
    test('удаление упражнения обнуляет exercise_id в упражнении дня', () async {
      final programId = await insertProgram('PPL');
      final dayId = await insertDay(programId, 0);
      final exerciseId = await insertExercise('Приседания');

      final dayExerciseId = await db
          .into(db.programDayExercises)
          .insert(
            ProgramDayExercisesCompanion.insert(
              dayId: dayId,
              exerciseId: Value(exerciseId),
              orderIndex: 0,
            ),
          );

      await (db.delete(
        db.exercises,
      )..where((t) => t.id.equals(exerciseId))).go();

      final row = (await (db.select(
        db.programDayExercises,
      )..where((t) => t.id.equals(dayExerciseId))).getSingle());
      expect(row.exerciseId, isNull);
    });

    test(
      'удаление упражнения обнуляет exercise_id в результате подхода',
      () async {
        final exerciseId = await insertExercise('Становая');
        final sessionId = await db
            .into(db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                programName: 'Pull',
                dayIndex: 0,
                variant: WorkoutVariant.main,
                performedDate: DateTime(2026, 3, 3),
                startedAt: DateTime(2026, 3, 3, 9),
                endedAt: DateTime(2026, 3, 3, 9, 30),
              ),
            );
        final setId = await db
            .into(db.workoutSetResults)
            .insert(
              WorkoutSetResultsCompanion.insert(
                sessionId: sessionId,
                exerciseId: Value(exerciseId),
                exerciseName: 'Становая',
                exerciseType: ExerciseType.strength,
                setIndex: 0,
                completedAt: DateTime(2026, 3, 3, 9, 10),
              ),
            );

        await (db.delete(
          db.exercises,
        )..where((t) => t.id.equals(exerciseId))).go();

        final row = (await (db.select(
          db.workoutSetResults,
        )..where((t) => t.id.equals(setId))).getSingle());
        expect(row.exerciseId, isNull);
      },
    );

    test('удаление программы обнуляет program_id в сессии', () async {
      final programId = await insertProgram('Leg Day');
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              programId: Value(programId),
              programName: 'Leg Day',
              dayIndex: 0,
              variant: WorkoutVariant.main,
              performedDate: DateTime(2026, 3, 3),
              startedAt: DateTime(2026, 3, 3, 9),
              endedAt: DateTime(2026, 3, 3, 9, 30),
            ),
          );

      await (db.delete(db.programs)..where((t) => t.id.equals(programId))).go();

      final session = (await (db.select(
        db.workoutSessions,
      )..where((t) => t.id.equals(sessionId))).getSingle());
      expect(session.programId, isNull);
      expect(session.programName, 'Leg Day');
    });

    test('удаление дня обнуляет program_day_id в сессии', () async {
      final programId = await insertProgram('PPL');
      final dayId = await insertDay(programId, 0);
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              programName: 'PPL',
              programDayId: Value(dayId),
              dayIndex: 0,
              variant: WorkoutVariant.main,
              performedDate: DateTime(2026, 3, 3),
              startedAt: DateTime(2026, 3, 3, 9),
              endedAt: DateTime(2026, 3, 3, 9, 30),
            ),
          );

      await (db.delete(db.programDays)..where((t) => t.id.equals(dayId))).go();

      final session = (await (db.select(
        db.workoutSessions,
      )..where((t) => t.id.equals(sessionId))).getSingle());
      expect(session.programDayId, isNull);
    });
  });

  group('ограничение ссылочной целостности', () {
    test('удаление группы мышц удаляет привязку к упражнению', () async {
      final muscleGroupId = await db
          .into(db.muscleGroups)
          .insert(
            MuscleGroupsCompanion.insert(
              key: 'fk_test_biceps',
              labelRu: 'Бицепс (fk)',
              view: MuscleView.front,
              regionKey: 'biceps',
            ),
          );
      final exerciseId = await insertExercise('Сгибания');

      await db
          .into(db.exerciseMuscles)
          .insert(
            ExerciseMusclesCompanion.insert(
              exerciseId: exerciseId,
              muscleGroupId: muscleGroupId,
              intensity: MuscleIntensity.primary,
            ),
          );

      await (db.delete(
        db.muscleGroups,
      )..where((t) => t.id.equals(muscleGroupId))).go();

      expect(
        await (db.select(
          db.exerciseMuscles,
        )..where((t) => t.muscleGroupId.equals(muscleGroupId))).get(),
        isEmpty,
      );
    });
  });
}
