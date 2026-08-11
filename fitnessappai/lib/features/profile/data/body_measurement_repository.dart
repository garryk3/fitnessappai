import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/domain/body_measurement_validator.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/domain/metric_point.dart';

/// Репозиторий замеров тела: CRUD, выборка по периодам и `latest`.
class BodyMeasurementRepository {
  BodyMeasurementRepository(this._db);

  final AppDatabase _db;
  final BodyMeasurementValidator _validator = const BodyMeasurementValidator();

  /// Добавляет замер после валидации значений и возвращает его с id.
  Future<BodyMeasurement> add(BodyMeasurement measurement) async {
    final result = _validator.validate(measurement);
    if (!result.isValid) {
      throw ArgumentError(result.errors.join('; '));
    }
    final id = await _db
        .into(_db.bodyMeasurements)
        .insert(_toCompanion(measurement));
    return (await _getById(id))!;
  }

  /// Возвращает все замеры, отсортированные по дате (затем по id).
  Future<List<BodyMeasurement>> getAll() async {
    final rows =
        await (_db.select(_db.bodyMeasurements)..orderBy([
              (t) => OrderingTerm.asc(t.date),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    return rows.map(_toModel).toList();
  }

  /// Самый свежий замер по дате или `null`, если замеров нет.
  Future<BodyMeasurement?> latest() async {
    final row =
        await (_db.select(_db.bodyMeasurements)
              ..orderBy([
                (t) => OrderingTerm.desc(t.date),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Удаляет замер по id (нет записи — ничего не делает).
  Future<void> delete(int id) async {
    await (_db.delete(
      _db.bodyMeasurements,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Точки метрики за период [start]..[end] (включительно) по датам.
  ///
  /// В выборку попадают только замеры, где [metric] измерена.
  Future<List<MetricPoint>> history(
    BodyMetric metric,
    DateTime start,
    DateTime end,
  ) async {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.bodyMeasurements)
              ..where((t) => t.date.isBetweenValues(startMs, endMs))
              ..orderBy([
                (t) => OrderingTerm.asc(t.date),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    final points = <MetricPoint>[];
    for (final row in rows) {
      final model = _toModel(row);
      final value = metric.readValue(model);
      if (value != null) {
        points.add(MetricPoint(date: model.date, value: value));
      }
    }
    return points;
  }

  Future<BodyMeasurement?> _getById(int id) async {
    final row = await (_db.select(
      _db.bodyMeasurements,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  BodyMeasurementsCompanion _toCompanion(BodyMeasurement m) =>
      BodyMeasurementsCompanion.insert(
        date: m.date,
        heightCm: Value(m.heightCm),
        weightKg: Value(m.weightKg),
        neckCm: Value(m.neckCm),
        chestCm: Value(m.chestCm),
        waistCm: Value(m.waistCm),
        hipsCm: Value(m.hipsCm),
        bicepsCm: Value(m.bicepsCm),
        forearmCm: Value(m.forearmCm),
        thighCm: Value(m.thighCm),
        calfCm: Value(m.calfCm),
      );

  BodyMeasurement _toModel(BodyMeasurementRow row) => BodyMeasurement(
    id: row.id,
    date: row.date,
    heightCm: row.heightCm,
    weightKg: row.weightKg,
    neckCm: row.neckCm,
    chestCm: row.chestCm,
    waistCm: row.waistCm,
    hipsCm: row.hipsCm,
    bicepsCm: row.bicepsCm,
    forearmCm: row.forearmCm,
    thighCm: row.thighCm,
    calfCm: row.calfCm,
  );
}
