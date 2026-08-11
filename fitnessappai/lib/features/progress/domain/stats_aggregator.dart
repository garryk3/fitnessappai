import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Период агрегации статистики.
enum StatPeriod { week, month, year }

/// Доля нагрузки на мышечную группу в процентах.
class MuscleLoad {
  const MuscleLoad({required this.muscleGroup, required this.percent});

  final MuscleGroup muscleGroup;
  final double percent;

  @override
  String toString() =>
      'MuscleLoad(${muscleGroup.key}: ${percent.toStringAsFixed(1)}%)';
}

/// Агрегация статистики тренировок за период.
///
/// Границы периода: неделя — с понедельника, месяц — с 1-го числа,
/// год — с 1 января. Период включает начало и не включает конец.
class StatsAggregator {
  StatsAggregator({
    required this.workoutRepository,
    required this.exerciseRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final DateTime Function() _clock;

  /// Границы периода `[start, end)`.
  (DateTime, DateTime) periodBounds(StatPeriod period) {
    final now = _clock();
    switch (period) {
      case StatPeriod.week:
        final monday = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - DateTime.monday),
        );
        return (monday, monday.add(const Duration(days: 7)));
      case StatPeriod.month:
        final first = DateTime(now.year, now.month, 1);
        return (first, DateTime(now.year, now.month + 1, 1));
      case StatPeriod.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
    }
  }

  /// Срезы периода для графиков: неделя — 7 дней, месяц — недели
  /// (с понедельника, крайние срезы укорочены), год — 12 месяцев.
  List<(DateTime, DateTime)> slices(StatPeriod period) {
    final (start, end) = periodBounds(period);
    switch (period) {
      case StatPeriod.week:
        return [
          for (var i = 0; i < 7; i++)
            (start.add(Duration(days: i)), start.add(Duration(days: i + 1))),
        ];
      case StatPeriod.month:
        final result = <(DateTime, DateTime)>[];
        var cursor = start;
        while (cursor.isBefore(end)) {
          final daysToMonday = cursor.weekday == DateTime.monday
              ? 7
              : DateTime.daysPerWeek + DateTime.monday - cursor.weekday;
          final nextMonday = cursor.add(Duration(days: daysToMonday));
          final sliceEnd = nextMonday.isBefore(end) ? nextMonday : end;
          result.add((cursor, sliceEnd));
          cursor = sliceEnd;
        }
        return result;
      case StatPeriod.year:
        return [
          for (var month = 1; month <= 12; month++)
            (
              DateTime(start.year, month, 1),
              DateTime(start.year, month + 1, 1),
            ),
        ];
    }
  }

  /// Количество тренировок за период.
  Future<int> workoutCount(StatPeriod period) async {
    final sessions = await _sessions(period);
    return sessions.length;
  }

  /// Суммарная дистанция бега в метрах.
  Future<double> totalDistance(StatPeriod period) async {
    final results = await _results(period);
    return results.fold<double>(
      0,
      (sum, r) => r.exerciseType == ExerciseType.running
          ? sum + (r.distanceMeters ?? 0)
          : sum,
    );
  }

  /// Суммарное время планки.
  Future<Duration> totalPlankTime(StatPeriod period) async {
    final results = await _results(period);
    final seconds = results.fold<int>(
      0,
      (sum, r) => r.exerciseType == ExerciseType.plank
          ? sum + (r.durationSeconds ?? 0)
          : sum,
    );
    return Duration(seconds: seconds);
  }

  /// Максимальный вес в упражнении (null, если подходов с весом не было).
  Future<double?> maxWeight(int exerciseId, StatPeriod period) async {
    final results = await _results(period);
    double? max;
    for (final r in results) {
      if (r.exerciseId != exerciseId || r.weightKg == null) {
        continue;
      }
      if (max == null || r.weightKg! > max) {
        max = r.weightKg;
      }
    }
    return max;
  }

  /// Суммарные повторения в упражнении.
  Future<int> totalReps(int exerciseId, StatPeriod period) async {
    final results = await _results(period);
    return results.fold<int>(
      0,
      (sum, r) => r.exerciseId == exerciseId ? sum + (r.reps ?? 0) : sum,
    );
  }

