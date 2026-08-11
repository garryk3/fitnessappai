import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/domain/metric_point.dart';

void main() {
  late AppDatabase db;
  late BodyMeasurementRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = BodyMeasurementRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  BodyMeasurement measurement({
    int? id,
    DateTime? date,
    double? heightCm,
    double? weightKg,
    double? waistCm,
    double? hipsCm,
  }) => BodyMeasurement(
    id: id,
    date: date ?? DateTime(2026, 8, 1),
    heightCm: heightCm,
    weightKg: weightKg,
    waistCm: waistCm,
    hipsCm: hipsCm,
  );

  group('add', () {
    test('добавляет замер и возвращает его с id', () async {
      final created = await repo.add(measurement(weightKg: 80.5));

      expect(created.id, isNotNull);
      expect(created.weightKg, 80.5);
      expect(created.date, DateTime(2026, 8, 1));
    });

    test('отклоняет отрицательное значение', () async {
      expect(() => repo.add(measurement(weightKg: -5)), throwsArgumentError);
    });

    test('отклоняет значения вне диапазонов', () async {
      expect(() => repo.add(measurement(heightCm: 320)), throwsArgumentError);
      expect(() => repo.add(measurement(weightKg: 0.5)), throwsArgumentError);
      expect(() => repo.add(measurement(waistCm: 400)), throwsArgumentError);
    });

    test('отклоняет замер без единого значения', () async {
      expect(() => repo.add(measurement()), throwsArgumentError);
    });

    test('принимает граничные значения диапазонов', () async {
      final created = await repo.add(measurement(heightCm: 40, weightKg: 500));
      expect(created.heightCm, 40);
      expect(created.weightKg, 500);
    });

    test('не сохраняет невалидный замер', () async {
      try {
        await repo.add(measurement(weightKg: -1));
      } on ArgumentError {
        // ожидаемо
      }
      expect(await repo.getAll(), isEmpty);
    });
  });

  group('getAll и latest', () {
    test('getAll возвращает замеры по дате', () async {
      await repo.add(measurement(date: DateTime(2026, 8, 10), weightKg: 81));
      await repo.add(measurement(date: DateTime(2026, 8, 1), weightKg: 82));
      await repo.add(measurement(date: DateTime(2026, 8, 5), weightKg: 83));

      final all = await repo.getAll();
      expect(all.map((m) => m.weightKg), [82, 83, 81]);
    });

    test('latest возвращает самый свежий замер', () async {
      await repo.add(measurement(date: DateTime(2026, 8, 1), weightKg: 82));
      final newest = await repo.add(
        measurement(date: DateTime(2026, 8, 10), weightKg: 81),
      );

      expect((await repo.latest())!.id, newest.id);
    });

    test('latest возвращает null, если замеров нет', () async {
      expect(await repo.latest(), isNull);
    });
  });

  group('delete', () {
    test('удаляет замер по id', () async {
      final created = await repo.add(measurement(weightKg: 80));
      await repo.delete(created.id!);

      expect(await repo.getAll(), isEmpty);
      expect(await repo.latest(), isNull);
    });

    test('удаление несуществующего id безопасно', () async {
      await repo.delete(999);
      expect(await repo.getAll(), isEmpty);
    });
  });

  group('history', () {
    test('возвращает точки метрики за период по датам', () async {
      await repo.add(measurement(date: DateTime(2026, 7, 20), weightKg: 84));
      await repo.add(
        measurement(date: DateTime(2026, 8, 1), weightKg: 82, heightCm: 180),
      );
      await repo.add(measurement(date: DateTime(2026, 8, 5), weightKg: 81));
      await repo.add(measurement(date: DateTime(2026, 8, 20), weightKg: 80));

      final points = await repo.history(
        BodyMetric.weight,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 10),
      );

      expect(points, [
        MetricPoint(date: DateTime(2026, 8, 1), value: 82),
        MetricPoint(date: DateTime(2026, 8, 5), value: 81),
      ]);
    });

    test('включает только замеры, где метрика измерена', () async {
      await repo.add(measurement(date: DateTime(2026, 8, 1), weightKg: 82));
      await repo.add(measurement(date: DateTime(2026, 8, 2), heightCm: 180));

      final points = await repo.history(
        BodyMetric.weight,
        DateTime(2026, 7, 1),
        DateTime(2026, 9, 1),
      );

      expect(points.single.value, 82);
    });

    test('показывает отдельные метрики независимо', () async {
      await repo.add(
        measurement(date: DateTime(2026, 8, 1), weightKg: 82, heightCm: 180),
      );

      final weights = await repo.history(
        BodyMetric.weight,
        DateTime(2026, 7, 1),
        DateTime(2026, 9, 1),
      );
      final heights = await repo.history(
        BodyMetric.height,
        DateTime(2026, 7, 1),
        DateTime(2026, 9, 1),
      );

      expect(weights.single.value, 82);
      expect(heights.single.value, 180);
    });

    test('пустой результат вне периода', () async {
      await repo.add(measurement(date: DateTime(2026, 8, 1), weightKg: 82));

      final points = await repo.history(
        BodyMetric.weight,
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30),
      );

      expect(points, isEmpty);
    });
  });
}
