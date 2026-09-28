import 'package:drift/drift.dart';

import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';

/// Сохраняет тип упражнения в TEXT-колонке по имени
/// (strength/bodyweight/plank/distance).
///
/// Чтение толерантно к прежним значениям: `running` и `bike` читаются как
/// `distance` (задача 47.13). Миграция 14→15 переписывает такие строки, но
/// конвертер не должен падать и на базе, которую по каким-то причинам не
/// обновили.
class ExerciseTypeConverter extends TypeConverter<ExerciseType, String> {
  const ExerciseTypeConverter();

  @override
  ExerciseType fromSql(String fromDb) {
    final type = exerciseTypeFromName(fromDb);
    if (type == null) {
      throw ArgumentError.value(
        fromDb,
        'fromDb',
        'Неизвестный тип упражнения в БД',
      );
    }
    return type;
  }

  @override
  String toSql(ExerciseType value) => value.name;
}

/// Сохраняет сторону диаграммы (front/back) в TEXT-колонке.
class MuscleViewConverter extends TypeConverter<MuscleView, String> {
  const MuscleViewConverter();

  @override
  MuscleView fromSql(String fromDb) => MuscleView.values.byName(fromDb);

  @override
  String toSql(MuscleView value) => value.name;
}

/// Сохраняет степень нагрузки (primary/secondary) в TEXT-колонке.
class MuscleIntensityConverter extends TypeConverter<MuscleIntensity, String> {
  const MuscleIntensityConverter();

  @override
  MuscleIntensity fromSql(String fromDb) =>
      MuscleIntensity.values.byName(fromDb);

  @override
  String toSql(MuscleIntensity value) => value.name;
}

/// Сохраняет вариант тренировки (main/alternative) в TEXT-колонке.
class WorkoutVariantConverter extends TypeConverter<WorkoutVariant, String> {
  const WorkoutVariantConverter();

  @override
  WorkoutVariant fromSql(String fromDb) => WorkoutVariant.values.byName(fromDb);

  @override
  String toSql(WorkoutVariant value) => value.name;
}

/// Сохраняет статус отметки (skipped) в TEXT-колонке.
class ScheduleMarkStatusConverter
    extends TypeConverter<ScheduleMarkStatus, String> {
  const ScheduleMarkStatusConverter();

  @override
  ScheduleMarkStatus fromSql(String fromDb) =>
      ScheduleMarkStatus.values.byName(fromDb);

  @override
  String toSql(ScheduleMarkStatus value) => value.name;
}
