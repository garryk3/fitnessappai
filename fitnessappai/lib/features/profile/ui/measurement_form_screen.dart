import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/body_measurement_validator.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/ui/body_metric_label.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Форма добавления замера: дата + числовые поля, всё кроме даты опционально.
class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({
    super.key,
    this.measurementRepository,
    this.validator = const BodyMeasurementValidator(),
  });

  final BodyMeasurementRepository? measurementRepository;
  final BodyMeasurementValidator validator;

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  late final BodyMeasurementRepository _repository;
  late final Map<BodyMetric, TextEditingController> _controllers;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _repository =
        widget.measurementRepository ??
        locator.get<BodyMeasurementRepository>();
    _controllers = {
      for (final metric in BodyMetric.values) metric: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppTopBar(title: l10n.measurementFormTitle),
      body: Form(
        key: _formKey,
        child: AppListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Дата (функциональность не менялась — вне образца, консервативно).
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const AppIcon(Icons.calendar_today_outlined),
                title: AppText(DateFormat('d MMMM yyyy', 'ru').format(_date)),
                trailing: const AppIcon(Icons.edit_outlined),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 16),
            // Основные параметры — широкие градиентные карточки (54.9,
            // образец «Новый замер»: вес — такая же карточка, рост —
            // в нашей форме он есть, по образцу же).
            for (final metric in const [
              BodyMetric.height,
              BodyMetric.weight,
            ]) ...[
              _MetricFieldCard(
                metric: metric,
                controller: _controllers[metric]!,
                suffix: metric == BodyMetric.weight
                    ? l10n.workoutUnitKg
                    : l10n.profileUnitCm,
                errorText: l10n.measurementFormNumberError,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            // Обхваты — сетка 2 колонки (54.9, образец).
            AppSectionHeader(title: l10n.measurementFormGirths),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final columnWidth = (constraints.maxWidth - spacing) / 2;
                final girths = [
                  for (final metric in BodyMetric.values)
                    if (!const {
                      BodyMetric.height,
                      BodyMetric.weight,
                    }.contains(metric))
                      metric,
                ];
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final metric in girths)
                      SizedBox(
                        width: columnWidth,
                        child: _MetricFieldCard(
                          metric: metric,
                          controller: _controllers[metric]!,
                          suffix: l10n.profileUnitCm,
                          errorText: l10n.measurementFormNumberError,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AppGradientButton(
              onPressed: _save,
              icon: Icons.check,
              label: l10n.commonSave,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final measurement = BodyMeasurement(
      date: _date,
      heightCm: _valueOf(BodyMetric.height),
      weightKg: _valueOf(BodyMetric.weight),
      neckCm: _valueOf(BodyMetric.neck),
      chestCm: _valueOf(BodyMetric.chest),
      waistCm: _valueOf(BodyMetric.waist),
      hipsCm: _valueOf(BodyMetric.hips),
      bicepsCm: _valueOf(BodyMetric.biceps),
      forearmCm: _valueOf(BodyMetric.forearm),
      thighCm: _valueOf(BodyMetric.thigh),
      calfCm: _valueOf(BodyMetric.calf),
    );
    final result = widget.validator.validate(measurement);
    if (!result.isValid) {
      showAppSnackBar(ScaffoldMessenger.of(context), result.errors.join('\n'));
      return;
    }
    await _repository.add(measurement);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  double? _valueOf(BodyMetric metric) {
    final text = _controllers[metric]!.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }
}

/// Карточка-поле метрики (54.9, образец «Новый замер»): градиентная
/// карточка с бейджем-иконкой, капс-заголовком и полем ввода.
/// Имена `labelText` не менять — контракт тестов/e2e
/// (`widgetWithText(TextFormField, 'Вес'/'Рост'/…)`).
class _MetricFieldCard extends StatelessWidget {
  const _MetricFieldCard({
    required this.metric,
    required this.controller,
    required this.suffix,
    required this.errorText,
  });

  final BodyMetric metric;
  final TextEditingController controller;
  final String suffix;
  final String errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Градиент карточки по образцу: тёмная тема — heroCard (тёмно-синий →
    // фиолет, стопы из образца), светлая — лёгкий ролевой (DESIGN.md §11).
    final gradient = theme.brightness == Brightness.dark
        ? AppGradients.heroCard
        : AppGradients.roleSurface(theme.colorScheme);
    return AppCard(
      padding: const EdgeInsets.all(12),
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppContainer(
                width: 28,
                height: 28,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Center(
                  child: AppIcon(
                    bodyMetricIcon(metric),
                    size: 16,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Expanded + ellipsis: на 320dp колонка сетки ~140px, а капс
              // «ПРЕДПЛЕЧЬЕ» шире — без этого детерминированное переполнение
              // Row (task-review 54.9, WILL BREAK).
              Expanded(
                child: AppText(
                  bodyMetricLabel(l10n, metric).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppTextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: bodyMetricLabel(l10n, metric),
              hintText: l10n.measurementFormValueHint,
              suffixText: suffix,
              // Лейбл всегда сверху, hint «0.0» виден без тапа — как в
              // образце «Новый замер» (дизайн-ревью 54.9); контракт
              // widgetWithText(TextFormField, …) не зависит от позиции.
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              return double.tryParse(value.trim()) == null ? errorText : null;
            },
          ),
        ],
      ),
    );
  }
}
