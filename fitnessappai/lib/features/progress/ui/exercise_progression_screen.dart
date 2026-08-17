import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран динамики упражнения: прогрессия метрики по датам тренировок.
class ExerciseProgressionScreen extends StatefulWidget {
  const ExerciseProgressionScreen({
    super.key,
    required this.exerciseId,
    this.statsAggregator,
    this.exerciseRepository,
  });

  final int exerciseId;
  final StatsAggregator? statsAggregator;
  final ExerciseRepository? exerciseRepository;

  @override
  State<ExerciseProgressionScreen> createState() =>
      _ExerciseProgressionScreenState();
}

class _ExerciseProgressionScreenState extends State<ExerciseProgressionScreen> {
  late final StatsAggregator _aggregator;
  late final ExerciseRepository _exerciseRepository;
  Exercise? _exercise;
  List<ProgressionPoint> _points = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _aggregator = widget.statsAggregator ?? locator.get<StatsAggregator>();
    _exerciseRepository =
        widget.exerciseRepository ?? locator.get<ExerciseRepository>();
    _load();
  }

  Future<void> _load() async {
    final exercise = await _exerciseRepository.getById(widget.exerciseId);
    final points = await _aggregator.exerciseProgression(widget.exerciseId);
    if (!mounted) {
      return;
    }
    setState(() {
      _exercise = exercise;
      _points = points;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_exercise?.name ?? l10n.progressProgression)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercise == null
          ? Center(
              child: Text(
                l10n.exerciseDetailNotFound,
                style: theme.textTheme.titleMedium,
              ),
            )
          : _points.isEmpty
          ? Center(
              child: Text(
                l10n.progressProgressionEmpty,
                style: theme.textTheme.titleMedium,
              ),
            )
          : _buildBody(context, _exercise!),
    );
  }

  Widget _buildBody(BuildContext context, Exercise exercise) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final maxPoint = _points.reduce((a, b) => b.metric > a.metric ? b : a);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.progressMetricChart,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.progressProgressionMax}: '
                  '${_formatMetric(l10n, exercise.type, maxPoint.metric)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: LineChart(_chartData(context, exercise)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final point in _points)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('d MMMM yyyy', 'ru').format(point.date),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  _formatMetric(l10n, exercise.type, point.metric),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  LineChartData _chartData(BuildContext context, Exercise exercise) {
    final theme = Theme.of(context);
    final maxY = _points.fold<double>(
      0,
      (max, p) => p.metric > max ? p.metric : max,
    );
    return LineChartData(
      minY: 0,
      maxY: maxY <= 0 ? 1 : maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => [
            for (final spot in spots)
              LineTooltipItem(
                '${DateFormat('d MMM', 'ru').format(_points[spot.x.toInt()].date)}\n'
                '${_formatMetricValue(exercise.type, spot.y)}',
                const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final title = _formatMetricValue(exercise.type, value);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: _points.length > 1 ? 1 : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('d MMM', 'ru').format(_points[index].date),
                  style: theme.textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < _points.length; i++)
              FlSpot(i.toDouble(), _points[i].metric),
          ],
          isCurved: false,
          barWidth: 2,
          color: theme.colorScheme.primary,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  String _formatMetric(AppLocalizations l10n, ExerciseType type, double value) {
    return switch (type) {
      ExerciseType.strength => '${_fmt(value)} ${l10n.workoutUnitKg}',
      ExerciseType.bodyweight => '${value.round()} ${l10n.workoutUnitReps}',
      ExerciseType.running => '${_fmt(value / 1000)} ${l10n.workoutUnitKm}',
      ExerciseType.plank => '${_fmt(value / 60)} ${l10n.workoutUnitMinutes}',
    };
  }

  String _formatMetricValue(ExerciseType type, double value) {
    return switch (type) {
      ExerciseType.strength || ExerciseType.bodyweight => _fmt(value),
      ExerciseType.running => _fmt(value / 1000),
      ExerciseType.plank => _fmt(value / 60),
    };
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
