import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';

/// Замер тела на дату. Все величины в см/кг, кроме даты — необязательны.
@DataClassName('BodyMeasurementRow')
class BodyMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer().map(const DateTimeConverter())();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get hipsCm => real().nullable()();
  RealColumn get bicepsCm => real().nullable()();
  RealColumn get forearmCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
  RealColumn get calfCm => real().nullable()();
}
