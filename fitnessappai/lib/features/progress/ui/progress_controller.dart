import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';

/// Управляет экраном прогресса: период, карточки, графики, нагрузка на мышцы.
class ProgressController {
  ProgressController({
    required this.statsAggregator,
    required this.exerciseRepository,
    DataChangeNotifier? changes,
  }) {
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final StatsAggregator statsAggregator;
  final ExerciseRepository exerciseRepository;
  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<StatPeriod> period = Signal(StatPeriod.week);
  final Signal<bool> isLoading = Signal(true);
  final Signal<int> workoutCount = Signal(0);
  final Signal<double> totalDistanceMeters = Signal(0);
  final Signal<Duration> plankTime = Signal(Duration.zero);
  final Signal<List<int>> countsPerSlice = Signal(const []);
  final Signal<List<MuscleLoad>> muscleLoads = Signal(const []);
  final Signal<List<Exercise>> exercises = Signal(const []);
  final Signal<int?> selectedExerciseId = Signal(null);
  final Signal<List<double>> metricPerSlice = Signal(const []);

  Future<void> setPeriod(StatPeriod value) async {
    if (period.value == value) {
      return;
    }
    period.value = value;
    await _loadStats();
  }

  Future<void> selectExercise(int id) async {
    if (selectedExerciseId.value == id) {
      return;
    }
    selectedExerciseId.value = id;
    isLoading.value = true;
    try {
      await _loadMetric();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final performedIds = await statsAggregator.performedExerciseIds();
      final all = await exerciseRepository.getAll();
      exercises.value = all.where((e) => performedIds.contains(e.id)).toList();
      selectedExerciseId.value = exercises.value.isNotEmpty
          ? exercises.value.first.id
          : null;
      await _loadStats();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStats() async {
    isLoading.value = true;
    try {
      final current = period.value;
      workoutCount.value = await statsAggregator.workoutCount(current);
      totalDistanceMeters.value = await statsAggregator.totalDistance(current);
      plankTime.value = await statsAggregator.totalPlankTime(current);
      countsPerSlice.value = await statsAggregator.workoutCountPerSlice(
        current,
      );
      muscleLoads.value = await statsAggregator.muscleLoadPercent(current);
      await _loadMetric();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMetric() async {
    final id = selectedExerciseId.value;
    if (id == null) {
      metricPerSlice.value = const [];
      return;
    }
    metricPerSlice.value = await statsAggregator.exerciseMetricPerSlice(
      id,
      period.value,
    );
  }

  void dispose() {
    _reloadSubscription.dispose();
  }
}
