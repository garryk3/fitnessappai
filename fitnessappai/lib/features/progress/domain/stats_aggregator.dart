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

/// Иерархическая нагрузка на группу мышц.
///
/// Содержит суммарный процент группы и список подгрупп с их долей
/// внутри группы. Для standalone-групп (без детей) `children` пуст.
class MuscleGroupLoad {
  const MuscleGroupLoad({
    required this.muscleGroup,
    required this.percent,
    this.children = const [],
  });

  final MuscleGroup muscleGroup;
  final double percent;
  final List<MuscleGroupLoad> children;

  @override
  String toString() {
    final childStr = children.isEmpty
        ? ''
        : ' (${children.map((c) => '${c.muscleGroup.labelRu} ${c.percent.toStringAsFixed(0)}%').join(', ')})';
    return 'MuscleGroupLoad(${muscleGroup.key}: ${percent.toStringAsFixed(1)}%$childStr)';
  }
}

/// Точка прогрессии упражнения: дата тренировки и значение метрики.
class ProgressionPoint {
  const ProgressionPoint({required this.date, required this.metric});

  final DateTime date;
  final double metric;

  @override
  String toString() => 'ProgressionPoint(${date.toIso8601String()}: $metric)';
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

  /// Множество id упражнений, выполнявшихся хотя бы раз (за всё время).
  Future<Set<int>> performedExerciseIds() =>
      workoutRepository.getPerformedExerciseIds();

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
  ///
  /// Подгруппы агрегируются в родительские группы. Процент подгруппы
  /// показывает долю внутри группы. Standalone-группы (без детей)
  /// отображаются как есть.
  Future<List<MuscleGroupLoad>> muscleLoadPercent(StatPeriod period) async {
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
    final allGroups = await exerciseRepository.getAllMuscleGroups();
    final groupsById = {for (final g in allGroups) g.id: g};
    final groupsByKey = {for (final g in allGroups) g.key: g};

    final childWeights = <String, double>{};
    for (final entry in weights.entries) {
      final group = groupsById[entry.key];
      if (group == null) {
        continue;
      }
      childWeights[group.key] = (childWeights[group.key] ?? 0) + entry.value;
    }

    final parentWeights = <String, double>{};
    final parentChildren = <String, Map<String, double>>{};
    for (final entry in childWeights.entries) {
      final group = groupsByKey[entry.key];
      if (group == null) {
        continue;
      }
      final parentKey = group.parentKey;
      if (parentKey != null) {
        parentWeights[parentKey] =
            (parentWeights[parentKey] ?? 0) + entry.value;
        parentChildren.putIfAbsent(parentKey, () => {}).addAll({
          entry.key: entry.value,
        });
      } else {
        parentWeights[entry.key] =
            (parentWeights[entry.key] ?? 0) + entry.value;
      }
    }

    final loads = <MuscleGroupLoad>[];
    for (final entry in parentWeights.entries) {
      final parentGroup = groupsByKey[entry.key];
      if (parentGroup == null) {
        continue;
      }
      final children = parentChildren[entry.key];
      final childLoads = <MuscleGroupLoad>[];
      if (children != null && children.isNotEmpty && entry.value > 0) {
        final sorted = children.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final child in sorted) {
          final childGroup = groupsByKey[child.key];
          if (childGroup == null) {
            continue;
          }
          childLoads.add(
            MuscleGroupLoad(
              muscleGroup: childGroup,
              percent: child.value / entry.value * 100,
            ),
          );
        }
      }
      loads.add(
        MuscleGroupLoad(
          muscleGroup: parentGroup,
          percent: entry.value / total * 100,
          children: childLoads,
        ),
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
        case ExerciseType.bodyweight:
          return inSlice
              .fold<int>(0, (sum, r) => sum + (r.reps ?? 0))
              .toDouble();
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

  /// Прогрессия упражнения по датам выполнения за всё время.
  ///
  /// strength — максимальный вес за дату (кг), bodyweight — суммарные
  /// повторения, running — суммарная дистанция (м), plank — суммарное
  /// время (с). Точки отсортированы по дате.
  Future<List<ProgressionPoint>> exerciseProgression(int exerciseId) async {
    final exercise = await exerciseRepository.getById(exerciseId);
    if (exercise == null) {
      return const [];
    }
    final values = <DateTime, double>{};
    for (final session in await workoutRepository.getAllSessions()) {
      final detail = await workoutRepository.getSession(session.id!);
      if (detail == null) {
        continue;
      }
      final date = DateTime(
        session.performedDate.year,
        session.performedDate.month,
        session.performedDate.day,
      );
      for (final r in detail.results) {
        if (r.exerciseId != exerciseId) {
          continue;
        }
        final current = values[date] ?? 0.0;
        values[date] = switch (exercise.type) {
          ExerciseType.strength when (r.weightKg ?? 0) > current => r.weightKg!,
          ExerciseType.strength => current,
          ExerciseType.bodyweight => current + (r.reps ?? 0),
          ExerciseType.running => current + (r.distanceMeters ?? 0),
          ExerciseType.plank => current + (r.durationSeconds ?? 0),
        };
      }
    }
    final points = [
      for (final entry in values.entries)
        ProgressionPoint(date: entry.key, metric: entry.value),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// История упражнения за последние [days] дней выполнения.
  ///
  /// Возвращает не более [days] последних точек [exerciseProgression]
  /// (агрегированных по датам тренировок), отсортированных по дате.
  Future<List<ProgressionPoint>> exerciseHistoryLastDays(
    int exerciseId, {
    int days = 3,
  }) async {
    final points = await exerciseProgression(exerciseId);
    if (points.length <= days) {
      return points;
    }
    return points.sublist(points.length - days);
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
    return _dedupPerSide(results);
  }

  /// Убирает дубли для упражнений «по сторонам»: для каждой пары
  /// (exerciseId, setIndex) оставляет только результат с лучшим показателем.
  /// Результаты без `side` (обычные упражнения) не затрагиваются.
  List<WorkoutSetResult> _dedupPerSide(List<WorkoutSetResult> input) {
    final byKey = <String, List<WorkoutSetResult>>{};
    final plain = <WorkoutSetResult>[];
    for (final r in input) {
      if (r.side == null) {
        plain.add(r);
        continue;
      }
      byKey.putIfAbsent('${r.exerciseId}_${r.setIndex}', () => []).add(r);
    }
    if (byKey.isEmpty) {
      return input;
    }
    final out = List<WorkoutSetResult>.from(plain);
    for (final group in byKey.values) {
      if (group.length <= 1) {
        out.addAll(group);
        continue;
      }
      out.add(
        group.reduce((best, current) {
          final bestVal = _metricValue(best);
          final curVal = _metricValue(current);
          return curVal > bestVal ? current : best;
        }),
      );
    }
    return out;
  }

  double _metricValue(WorkoutSetResult r) => switch (r.exerciseType) {
    ExerciseType.strength => r.weightKg ?? 0,
    ExerciseType.bodyweight => (r.reps ?? 0).toDouble(),
    ExerciseType.plank => (r.durationSeconds ?? 0).toDouble(),
    ExerciseType.running => r.distanceMeters ?? 0,
  };
}
