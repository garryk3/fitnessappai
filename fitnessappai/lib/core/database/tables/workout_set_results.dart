import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';
import 'package:fitnessappai/core/database/converters/enum_converters.dart';
import 'package:fitnessappai/core/database/tables/exercises.dart';
import 'package:fitnessappai/core/database/tables/workout_sessions.dart';

/// Результат одного подхода в тренировочной сессии.
@DataClassName('WorkoutSetResultRow')
class WorkoutSetResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().nullable().references(
    Exercises,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get exerciseName => text()();
  TextColumn get exerciseType => text().map(const ExerciseTypeConverter())();
  IntColumn get setIndex => integer()();
  IntColumn get reps => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  IntColumn get completedAt => integer().map(const DateTimeConverter())();
}
