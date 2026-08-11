import 'package:signals/signals.dart';

import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/domain/metric_point.dart';

/// Управляет экраном профиля: замеры, график и история.
class ProfileController {
  ProfileController({required this.measurementRepository}) {
    _load();
  }

  final BodyMeasurementRepository measurementRepository;

  final Signal<bool> isLoading = Signal(true);
  final Signal<BodyMeasurement?> latest = Signal(null);
  final Signal<List<BodyMeasurement>> measurements = Signal(const []);
  final Signal<BodyMetric> selectedMetric = Signal(BodyMetric.weight);
  final Signal<List<MetricPoint>> chartPoints = Signal(const []);

  /// Перезагружает замеры и график после внешних изменений.
  Future<void> reload() => _load();

  Future<void> _load() async {
    isLoading.value = true;
    try {
      measurements.value = await measurementRepository.getAll();
      latest.value = measurements.value.isEmpty
          ? null
          : measurements.value.last;
      await _refreshChart();
    } finally {
      isLoading.value = false;
    }
  }

  /// Переключает метрику графика.
  Future<void> selectMetric(BodyMetric metric) async {
    if (metric == selectedMetric.value) {
      return;
    }
    selectedMetric.value = metric;
    await _refreshChart();
  }

  /// Добавляет замер и перезагружает данные.
  Future<void> addMeasurement(BodyMeasurement measurement) async {
    await measurementRepository.add(measurement);
    await _load();
  }

  /// Удаляет замер по id и перезагружает данные.
  Future<void> deleteMeasurement(int id) async {
    await measurementRepository.delete(id);
    await _load();
  }

  Future<void> _refreshChart() async {
    chartPoints.value = await measurementRepository.history(
      selectedMetric.value,
      DateTime(2000),
      DateTime(2100),
    );
  }
}
