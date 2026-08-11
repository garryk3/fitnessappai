import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';
import 'package:fitnessappai/core/database/converters/enum_converters.dart';
import 'package:fitnessappai/core/database/converters/string_list_converter.dart';
import 'package:fitnessappai/core/database/seed/reference_seeder.dart';
import 'package:fitnessappai/core/database/tables/app_meta.dart';
import 'package:fitnessappai/core/database/tables/body_measurements.dart';
import 'package:fitnessappai/core/database/tables/contraindication_tags.dart';
import 'package:fitnessappai/core/database/tables/exercise_contraindications.dart';
import 'package:fitnessappai/core/database/tables/exercise_muscles.dart';
import 'package:fitnessappai/core/database/tables/exercises.dart';
import 'package:fitnessappai/core/database/tables/muscle_groups.dart';
import 'package:fitnessappai/core/database/tables/program_day_exercises.dart';
import 'package:fitnessappai/core/database/tables/program_days.dart';
import 'package:fitnessappai/core/database/tables/programs.dart';
import 'package:fitnessappai/core/database/tables/schedule_marks.dart';
import 'package:fitnessappai/core/database/tables/user_contraindications.dart';
import 'package:fitnessappai/core/database/tables/user_profiles.dart';
import 'package:fitnessappai/core/database/tables/workout_reminders.dart';
import 'package:fitnessappai/core/database/tables/workout_sessions.dart';
import 'package:fitnessappai/core/database/tables/workout_set_results.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';

part 'app_database.g.dart';

/// Точка входа в локальную БД SQLite.
///
/// В проде используется файл `fitnessappai.sqlite` в documents-каталоге,
/// в тестах — [QueryExecutor] с [NativeDatabase.memory] или in-memory.
@DriftDatabase(
  tables: [
    AppMeta,
    MuscleGroups,
    ContraindicationTags,
    Exercises,
    UserProfiles,
    ExerciseMuscles,
    ExerciseContraindications,
    UserContraindications,
    Programs,
    ProgramDays,
    ProgramDayExercises,
    WorkoutReminders,
    WorkoutSessions,
    WorkoutSetResults,
    ScheduleMarks,
    BodyMeasurements,
  ],
)
/// Версия схемы БД; записывается в `PRAGMA user_version` и используется
/// при валидации импортируемых файлов.
const int appDatabaseSchemaVersion = 1;

class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
    : super(executor ?? driftDatabase(name: 'fitnessappai'));

  @override
  int get schemaVersion => appDatabaseSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await ReferenceSeeder(this).seed();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
