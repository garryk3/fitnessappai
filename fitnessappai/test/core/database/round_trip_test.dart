import 'package:drift/drift.dart';
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

  group('круговые проверки сохранения данных', () {
    test('Программа и её дни', () async {
      final programId = await db
          .into(db.programs)
          .insert(
            ProgramsCompanion.insert(
              name: 'Split',
              description: Value('Классический сплит'),
              daysCount: Value(3),
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 2),
            ),
          );
      final dayId = await db
          .into(db.programDays)
          .insert(
            ProgramDaysCompanion.insert(
              programId: programId,
              dayIndex: 0,
              dayOfWeek: Value(1),
            ),
          );

      final program = (await db.select(db.programs).getSingle());
      expect(program.id, programId);
      expect(program.name, 'Split');
      expect(program.description, 'Классический сплит');
      expect(program.daysCount, 3);

      final day = (await db.select(db.programDays).getSingle());
      expect(day.id, dayId);
      expect(day.programId, programId);
      expect(day.dayIndex, 0);
      expect(day.dayOfWeek, 1);
    });

    test('Упражнение со списком ошибок и типом', () async {
      final exerciseId = await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: 'Жим штанги',
              description: Value('Базовое движение'),
              instructions: Value('Лечь на скамью'),
              commonMistakes: Value(const ['отрыв таза', 'неполная амплитуда']),
              type: ExerciseType.strength,
              thumbnailPath: Value('/img/bench.png'),
              isCustom: Value(true),
              createdAt: DateTime(2026, 2, 2),
              updatedAt: DateTime(2026, 2, 3),
            ),
          );

      final exercise = (await db.select(db.exercises).getSingle());
      expect(exercise.id, exerciseId);
      expect(exercise.name, 'Жим штанги');
      expect(exercise.type, ExerciseType.strength);
      expect(exercise.commonMistakes, ['отрыв таза', 'неполная амплитуда']);
      expect(exercise.thumbnailPath, '/img/bench.png');
      expect(exercise.isCustom, isTrue);
    });

    test('Программа → день → упражнение дня', () async {
      final programId = await db
          .into(db.programs)
          .insert(
            ProgramsCompanion.insert(
              name: 'PPL',
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
      final dayId = await db
          .into(db.programDays)
          .insert(
            ProgramDaysCompanion.insert(programId: programId, dayIndex: 1),
          );
      final exerciseId = await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: 'Подтягивания',
              type: ExerciseType.strength,
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );

      final id = await db
          .into(db.programDayExercises)
          .insert(
            ProgramDayExercisesCompanion.insert(
              dayId: dayId,
              exerciseId: Value(exerciseId),
              orderIndex: 0,
              sets: Value(4),
              reps: Value(10),
              restSeconds: Value(90),
            ),
          );

      final row = (await db.select(db.programDayExercises).getSingle());
      expect(row.id, id);
      expect(row.dayId, dayId);
      expect(row.exerciseId, exerciseId);
      expect(row.orderIndex, 0);
      expect(row.sets, 4);
      expect(row.reps, 10);
      expect(row.restSeconds, 90);
    });

    test('Напоминание тренировки', () async {
      final programId = await db
          .into(db.programs)
          .insert(
            ProgramsCompanion.insert(
              name: 'Push',
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
      final dayId = await db
          .into(db.programDays)
          .insert(
            ProgramDaysCompanion.insert(programId: programId, dayIndex: 0),
          );

      await db
          .into(db.workoutReminders)
          .insert(
            WorkoutRemindersCompanion.insert(
              programDayId: dayId,
              hour: 18,
              minute: 30,
              enabled: Value(false),
            ),
          );

      final reminder = (await db.select(db.workoutReminders).getSingle());
      expect(reminder.programDayId, dayId);
      expect(reminder.hour, 18);
      expect(reminder.minute, 30);
      expect(reminder.enabled, isFalse);
    });

    test('Тренировочная сессия и результаты подходов', () async {
      final exerciseId = await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: 'Приседания',
              type: ExerciseType.strength,
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );

      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              programName: 'Leg Day',
              dayIndex: 2,
              variant: WorkoutVariant.main,
              performedDate: DateTime(2026, 3, 3),
              startedAt: DateTime(2026, 3, 3, 9),
              endedAt: DateTime(2026, 3, 3, 9, 40),
            ),
          );

      final setResultId = await db
          .into(db.workoutSetResults)
          .insert(
            WorkoutSetResultsCompanion.insert(
              sessionId: sessionId,
              exerciseId: Value(exerciseId),
              exerciseName: 'Приседания',
              exerciseType: ExerciseType.strength,
              setIndex: 0,
              reps: Value(8),
              weightKg: Value(80.0),
              completedAt: DateTime(2026, 3, 3, 9, 10),
            ),
          );

      final session = (await db.select(db.workoutSessions).getSingle());
      expect(session.id, sessionId);
      expect(session.programName, 'Leg Day');
      expect(session.dayIndex, 2);
      expect(session.variant, WorkoutVariant.main);
      expect(session.status, 'completed');

      final setResult = (await db.select(db.workoutSetResults).getSingle());
      expect(setResult.id, setResultId);
      expect(setResult.sessionId, sessionId);
      expect(setResult.exerciseName, 'Приседания');
      expect(setResult.exerciseType, ExerciseType.strength);
      expect(setResult.reps, 8);
      expect(setResult.weightKg, 80.0);
    });

    test('Отметка пропуска дня', () async {
      final programId = await db
          .into(db.programs)
          .insert(
            ProgramsCompanion.insert(
              name: 'Full Body',
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
      final dayId = await db
          .into(db.programDays)
          .insert(
            ProgramDaysCompanion.insert(programId: programId, dayIndex: 0),
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

      final mark = (await db.select(db.scheduleMarks).getSingle());
      expect(mark.programDayId, dayId);
      expect(mark.weekStart, DateTime(2026, 3, 9));
      expect(mark.status, ScheduleMarkStatus.skipped);
    });

    test('Группа мышц и привязка к упражнению', () async {
      final muscleGroupId = await db
          .into(db.muscleGroups)
          .insert(
            MuscleGroupsCompanion.insert(
              key: 'test_chest',
              labelRu: 'Грудь (тест)',
              view: MuscleView.front,
              regionKey: 'chest',
            ),
          );
      final exerciseId = await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: 'Отжимания',
              type: ExerciseType.strength,
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );

      await db
          .into(db.exerciseMuscles)
          .insert(
            ExerciseMusclesCompanion.insert(
              exerciseId: exerciseId,
              muscleGroupId: muscleGroupId,
              intensity: MuscleIntensity.primary,
            ),
          );

      final muscle = (await (db.select(
        db.muscleGroups,
      )..where((t) => t.key.equals('test_chest'))).getSingle());
      expect(muscle.key, 'test_chest');
      expect(muscle.labelRu, 'Грудь (тест)');
      expect(muscle.view, MuscleView.front);

      final binding = (await db.select(db.exerciseMuscles).getSingle());
      expect(binding.exerciseId, exerciseId);
      expect(binding.muscleGroupId, muscleGroupId);
      expect(binding.intensity, MuscleIntensity.primary);
    });

    test('Тег противопоказаний и привязки', () async {
      final tagId = await db
          .into(db.contraindicationTags)
          .insert(
            ContraindicationTagsCompanion.insert(
              key: 'test_knees',
              labelRu: 'Колени (тест)',
            ),
          );
      final exerciseId = await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: 'Выпады',
              type: ExerciseType.strength,
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
      final userId = await db
          .into(db.userProfiles)
          .insert(
            UserProfilesCompanion.insert(
              name: Value('Иван'),
              heightCm: Value(180.0),
              weightKg: Value(82.0),
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
      await db
          .into(db.userContraindications)
          .insert(
            UserContraindicationsCompanion.insert(
              userId: userId,
              contraindicationTagId: tagId,
            ),
          );

      final tag = (await (db.select(
        db.contraindicationTags,
      )..where((t) => t.key.equals('test_knees'))).getSingle());
      expect(tag.key, 'test_knees');
      expect(tag.labelRu, 'Колени (тест)');

      final exerciseLink = (await db
          .select(db.exerciseContraindications)
          .getSingle());
      expect(exerciseLink.exerciseId, exerciseId);
      expect(exerciseLink.contraindicationTagId, tagId);

      final userLink = (await db.select(db.userContraindications).getSingle());
      expect(userLink.userId, userId);
      expect(userLink.contraindicationTagId, tagId);
    });

    test('Профиль пользователя и замеры', () async {
      final userId = await db
          .into(db.userProfiles)
          .insert(
            UserProfilesCompanion.insert(
              name: Value('Пётр'),
              birthDate: Value(DateTime(1990, 5, 10)),
              heightCm: Value(175.0),
              weightKg: Value(70.0),
              gender: Value('male'),
            ),
          );

      await db
          .into(db.bodyMeasurements)
          .insert(
            BodyMeasurementsCompanion.insert(
              date: DateTime(2026, 4, 4),
              heightCm: Value(175.0),
              weightKg: Value(69.5),
              waistCm: Value(82.0),
            ),
          );

      final profile = (await db.select(db.userProfiles).getSingle());
      expect(profile.id, userId);
      expect(profile.name, 'Пётр');
      expect(profile.birthDate, DateTime(1990, 5, 10));
      expect(profile.heightCm, 175.0);

      final measurement = (await db.select(db.bodyMeasurements).getSingle());
      expect(measurement.date, DateTime(2026, 4, 4));
      expect(measurement.weightKg, 69.5);
      expect(measurement.waistCm, 82.0);
    });
  });
}
