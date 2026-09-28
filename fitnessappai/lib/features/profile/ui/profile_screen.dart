import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/bmi.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/domain/metric_point.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/profile/ui/profile_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Экран профиля: текущие замеры, график динамики и история.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.measurementRepository,
    this.profileRepository,
  });

  final BodyMeasurementRepository? measurementRepository;
  final UserProfileRepository? profileRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(
      measurementRepository:
          widget.measurementRepository ??
          locator.get<BodyMeasurementRepository>(),
      profileRepository:
          widget.profileRepository ?? locator.get<UserProfileRepository>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(l10n.navProfile),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'profile-fab',
        onPressed: () async {
          await context.push('/measurements/new');
          if (mounted) {
            await _controller.reload();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.profileAddMeasurement),
      ),
      body: SignalBuilder(builder: (_) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final measurements = _controller.measurements.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _GenderCard(controller: _controller),
        if (_controller.latest.value != null) ...[
          const SizedBox(height: 12),
          _SummaryCard(latest: _controller.latest.value!),
        ],
        if (_controller.bmi != null) ...[
          const SizedBox(height: 12),
          _BmiCard(controller: _controller),
        ],
        const SizedBox(height: 12),
        _MetricChartCard(controller: _controller),
        const SizedBox(height: 16),
        Text(
          l10n.profileMeasurementsHistory,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (measurements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.profileEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          for (final measurement in measurements) ...[
            _HistoryTile(
              measurement: measurement,
              onDelete: () => _confirmDelete(context, measurement),
            ),
            const SizedBox(height: 8),
          ],
          if (_controller.hasMore.value)
            Center(
              child: TextButton.icon(
                onPressed: _controller.loadMore,
                icon: const Icon(Icons.expand_more),
                label: Text(l10n.profileLoadMore),
              ),
            ),
        ],
        const SizedBox(height: 8),
        _LinksCard(),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BodyMeasurement measurement,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileDeleteMeasurementConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _controller.deleteMeasurement(measurement.id!);
    }
  }
}

/// Карточка выбора пола — используется для пол-специфичных шкал (ИМТ).
class _GenderCard extends StatelessWidget {
  const _GenderCard({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileGender,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<Gender>(
            segments: [
              ButtonSegment(
                value: Gender.male,
                label: Text(l10n.profileGenderMale),
              ),
              ButtonSegment(
                value: Gender.female,
                label: Text(l10n.profileGenderFemale),
              ),
            ],
            selected: {?controller.gender.value},
            emptySelectionAllowed: true,
            onSelectionChanged: (selection) {
              controller.setGender(selection.firstOrNull);
            },
          ),
        ],
      ),
    );
  }
}

/// Карточка ИМТ: значение, категория и цветная шкала с маркером.
class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final value = controller.bmi!;
    final category = controller.bmiCategory!;
    final gender = controller.gender.value!;
    final color = _bmiCategoryColor(theme, category);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.profileBmi, style: theme.textTheme.titleSmall),
              ),
              AppBadge(
                label: _bmiCategoryLabel(l10n, category),
                background: color.withValues(alpha: 0.15),
                foreground: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(value),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.profileBmiNormalRange(
              _fmt(normalBmiLowerBound(gender)),
              _fmt(normalBmiUpperBound(gender)),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: l10n.profileBmiScale(
              _fmt(value),
              _bmiCategoryLabel(l10n, category),
            ),
            child: _BmiScale(value: value, gender: gender, accent: color),
          ),
        ],
      ),
    );
  }
}

/// Горизонтальная шкала ИМТ с цветными зонами и маркером значения.
class _BmiScale extends StatelessWidget {
  const _BmiScale({
    required this.value,
    required this.gender,
    required this.accent,
  });

  static const double _min = 15;
  static const double _max = 40;

