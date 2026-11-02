// ignore_for_file: type=lint
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/body_measurement.dart';

BodyMeasurement _m(
  DateTime date, {
  double? heightCm,
  double? weightKg,
  double? chestCm,
  double? bicepsCm,
  double? waistCm,
}) => BodyMeasurement(
  date: date,
  heightCm: heightCm,
  weightKg: weightKg,
  chestCm: chestCm,
  bicepsCm: bicepsCm,
  waistCm: waistCm,
);

void main() {
  test('пустой список — null', () {
    expect(coalesceLatest(const []), isNull);
  });

  test('свежий замер с одном полем не стирает старые значения (58.3)', () {
    final summary = coalesceLatest([
      _m(DateTime(2026, 10, 1), weightKg: 82),
      _m(DateTime(2026, 9, 1), heightCm: 180, weightKg: 80, chestCm: 100),
    ]);

    expect(summary, isNotNull);
    expect(summary!.weightKg, 82); // заполненное поле перезаписано новым
    expect(summary.heightCm, 180); // незаполненное — сохранилось старое
    expect(summary.chestCm, 100);
    expect(summary.date, DateTime(2026, 10, 1));
  });

  test('самое свежее значение каждой метрики побеждает независимо', () {
    final summary = coalesceLatest([
      _m(DateTime(2026, 10, 3), bicepsCm: 36),
      _m(DateTime(2026, 10, 2), waistCm: 80, bicepsCm: 35),
      _m(DateTime(2026, 10, 1), waistCm: 82),
    ]);

    expect(summary!.bicepsCm, 36);
    expect(summary.waistCm, 80);
  });

  test('одна строка — сводка равна ей по значениям', () {
    final row = _m(DateTime(2026, 10, 1), weightKg: 80);
    final summary = coalesceLatest([row]);

    expect(summary!.weightKg, 80);
    expect(summary.heightCm, isNull);
  });
}
