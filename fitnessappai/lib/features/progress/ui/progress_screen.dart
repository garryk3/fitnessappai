import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/progress/ui/progress_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран прогресса: карточки метрик, графики и нагрузка на мышцы.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.statsAggregator,
    this.exerciseRepository,
  });

  final StatsAggregator? statsAggregator;
  final ExerciseRepository? exerciseRepository;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProgressController(
      statsAggregator: widget.statsAggregator ?? locator.get<StatsAggregator>(),
      exerciseRepository:
          widget.exerciseRepository ?? locator.get<ExerciseRepository>(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navProgress)),
      body: SignalBuilder(builder: (_) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = _controller;
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = AppLocalizations.of(context);
    final period = SegmentedButton<StatPeriod>(
      segments: [
        ButtonSegment(
          value: StatPeriod.week,
          label: Text(l10n.progressPeriodWeek),
        ),
        ButtonSegment(
          value: StatPeriod.month,
          label: Text(l10n.progressPeriodMonth),
        ),
        ButtonSegment(
          value: StatPeriod.year,
          label: Text(l10n.progressPeriodYear),
        ),
      ],
      selected: {controller.period.value},
      onSelectionChanged: (selection) => _controller.setPeriod(selection.first),
    );
    if (controller.workoutCount.value == 0) {
      return LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: period,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.progressEmpty,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        period,
        const SizedBox(height: 16),
        ...[
          _StatCards(controller: controller),
          const SizedBox(height: 16),
          _WorkoutsChart(controller: controller),
          const SizedBox(height: 16),
          if (controller.exercises.value.isNotEmpty) ...[
            _MetricChart(controller: controller),
            const SizedBox(height: 16),
          ],
          if (controller.muscleLoads.value.isNotEmpty)
            _MuscleLoadPanel(controller: controller),
        ],
      ],
    );
  }
}

