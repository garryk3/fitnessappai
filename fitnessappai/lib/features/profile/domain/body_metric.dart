import 'package:fitnessappai/core/domain/models/body_measurement.dart';

/// Метрика замера тела с диапазоном допустимых значений (см/кг).
enum BodyMetric {
  height('Рост', 40, 300),
  weight('Вес', 1, 500),
  neck('Шея', 5, 300),
  chest('Грудь', 5, 300),
  waist('Талия', 5, 300),
  hips('Бёдра', 5, 300),
  biceps('Бицепс', 5, 300),
  forearm('Предплечье', 5, 300),
  thigh('Бедро', 5, 300),
  calf('Икра', 5, 300);

  const BodyMetric(this.labelRu, this.minValue, this.maxValue);

  final String labelRu;
  final double minValue;
  final double maxValue;

  /// Значение метрики в замере или `null`, если не измерено.
  double? readValue(BodyMeasurement measurement) => switch (this) {
    BodyMetric.height => measurement.heightCm,
    BodyMetric.weight => measurement.weightKg,
    BodyMetric.neck => measurement.neckCm,
    BodyMetric.chest => measurement.chestCm,
    BodyMetric.waist => measurement.waistCm,
    BodyMetric.hips => measurement.hipsCm,
    BodyMetric.biceps => measurement.bicepsCm,
    BodyMetric.forearm => measurement.forearmCm,
    BodyMetric.thigh => measurement.thighCm,
    BodyMetric.calf => measurement.calfCm,
  };
}
