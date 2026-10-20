import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/theme/status_colors.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/progress/ui/progress_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

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
    return AppScaffold(
      appBar: AppTopBar(
        leading: const AppMenuButton(),
        title: AppLocalizations.of(context).navProgress,
        large: true,
      ),
      body: SignalBuilder(builder: (_) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = _controller;
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = AppLocalizations.of(context);
    final period = AppSegmentedButton<StatPeriod>(
      expanded: true,
      segments: [
        AppSegment(value: StatPeriod.week, label: l10n.progressPeriodWeek),
        AppSegment(value: StatPeriod.month, label: l10n.progressPeriodMonth),
        AppSegment(value: StatPeriod.year, label: l10n.progressPeriodYear),
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
              child: AppEmptyState(
                icon: Icons.bar_chart_outlined,
                title: l10n.progressEmpty,
                hint: l10n.progressEmptyHint,
              ),
            ),
          ],
        ),
      );
    }
    return AppListView(
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

/// Единая градиентная карточка статистики (54.8, образец `IMG_..._204452`):
/// Тренировки / Дистанция / Время планки — три колонки через вертикальный
/// разделитель. Тап по «Тренировкам» → история (e2e-контракт).
class _StatCards extends StatelessWidget {
  const _StatCards({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final distanceKm = controller.totalDistanceMeters.value / 1000;
    final exerciseMinutes = _fmt(controller.exerciseTime.value.inSeconds / 60);
    final column = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final caption = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget cell({
      required IconData icon,
      required String value,
      required String label,
      VoidCallback? onTap,
    }) {
      final content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: Column(
          children: [
            AppIcon(
              icon,
              size: 20,
              color: onTap != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            // FittedBox: значение ужимается, а не обрезается, при
            // fontScale 1.3–1.5 (design-review 54.8).
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AppText(value, style: column, maxLines: 1),
            ),
            const SizedBox(height: 2),
            AppText(
              label,
              style: caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
      final child = onTap == null
          ? content
          // Явный affordance и семантика кнопки (design-review 54.8).
          : Semantics(
              button: true,
              label: label,
              child: AppInkWell(
                borderRadius: BorderRadius.circular(AppRadii.xl),
                onTap: onTap,
                child: content,
              ),
            );
      return Expanded(child: child);
    }

    // Разделители колонок: в тёмной теме — приглушённая линия ролей
    // (outlineVariant светлее роли surface на near-black), в светлой —
    // канонический outlineVariant (design-review 54.8).
    final dividerColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface.withValues(alpha: AppTints.faint)
        : theme.colorScheme.outlineVariant;
    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: AppContainer(
        width: 1,
        height: double.infinity,
        color: dividerColor,
      ),
    );

    // Фон (54.8, fix design-review): в тёмной теме — тёмный градиент-токен
    // heroCard по образцу (светлые роли ≥4.5:1, проверяется токен-тестом);
    // светлая тема без near-black поверхностей (DESIGN.md §11) — лёгкий
    // ролевой градиент (токен, паттерн home-hero 54.3).
    final cardGradient = theme.brightness == Brightness.dark
        ? AppGradients.heroCard
        : AppGradients.roleSurface(theme.colorScheme);

    return AppCard(
      gradient: cardGradient,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              icon: Icons.fitness_center,
              value: '${controller.workoutCount.value}',
              label: l10n.progressWorkouts,
              onTap: () => context.go('/history'),
            ),
            divider,
            cell(
              icon: Icons.directions_run,
              value: '${_fmt(distanceKm)} ${l10n.workoutUnitKm}',
              label: l10n.progressDistance,
            ),
            divider,
            cell(
              icon: Icons.timer_outlined,
              value: '$exerciseMinutes ${l10n.workoutUnitMinutes}',
              label: l10n.progressTotalTime,
            ),
          ],
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
    // Два последних непустых среза (54.8, образец): светлые колонки-акцент.
    final highlighted = <int>{};
    for (var i = counts.length - 1; i >= 0 && highlighted.length < 2; i--) {
      if (counts[i] > 0) {
        highlighted.add(i);
      }
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              l10n.progressWorkoutsChart,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const rodWidth = 16.0;
                final barGroups = [
                  for (var i = 0; i < counts.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: counts[i].toDouble(),
                          width: rodWidth,
                          gradient: AppGradients.chartLine(theme.brightness),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ],
                    ),
                ];
                // Центры групп в пикселях — та же формула, что в
                // BarChartPainter.paint → calculateGroupsX (spaceEvenly;
                // usableSize = viewSize, т.к. виртуального rect нет).
                final groupsX = _evenlyGroupCenters(
                  viewWidth: constraints.maxWidth,
                  count: barGroups.length,
                  groupWidth: rodWidth,
                );
                // Подложка шире столбика на 4 px с каждой стороны
                // (24 px вместо 16 px) — читается в обеих темах.
                const columnHalf = 12.0;
                final scale = BarChartData().maxX / constraints.maxWidth;
                final annotations = [
                  for (final i in highlighted)
                    VerticalRangeAnnotation(
                      x1: (groupsX[i] - columnHalf) * scale,
                      x2: (groupsX[i] + columnHalf) * scale,
                      color: theme.colorScheme.surfaceContainerHigh,
                    ),
                ];
                final chartData = BarChartData(
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
                    horizontalInterval: niceInterval(maxY),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.chartGrid,
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
                            child: AppText(
                              labels[index],
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Подложка-колонка двух последних непустых срезов
                  // (54.8, образец «выделенных месяцев»): рисуется
                  // AxisChartPainter.paint() ДО баров (drawRangeAnnotation),
                  // поэтому видна за столбиком в обеих темах. `verticalLines`
                  // в BarChart fl_chart 1.2.0 не рисуются (issue #1149) —
                  // подложка только через rangeAnnotations.
                  rangeAnnotations: RangeAnnotations(
                    verticalRangeAnnotations: annotations,
                  ),
                  barGroups: barGroups,
                );
                return SizedBox(height: 160, child: BarChart(chartData));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Центры групп в пикселях при `BarChartAlignment.spaceEvenly` — та же
  /// формула, что в `BarChartDataExtension.calculateGroupsX` (fl_chart,
  /// не экспортируется публично; src-импорт запрещён линтом
  /// `implementation_imports`). Если группы не помещаются — fl_chart
  /// переключается на равномерное заполнение (пространство межгрупп).
  List<double> _evenlyGroupCenters({
    required double viewWidth,
    required int count,
    required double groupWidth,
  }) {
    if (count == 0) {
      return const [];
    }
    final free = viewWidth - count * groupWidth;
    if (free < 0) {
      // Fallback fl_chart: пространство делится между группами.
      final eachSpace = viewWidth / (count + 1);
      return [
        for (var i = 0; i < count; i++) eachSpace * (i + 1) + groupWidth / 2,
      ];
    }
    final eachSpace = free / (count + 1);
    return [
      for (var i = 0; i < count; i++)
        eachSpace * (i + 1) + groupWidth * (i + 0.5),
    ];
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
    final rawValues = _displayValues(selected?.type);
    final rawLabels = _sliceLabels(context);
    final trimCount = _trailingZeroCount(rawValues);
    final values = rawValues.sublist(0, rawValues.length - trimCount);
    final labels = rawLabels.sublist(0, rawLabels.length - trimCount);
    final unitSuffix = _unitSuffix(l10n, selected?.type);
    final leftReserved = unitSuffix.isNotEmpty ? 48.0 : 32.0;
    final maxY = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final yInterval = niceInterval(maxY);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    l10n.progressMetricChart,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const AppIcon(Icons.trending_up),
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
                    child: AppText(
                      exercise.name,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.chartGrid,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: leftReserved,
                        maxIncluded: false,
                        getTitlesWidget: (value, meta) {
                          final label = _yAxisLabel(
                            value,
                            unitSuffix,
                            yInterval,
                          );
                          return AppText(
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
                            child: AppText(
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
                      barWidth: 3,
                      gradient: AppGradients.chartLine(theme.brightness),
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: AppGradients.chartLine(
                          theme.brightness,
                        ).withOpacity(AppTints.faint),
                      ),
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
      ExerciseType.distance => [for (final v in values) v / 1000],
      ExerciseType.plank => [for (final v in values) v / 60],
      ExerciseType.bodyweight || ExerciseType.strength || null => values,
    };
  }

  String _unitSuffix(AppLocalizations l10n, ExerciseType? type) =>
      switch (type) {
        ExerciseType.plank => l10n.workoutUnitMinutes,
        ExerciseType.distance => l10n.workoutUnitKm,
        ExerciseType.bodyweight => l10n.workoutUnitReps,
        ExerciseType.strength || null => l10n.workoutUnitKg,
      };

  int _trailingZeroCount(List<double> values) {
    var count = 0;
    for (var i = values.length - 1; i >= 0 && values[i] == 0.0; i--) {
      count++;
    }
    return count;
  }

  String _yAxisLabel(double value, String suffix, double interval) {
    // Точность подписи — из интервала сетки: иначе деления меньше 0.1
    // склеиваются при округлении до 1 знака («0.1, 0.1, 0.2, 0.2»).
    final decimals = interval < 1
        ? math.max(1, (-math.log(interval) / math.ln10).ceil())
        : 0;
    final formatted = decimals > 0
        ? value.toStringAsFixed(decimals)
        : value.round().toString();
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(l10n.progressMuscleLoad, style: theme.textTheme.titleSmall),
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
                child: AppText(
                  load.muscleGroup.labelRu,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: hasChildren ? FontWeight.w600 : null,
                  ),
                ),
              ),
              AppText(
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
                  child: AppText(
                    child.muscleGroup.labelRu,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                AppText(
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

/// Вычисляет «красивый» интервал для оси Y по алгоритму nice numbers.
///
/// Возвращает значение из ряда 1, 2, 5, 10, 20, 50, 100, 200, 500…
/// так, чтобы на графике было ~5–8 горизонтальных линий сетки.
double niceInterval(double maxValue, {int targetTicks = 6}) {
  if (maxValue <= 0) {
    return 1;
  }
  final rough = maxValue / targetTicks;
  if (rough <= 0) {
    return 1;
  }
  final magnitude = _pow10((math.log(rough) / math.ln10).floor());
  final residual = rough / magnitude;
  if (residual <= 1.5) {
    return magnitude;
  } else if (residual <= 3) {
    return 2 * magnitude;
  } else if (residual <= 7) {
    return 5 * magnitude;
  }
  return 10 * magnitude;
}

double _pow10(int exponent) {
  var result = 1.0;
  for (var i = 0; i < exponent.abs(); i++) {
    result *= 10;
  }
  return exponent < 0 ? 1 / result : result;
}
