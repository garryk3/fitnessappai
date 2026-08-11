import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/domain/body_measurement_validator.dart';

void main() {
  const validator = BodyMeasurementValidator();

  BodyMeasurement measurement({
    double? heightCm,
    double? weightKg,
    double? neckCm,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bicepsCm,
    double? forearmCm,
    double? thighCm,
    double? calfCm,
  }) => BodyMeasurement(
    date: DateTime(2026, 8, 1),
    heightCm: heightCm,
    weightKg: weightKg,
    neckCm: neckCm,
    chestCm: chestCm,
    waistCm: waistCm,
    hipsCm: hipsCm,
    bicepsCm: bicepsCm,
    forearmCm: forearmCm,
    thighCm: thighCm,
    calfCm: calfCm,
  );

  test('валидный замер без ошибок', () {
    final result = validator.validate(measurement(heightCm: 180, weightKg: 82));

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('частичный замер без ошибок', () {
    expect(validator.validate(measurement(waistCm: 80)).isValid, isTrue);
  });

  test('замер без значений невалиден', () {
    final result = validator.validate(measurement());

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('хотя бы одно значение'));
  });

  test('отрицательные значения невалидны', () {
    expect(validator.validate(measurement(weightKg: -1)).isValid, isFalse);
    expect(validator.validate(measurement(heightCm: -10)).isValid, isFalse);
    expect(validator.validate(measurement(calfCm: -2)).isValid, isFalse);
  });

  test('значения вне диапазонов невалидны', () {
    expect(validator.validate(measurement(heightCm: 301)).isValid, isFalse);
    expect(validator.validate(measurement(heightCm: 39)).isValid, isFalse);
    expect(validator.validate(measurement(weightKg: 501)).isValid, isFalse);
    expect(validator.validate(measurement(chestCm: 4)).isValid, isFalse);
    expect(validator.validate(measurement(neckCm: 301)).isValid, isFalse);
  });

  test('граничные значения валидны', () {
    expect(validator.validate(measurement(heightCm: 40)).isValid, isTrue);
    expect(validator.validate(measurement(heightCm: 300)).isValid, isTrue);
    expect(validator.validate(measurement(weightKg: 1)).isValid, isTrue);
    expect(validator.validate(measurement(weightKg: 500)).isValid, isTrue);
    expect(validator.validate(measurement(waistCm: 5)).isValid, isTrue);
    expect(validator.validate(measurement(waistCm: 300)).isValid, isTrue);
  });

  test('ошибка содержит название метрики и диапазон', () {
    final result = validator.validate(measurement(weightKg: 999));

    expect(result.errors.single, contains('Вес'));
    expect(result.errors.single, contains('1'));
    expect(result.errors.single, contains('500'));
  });

  test('собирает ошибки по всем метрикам', () {
    final result = validator.validate(
      measurement(heightCm: 500, weightKg: -5, waistCm: 999),
    );

    expect(result.errors, hasLength(3));
  });
}
