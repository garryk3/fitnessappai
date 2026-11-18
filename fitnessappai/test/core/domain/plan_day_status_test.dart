// ignore_for_file: type=lint
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/plan_day_status.dart';

void main() {
  // 2026-08-12 — среда.
  final wednesday = DateTime(2026, 8, 12);

  group('planDayStatus', () {
    test('нет сессий, вхождение сегодня → pending', () {
      expect(
        planDayStatus(
          scheduledDate: wednesday,
          performedDates: const [],
          now: wednesday,
        ),
        WeekPlanStatus.pending,
      );
    });

    test('нет сессий, вхождение в прошлом → pastSkipped', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 10),
          performedDates: const [],
          now: wednesday,
        ),
        WeekPlanStatus.pastSkipped,
      );
    });

    test('нет сессий, вхождение в будущем → pending', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 14),
          performedDates: const [],
          now: wednesday,
        ),
        WeekPlanStatus.pending,
      );
    });

    test('пропуск вручную сегодня → skipped', () {
      expect(
        planDayStatus(
          scheduledDate: wednesday,
          performedDates: const [],
          now: wednesday,
          isSkipped: true,
        ),
        WeekPlanStatus.skipped,
      );
    });

    test('пропуск вручную в прошлом → skipped', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 10),
          performedDates: const [],
          now: wednesday,
          isSkipped: true,
        ),
        WeekPlanStatus.skipped,
      );
    });

    test('сессия в день вхождения → performed', () {
      expect(
        planDayStatus(
          scheduledDate: wednesday,
          performedDates: [DateTime(2026, 8, 12, 18, 30)],
          now: wednesday,
        ),
        WeekPlanStatus.performed,
      );
    });

    test('позднее выполнение в окне +3 дня → performed (64.8)', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 10),
          performedDates: [DateTime(2026, 8, 13)],
          now: wednesday,
        ),
        WeekPlanStatus.performed,
      );
    });

    test('выполнение ровно на границе +3 дня → performed', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 10),
          performedDates: [DateTime(2026, 8, 13)],
          now: DateTime(2026, 8, 20),
        ),
        WeekPlanStatus.performed,
      );
    });

    test('выполнение за окном +3 дня не отмечает вхождение', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 10),
          performedDates: [DateTime(2026, 8, 14)],
          now: DateTime(2026, 8, 20),
        ),
        WeekPlanStatus.pastSkipped,
      );
    });

    test('сессия раньше вхождения не отмечает его (регресс 43.7)', () {
      // Тренировка была вчера, а вхождение — сегодня: сегодня ещё не
      // выполнено, иначе нельзя пропустить текущий день.
      expect(
        planDayStatus(
          scheduledDate: wednesday,
          performedDates: [DateTime(2026, 8, 11)],
          now: wednesday,
        ),
        WeekPlanStatus.pending,
      );
    });

    test('сессия раньше вхождения прошедшего дня → pastSkipped', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 12),
          performedDates: [DateTime(2026, 8, 11)],
          now: DateTime(2026, 8, 14),
        ),
        WeekPlanStatus.pastSkipped,
      );
    });

    test('несколько сессий — достаточно одной в окне', () {
      expect(
        planDayStatus(
          scheduledDate: DateTime(2026, 8, 10),
          performedDates: [DateTime(2026, 8, 9), DateTime(2026, 8, 12)],
          now: wednesday,
        ),
        WeekPlanStatus.performed,
      );
    });

    test('rescheduled правилом не выставляется', () {
      for (final dates in [
        <DateTime>[],
        [DateTime(2026, 8, 9)],
        [DateTime(2026, 8, 12)],
        [DateTime(2026, 8, 20)],
      ]) {
        for (final skipped in [false, true]) {
          expect(
            planDayStatus(
              scheduledDate: DateTime(2026, 8, 10),
              performedDates: dates,
              now: wednesday,
              isSkipped: skipped,
            ),
            isNot(WeekPlanStatus.rescheduled),
          );
        }
      }
    });
  });
}
