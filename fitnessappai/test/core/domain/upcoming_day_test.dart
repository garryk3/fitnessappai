// ignore_for_file: type=lint
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/upcoming_day.dart';

void main() {
  // 2026-08-12 — среда (3), 2026-08-17 — понедельник (1).
  final wednesday = DateTime(2026, 8, 12);

  group('resolveUpcomingDay', () {
    test('дней нет — пустой результат', () {
      final resolved = resolveUpcomingDay(days: const [], today: wednesday);

      expect(resolved.dayId, isNull);
      expect(resolved.date, isNull);
    });

    test('только непривязанные дни — первый день без даты', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 7, dayOfWeek: null), (id: 8, dayOfWeek: null)],
        today: wednesday,
      );

      expect(resolved.dayId, 7);
      expect(resolved.date, isNull);
    });

    test('день сегодняшнего дня недели — дата сегодня', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 3)],
        today: wednesday,
      );

      expect(resolved.dayId, 1);
      expect(resolved.date, DateTime(2026, 8, 12));
    });

    test('день позже сегодня — дата этой недели', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 5)],
        today: wednesday,
      );

      expect(resolved.date, DateTime(2026, 8, 14));
    });

    test('день позади — перенос на следующую неделю', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 1)],
        today: wednesday,
      );

      // Понедельник позади среды — следующий понедельник 17 августа.
      expect(resolved.dayId, 1);
      expect(resolved.date, DateTime(2026, 8, 17));
    });

    test('день позади пропускается, если есть день впереди', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 2, dayOfWeek: 4), (id: 1, dayOfWeek: 1)],
        today: wednesday,
      );

      // Сортировка по дню недели: понедельник (1) позади, четверг (4) —
      // ближайший впереди.
      expect(resolved.dayId, 2);
      expect(resolved.date, DateTime(2026, 8, 13));
    });

    test('назначение раньше шаблонного дня — побеждает назначение', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 1)],
        today: wednesday,
        scheduled: [(dayId: 1, date: DateTime(2026, 8, 13))],
      );

      // Шаблонный понедельник — 17 августа, назначение — четверг 13 августа.
      expect(resolved.dayId, 1);
      expect(resolved.date, DateTime(2026, 8, 13));
    });

    test('назначение позже шаблонного дня — остаётся шаблон', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 5)],
        today: wednesday,
        scheduled: [(dayId: 1, date: DateTime(2026, 8, 20))],
      );

      expect(resolved.date, DateTime(2026, 8, 14));
    });

    test('несколько назначений — ближайшее', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 5), (id: 2, dayOfWeek: null)],
        today: wednesday,
        scheduled: [
          (dayId: 1, date: DateTime(2026, 8, 15)),
          (dayId: 2, date: DateTime(2026, 8, 13)),
        ],
      );

      expect(resolved.dayId, 2);
      expect(resolved.date, DateTime(2026, 8, 13));
    });

    test('назначение для дня другой программы игнорируется', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 5)],
        today: wednesday,
        scheduled: [(dayId: 99, date: DateTime(2026, 8, 13))],
      );

      expect(resolved.dayId, 1);
      expect(resolved.date, DateTime(2026, 8, 14));
    });

    test('назначение в прошлом игнорируется', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 1, dayOfWeek: 5)],
        today: wednesday,
        scheduled: [(dayId: 1, date: DateTime(2026, 8, 10))],
      );

      // Понедельник 10 августа — в прошлом; остаётся шаблонная пятница.
      expect(resolved.dayId, 1);
      expect(resolved.date, DateTime(2026, 8, 14));
    });

    test('назначение непривязанного дня даёт дату', () {
      final resolved = resolveUpcomingDay(
        days: const [(id: 3, dayOfWeek: null)],
        today: wednesday,
        scheduled: [(dayId: 3, date: DateTime(2026, 8, 13))],
      );

      expect(resolved.dayId, 3);
      expect(resolved.date, DateTime(2026, 8, 13));
    });
  });
}