  final double value;
  final Gender gender;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fraction = ((value - _min) / (_max - _min)).clamp(0.0, 1.0);
    final normalStart = (normalBmiLowerBound(gender) - _min) / (_max - _min);
    final normalEnd = (normalBmiUpperBound(gender) - _min) / (_max - _min);
    final obeseStart = (obeseBmiBound - _min) / (_max - _min);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 34,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (normalStart * 1000).round(),
                          child: ColoredBox(
                            color: _categoryColor(
                              theme,
                              BmiCategory.underweight,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((normalEnd - normalStart) * 1000).round(),
                          child: ColoredBox(
                            color: _categoryColor(theme, BmiCategory.normal),
                          ),
                        ),
                        Expanded(
                          flex: ((obeseStart - normalEnd) * 1000).round(),
                          child: ColoredBox(
                            color: _categoryColor(
                              theme,
                              BmiCategory.overweight,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((1 - obeseStart) * 1000).round(),
                          child: ColoredBox(
                            color: _categoryColor(theme, BmiCategory.obese),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (width * fraction - 5).clamp(0.0, width - 10),
                top: 0,
                child: Container(
                  width: 10,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  l10n.profileBmiScaleLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _bmiCategoryLabel(AppLocalizations l10n, BmiCategory category) =>
    switch (category) {
      BmiCategory.underweight => l10n.profileBmiUnderweight,
      BmiCategory.normal => l10n.profileBmiNormal,
      BmiCategory.overweight => l10n.profileBmiOverweight,
      BmiCategory.obese => l10n.profileBmiObese,
    };

Color _bmiCategoryColor(ThemeData theme, BmiCategory category) =>
    _categoryColor(theme, category);

Color _categoryColor(ThemeData theme, BmiCategory category) =>
    switch (category) {
      BmiCategory.underweight => theme.colorScheme.tertiary,
      BmiCategory.normal => theme.colorScheme.primary,
      BmiCategory.overweight => theme.colorScheme.secondary,
      BmiCategory.obese => theme.colorScheme.error,
    };

/// Карточка «Текущие значения» из самого свежего замера.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.latest});

  final BodyMeasurement latest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileCurrentValues, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metric in BodyMetric.values)
                  _MetricChip(metric: metric, value: metric.readValue(latest)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.metric, required this.value});

  final BodyMetric metric;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unit = metric == BodyMetric.weight
        ? l10n.workoutUnitKg
        : l10n.profileUnitCm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.labelRu, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value == null ? '—' : '${_fmt(value!)} $unit',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Карточка с LineChart выбранной метрики.
class _MetricChartCard extends StatelessWidget {
  const _MetricChartCard({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: SignalBuilder(
        builder: (context) {
          final selectedMetric = controller.selectedMetric.value;
          final points = controller.chartPoints.value;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileMetricChart,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButton<BodyMetric>(
                  value: selectedMetric,
                  isExpanded: true,
                  items: [
                    for (final metric in BodyMetric.values)
                      DropdownMenuItem(
                        value: metric,
                        child: Text(metric.labelRu),
                      ),
                  ],
                  onChanged: (metric) {
                    if (metric != null) {
                      controller.selectMetric(metric);
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (points.isEmpty)
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        l10n.profileChartEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 160,
                    child: _MetricLineChart(points: points),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricLineChart extends StatelessWidget {
  const _MetricLineChart({required this.points});

  final List<MetricPoint> points;

  static String _dateLabel(
    DateTime date,
    DateTime today,
    AppLocalizations l10n,
  ) {
    if (date == today) {
      return l10n.commonToday;
    }
    return DateFormat('d.M', 'ru').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final labels = [
      for (final point in points) _dateLabel(point.date, today, l10n),
    ];
    return LineChart(
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
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final label = _fmt(value);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: theme.textTheme.labelSmall),
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[index],
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].value),
            ],
            isCurved: false,
            barWidth: 2,
            color: theme.colorScheme.primary,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Строка истории замеров с удалением.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.measurement, required this.onDelete});

  final BodyMeasurement measurement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat('d MMMM yyyy', 'ru').format(measurement.date);
    final values = BodyMetric.values
        .map((m) => m.readValue(measurement))
        .whereType<double>()
        .toList();
    final summary = measurement.weightKg != null
        ? '${_fmt(measurement.weightKg!)} ${l10n.workoutUnitKg}'
        : '${values.length} ${l10n.profileUnitCm}';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(date, style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text(
            summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.commonDelete,
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}

/// Ссылка на экран противопоказаний.
class _LinksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.health_and_safety_outlined),
        title: Text(l10n.contraindications),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/contraindications'),
      ),
    );
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
