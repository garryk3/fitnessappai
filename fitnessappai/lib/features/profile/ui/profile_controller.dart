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
  final Signal<int?> selectedYear = Signal(DateTime.now().year);
  final Signal<List<int>> availableYears = Signal(const []);

  /// Перезагружает замеры и график после внешних изменений.
  Future<void> reload() => _load();

  /// Выбирает год фильтра (null — все годы) и перезагружает данные.
  Future<void> selectYear(int? year) async {
    if (year == selectedYear.value) {
      return;
    }
    selectedYear.value = year;
    await _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final all = await measurementRepository.getAll();
      final years = all.map((m) => m.date.year).toSet().toList()..sort();
      availableYears.value = years;
      final year = selectedYear.value;
      measurements.value = year == null
          ? all
          : all.where((m) => m.date.year == year).toList();
      latest.value = all.isEmpty ? null : all.last;
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
    final year = selectedYear.value;
    final start = year == null ? DateTime(2000) : DateTime(year, 1, 1);
    final end = year == null
        ? DateTime(2100)
        : DateTime(year, 12, 31, 23, 59, 59, 999);
    final raw = await measurementRepository.history(
      selectedMetric.value,
      start,
      end,
    );
    // Дедупликация: при нескольких замерах за день берём последний.
    final byDate = <DateTime, MetricPoint>{};
    for (final point in raw) {
      final day = DateTime(point.date.year, point.date.month, point.date.day);
      byDate[day] = point;
    }
    final deduped = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    // Для одного замера добавляем «сегодня» как опорную точку (горизонтальная
    // линия).
    if (deduped.length == 1) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastValue = deduped.first.value;
      deduped.add(MetricPoint(date: today, value: lastValue));
    }
    // Ограничиваем количество точек: при >30 — агрегируем по неделям.
    if (deduped.length > 30) {
      final byWeek = <DateTime, MetricPoint>{};
      for (final point in deduped) {
        final weekStart = point.date.subtract(
          Duration(days: point.date.weekday - 1),
        );
        final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
        byWeek[key] = point;
      }
      chartPoints.value = byWeek.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } else {
      chartPoints.value = deduped;
    }
  }
}
