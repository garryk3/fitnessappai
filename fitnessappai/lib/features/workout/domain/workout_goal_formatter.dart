import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/workout/domain/workout_exercise.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Форматирование цели сета и сводки параметров позиции (64.7, вариант A).
///
/// Один источник для бейджа «Цель: …» в карточке прошлой тренировки (54.6)
/// и сводки параметров на экране упражнения (59.4), чтобы строки не
/// расходились. Учитывает тип упражнения: силовое — повторения (+ вес),
/// свой вес — повторения, планка — время удержания, дистанция — км (+ мин).
class WorkoutGoalFormatter {
  const WorkoutGoalFormatter._();

  /// Цель одного подхода без префикса «Цель:», например `8 повт · 20 кг`.
  /// Значимых параметров не задано — null (бейдж не показывается).
  static String? perSet(AppLocalizations l10n, WorkoutExercise exercise) {
    final position = exercise.position;
    final parts = <String>[];
    switch (exercise.type) {
      case ExerciseType.strength || ExerciseType.bodyweight:
        if ((position.reps ?? 0) > 0) {
          parts.add('${position.reps} ${l10n.workoutUnitReps}');
        }
        if (exercise.type == ExerciseType.strength &&
            (position.weightKg ?? 0) > 0) {
          parts.add('${_fmt(position.weightKg!)} ${l10n.workoutUnitKg}');
        }
      case ExerciseType.plank:
        if ((position.durationSeconds ?? 0) > 0) {
          parts.add('${position.durationSeconds} ${l10n.workoutUnitSeconds}');
        }
      case ExerciseType.distance:
        if ((position.distanceMeters ?? 0) > 0) {
          parts.add(
            '${_fixed(position.distanceMeters! / 1000)} '
            '${l10n.workoutUnitKm}',
          );
        }
        if ((position.durationSeconds ?? 0) > 0) {
          parts.add(
            '${_fixed(position.durationSeconds! / 60)} '
            '${l10n.workoutUnitMinutes}',
          );
        }
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' · ');
  }

  /// Сводка параметров позиции с числом подходов: `3 × 8 повт · 20 кг`.
  /// Для дистанции подходы не добавляются (типично одно подход-упражнение).
  static String summary(AppLocalizations l10n, WorkoutExercise exercise) {
    final perSetLabel = perSet(l10n, exercise);
    if (perSetLabel == null) {
      return '';
    }
    if (exercise.type == ExerciseType.distance) {
      return perSetLabel;
    }
    final sets = exercise.position.sets ?? 0;
    return sets > 0 ? '$sets × $perSetLabel' : perSetLabel;
  }

  static String _fmt(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  /// Фиксированный один знак (км, мин) — как в прежней сводке параметров.
  static String _fixed(double value) => value.toStringAsFixed(1);
}