/// Карточки «Тренировок», «Дистанция», «Время планки».
class _StatCards extends StatelessWidget {
  const _StatCards({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final distanceKm = controller.totalDistanceMeters.value / 1000;
    final plankMinutes = _fmt(controller.plankTime.value.inSeconds / 60);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: l10n.progressWorkouts,
            value: '${controller.workoutCount.value}',
            icon: Icons.fitness_center,
            onTap: () => context.push('/history'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: l10n.progressDistance,
            value: '${_fmt(distanceKm)} ${l10n.workoutUnitKm}',
            icon: Icons.directions_run,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: l10n.progressPlankTime,
            value: '$plankMinutes ${l10n.workoutUnitMinutes}',
            icon: Icons.self_improvement,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: onTap != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BarChart «Тренировки по срезам».
class _WorkoutsChart extends StatelessWidget {
  const _WorkoutsChart({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final counts = controller.countsPerSlice.value;
    final labels = _sliceLabels(context, controller);
    final maxY = counts.isEmpty
        ? 4.0
        : (counts.reduce((a, b) => a > b ? a : b) + 1).toDouble();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.progressWorkoutsChart, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final index = group.x.toInt();
                        final label = index < 0 || index >= labels.length
                            ? ''
                            : labels[index];
                        return BarTooltipItem(
                          '$label\n${rod.toY.toInt()}',
                          TextStyle(color: theme.colorScheme.onInverseSurface),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) {
                        return;
                      }
                      final touched = response?.spot;
                      if (touched == null) {
                        return;
                      }
                      final index = touched.touchedBarGroupIndex;
                      final slices = controller.statsAggregator.slices(
                        controller.period.value,
                      );
                      if (index < 0 || index >= slices.length) {
                        return;
                      }
                      final (start, end) = slices[index];
                      context.push(
                        '/progress/day'
                        '?start=${start.millisecondsSinceEpoch}'
                        '&end=${end.millisecondsSinceEpoch}',
                      );
                    },
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
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels[index],
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < counts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            width: 12,
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _sliceLabels(
    BuildContext context,
    ProgressController controller,
  ) {
    final l10n = AppLocalizations.of(context);
    final slices = controller.statsAggregator.slices(controller.period.value);
    return switch (controller.period.value) {
      StatPeriod.week => [
        for (final slice in slices) _weekdayLabel(l10n, slice.$1.weekday),
      ],
      StatPeriod.month => [
        for (final slice in slices)
          '${slice.$1.day.toString().padLeft(2, '0')}.'
              '${slice.$1.month.toString().padLeft(2, '0')}',
      ],
      StatPeriod.year => [
        for (final slice in slices) _monthLabel(l10n, slice.$1.month),
      ],
    };
  }
}

/// LineChart «Прогресс метрики» с выбором упражнения.
class _MetricChart extends StatelessWidget {
  const _MetricChart({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercises = controller.exercises.value;
    final selectedId = controller.selectedExerciseId.value;
    final selected = exercises.firstWhereOrNull((e) => e.id == selectedId);
    final values = _displayValues(selected?.type);
    final labels = _sliceLabels(context);
    final unitSuffix = _unitSuffix(selected?.type);
    final leftReserved = unitSuffix.isNotEmpty ? 48.0 : 32.0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.progressMetricChart,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.trending_up),
                  tooltip: l10n.progressProgressionOpen,
                  onPressed: selectedId == null
                      ? null
                      : () => context.push('/progress/exercise/$selectedId'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: selectedId,
              isExpanded: true,
              items: [
                for (final exercise in exercises)
                  DropdownMenuItem(
                    value: exercise.id,
                    child: Text(exercise.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) {
                if (id != null) {
                  controller.selectExercise(id);
                }
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  lineTouchData: LineTouchData(enabled: false),
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
                        reservedSize: leftReserved,
                        getTitlesWidget: (value, meta) {
                          final label = _yAxisLabel(value, unitSuffix);
                          return Text(
                            label,
                            style: theme.textTheme.labelSmall,
                            maxLines: 1,
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels[index],
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
                        for (var i = 0; i < values.length; i++)
                          FlSpot(i.toDouble(), values[i]),
                      ],
                      isCurved: false,
                      barWidth: 2,
                      color: theme.colorScheme.primary,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _displayValues(ExerciseType? type) {
    final values = controller.metricPerSlice.value;
    return switch (type) {
      ExerciseType.running => [for (final v in values) v / 1000],
      ExerciseType.plank => [for (final v in values) v / 60],
      ExerciseType.bodyweight || ExerciseType.strength || null => values,
    };
  }

  String _unitSuffix(ExerciseType? type) => switch (type) {
    ExerciseType.plank => 'м',
    ExerciseType.running => 'км',
    ExerciseType.bodyweight => 'повт',
    ExerciseType.strength || null => 'кг',
  };

  String _yAxisLabel(double value, String suffix) {
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$formatted $suffix';
  }

  List<String> _sliceLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slices = controller.statsAggregator.slices(controller.period.value);
    return switch (controller.period.value) {
      StatPeriod.week => [
        for (final slice in slices) _weekdayLabel(l10n, slice.$1.weekday),
      ],
      StatPeriod.month => [
        for (final slice in slices)
          '${slice.$1.day.toString().padLeft(2, '0')}.'
              '${slice.$1.month.toString().padLeft(2, '0')}',
      ],
      StatPeriod.year => [
        for (final slice in slices) _monthLabel(l10n, slice.$1.month),
      ],
    };
  }
}

/// Панель «Нагрузка на мышцы»: диаграмма и список топ-мышц.
class _MuscleLoadPanel extends StatelessWidget {
  const _MuscleLoadPanel({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final loads = controller.muscleLoads.value;
    final maxPercent = loads.isEmpty ? 0.0 : loads.first.percent;
    final highlights = <String, double>{};
    for (final load in loads) {
      final value = maxPercent == 0 ? 0.0 : load.percent / maxPercent;
      final current = highlights[load.muscleGroup.regionKey] ?? 0.0;
      highlights[load.muscleGroup.regionKey] = current > value
          ? current
          : value;
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.progressMuscleLoad, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MuscleDiagram(
                  view: MuscleView.front,
                  highlights: highlights,
                  size: const Size(110, 220),
                ),
                const SizedBox(width: 16),
                MuscleDiagram(
                  view: MuscleView.back,
                  highlights: highlights,
                  size: const Size(110, 220),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final load in loads) _MuscleGroupTile(load: load),
          ],
        ),
      ),
    );
  }
}

class _MuscleGroupTile extends StatelessWidget {
  const _MuscleGroupTile({required this.load});

  final MuscleGroupLoad load;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = load.children.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  load.muscleGroup.labelRu,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: hasChildren ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Text(
                '${load.percent.toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: hasChildren ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        for (final child in load.children)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    child.muscleGroup.labelRu,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${child.percent.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _weekdayLabel(AppLocalizations l10n, int weekday) => switch (weekday) {
  DateTime.monday => l10n.weekdayMon,
  DateTime.tuesday => l10n.weekdayTue,
  DateTime.wednesday => l10n.weekdayWed,
  DateTime.thursday => l10n.weekdayThu,
  DateTime.friday => l10n.weekdayFri,
  DateTime.saturday => l10n.weekdaySat,
  DateTime.sunday => l10n.weekdaySun,
  _ => '',
};

String _monthLabel(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.monthShortJan,
  2 => l10n.monthShortFeb,
  3 => l10n.monthShortMar,
  4 => l10n.monthShortApr,
  5 => l10n.monthShortMay,
  6 => l10n.monthShortJun,
  7 => l10n.monthShortJul,
  8 => l10n.monthShortAug,
  9 => l10n.monthShortSep,
  10 => l10n.monthShortOct,
  11 => l10n.monthShortNov,
  12 => l10n.monthShortDec,
  _ => '',
};

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
