import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/core/domain/validators/validation_result.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';

/// Валидация замеров тела: значения неотрицательны и в разумных диапазонах.
class BodyMeasurementValidator {
  const BodyMeasurementValidator();

  ValidationResult validate(BodyMeasurement measurement) {
    final errors = <String>[];
    if (!BodyMetric.values.any((m) => m.readValue(measurement) != null)) {
      errors.add('Укажите хотя бы одно значение');
    }
    for (final metric in BodyMetric.values) {
      final value = metric.readValue(measurement);
      if (value == null) {
        continue;
      }
      if (value < metric.minValue || value > metric.maxValue) {
        errors.add(
          '${metric.labelRu}: допустимо ${_format(metric.minValue)}–'
          '${_format(metric.maxValue)}',
        );
      }
    }
    return ValidationResult(errors);
  }

  static String _format(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
