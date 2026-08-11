import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/body_measurement_validator.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.measurementFormTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('d MMMM yyyy', 'ru').format(_date)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            for (final metric in BodyMetric.values) ...[
              _MetricField(
                metric: metric,
                controller: _controllers[metric]!,
                suffix: metric == BodyMetric.weight
                    ? l10n.workoutUnitKg
                    : l10n.profileUnitCm,
                errorText: l10n.measurementFormNumberError,
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.commonSave),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errors.join('\n'))));
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

class _MetricField extends StatelessWidget {
  const _MetricField({
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
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: metric.labelRu,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }
        return double.tryParse(value.trim()) == null ? errorText : null;
      },
    );
  }
}
