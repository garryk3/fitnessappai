import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/ui/body_metric_label.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Открывает нижний дравер с деталями записи истории замеров (64.9).
///
/// Тап по строке истории замеров показывает все параметры записи
/// (заполненные метрики с единицами) в bottom sheet — по образцу
/// дравера дня истории (59.2), без отдельной страницы.
Future<void> showMeasurementSheet(
  BuildContext context,
  BodyMeasurement measurement,
) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      // Поджимание под контент с потолком 60% экрана (образец 59.2):
      // короткий список метрик не оставляет пустое дно, полный —
      // ограничивается и прокручивается внутри.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок с датой — как в драверах «Плана»/«Истории»
            // (design-review 59.2).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: AppText(
                DateFormat('d MMMM yyyy', 'ru').format(measurement.date),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final metric in BodyMetric.values)
                      if (metric.readValue(measurement) case final value?)
                        _MetricRow(metric: metric, value: value),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Строка метрики в дравере замера: иконка, подпись, значение с единицей.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric, required this.value});

  final BodyMetric metric;
  final double value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unit = metric == BodyMetric.weight
        ? l10n.workoutUnitKg
        : l10n.profileUnitCm;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppIcon(
            bodyMetricIcon(metric),
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              bodyMetricLabel(l10n, metric),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          AppText(
            '${formatMetricValue(value)} $unit',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