  /// Количество тренировок по срезам периода (см. [slices]).
  Future<List<int>> workoutCountPerSlice(StatPeriod period) async {
    final sessions = await _sessions(period);
    return slices(period).map((slice) {
      final (start, end) = slice;
      return sessions
          .where(
            (s) =>
                !s.performedDate.isBefore(start) &&
                s.performedDate.isBefore(end),
          )
          .length;
    }).toList();
  }

  /// Распределение нагрузки по мышечным группам в процентах.
  ///
  /// Каждый выполненный подход даёт primary-мышцам вес 1.0 и secondary 0.5.
  /// Подходы удалённых упражнений (без привязок мышц) не учитываются.
  /// Сумма процентов ≈ 100 при непустой нагрузке.
  Future<List<MuscleLoad>> muscleLoadPercent(StatPeriod period) async {
    final results = await _results(period);
    final weights = <int, double>{};
    final musclesCache = <int, List<ExerciseMuscle>>{};
    for (final result in results) {
      final exerciseId = result.exerciseId;
      if (exerciseId == null) {
        continue;
      }
      final List<ExerciseMuscle> muscles;
      if (musclesCache.containsKey(exerciseId)) {
        muscles = musclesCache[exerciseId]!;
      } else {
        muscles = await exerciseRepository.getMuscles(exerciseId);
        musclesCache[exerciseId] = muscles;
      }
      for (final muscle in muscles) {
        final weight = switch (muscle.intensity) {
          MuscleIntensity.primary => 1.0,
          MuscleIntensity.secondary => 0.5,
        };
        weights.update(
          muscle.muscleGroupId,
          (value) => value + weight,
          ifAbsent: () => weight,
        );
      }
    }
    if (weights.isEmpty) {
      return const [];
    }
    final total = weights.values.fold<double>(0, (sum, w) => sum + w);
    final groups = {
      for (final group in await exerciseRepository.getAllMuscleGroups())
        group.id: group,
    };
    final loads = <MuscleLoad>[];
    for (final entry in weights.entries) {
      final group = groups[entry.key];
      if (group == null) {
        continue;
      }
      loads.add(
        MuscleLoad(muscleGroup: group, percent: entry.value / total * 100),
      );
    }
    loads.sort((a, b) => b.percent.compareTo(a.percent));
    return loads;
  }

  /// Метрика упражнения по срезам периода для графика прогресса.
  ///
  /// strength — максимальный вес в срезе (кг), running — суммарная
  /// дистанция (м), plank — суммарное время (с). Пустые срезы — 0.
  Future<List<double>> exerciseMetricPerSlice(
    int exerciseId,
    StatPeriod period,
  ) async {
    final exercise = await exerciseRepository.getById(exerciseId);
    if (exercise == null) {
      return List.filled(slices(period).length, 0.0);
    }
    final results = (await _results(
      period,
    )).where((r) => r.exerciseId == exerciseId).toList();
    return slices(period).map((slice) {
      final (start, end) = slice;
      final inSlice = results
          .where(
            (r) =>
                !r.completedAt.isBefore(start) && r.completedAt.isBefore(end),
          )
          .toList();
      switch (exercise.type) {
        case ExerciseType.strength:
          var max = 0.0;
          for (final r in inSlice) {
            if (r.weightKg != null && r.weightKg! > max) {
              max = r.weightKg!;
            }
          }
          return max;
        case ExerciseType.running:
          return inSlice.fold<double>(
            0,
            (sum, r) => sum + (r.distanceMeters ?? 0),
          );
        case ExerciseType.plank:
          return inSlice.fold<double>(
            0,
            (sum, r) => sum + (r.durationSeconds ?? 0),
          );
      }
    }).toList();
  }

  Future<List<WorkoutSession>> _sessions(StatPeriod period) {
    final (start, end) = periodBounds(period);
    return workoutRepository.getSessionsBetween(start, end);
  }

  Future<List<WorkoutSetResult>> _results(StatPeriod period) async {
    final sessions = await _sessions(period);
    final results = <WorkoutSetResult>[];
    for (final session in sessions) {
      final detail = await workoutRepository.getSession(session.id!);
      if (detail != null) {
        results.addAll(detail.results);
      }
    }
    return results;
  }
}
