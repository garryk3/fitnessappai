import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/workout_streak.dart';

void main() {
  group('streakDays (чистая функция)', () {
    // «Сегодня» — среда 14.10.2026 (детерминированно).
    final today = DateTime(2026, 10, 14);

    test('пустая история → 0', () {
      expect(streakDays(dates: const [], today: today), 0);
    });

    test('тренировка сегодня → 1', () {
      expect(
        streakDays(dates: [DateTime(2026, 10, 14, 21, 30)], today: today),
        1,
      );
    });

    test('вчерашняя без сегодняшней → серия жива (1)', () {
      expect(streakDays(dates: [DateTime(2026, 10, 13, 8)], today: today), 1);
    });

    test('три дня подряд, заканчиваясь сегодняшним → 3', () {
      expect(
        streakDays(
          dates: [
            DateTime(2026, 10, 14),
            DateTime(2026, 10, 14, 19),
            DateTime(2026, 10, 13),
            DateTime(2026, 10, 12, 7, 5),
          ],
          today: today,
        ),
        3,
      );
    });

    test('разрыв дней обрывает серию на пробеле', () {
      // 14, 13, 12 — подряд; 10 — за пробелом (нет 11), дальше не считаем.
      expect(
        streakDays(
          dates: [
            DateTime(2026, 10, 14),
            DateTime(2026, 10, 13),
            DateTime(2026, 10, 12),
            DateTime(2026, 10, 10),
            DateTime(2026, 10, 9),
          ],
          today: today,
        ),
        3,
      );
    });

    test('последняя тренировка старше вчера → 0 (прервана)', () {
      expect(
        streakDays(
          dates: [DateTime(2026, 10, 11), DateTime(2026, 10, 10)],
          today: today,
        ),
        0,
      );
    });

    test('несколько сессий в один день не удваивают серию', () {
      expect(
        streakDays(
          dates: [
            DateTime(2026, 10, 14, 7),
            DateTime(2026, 10, 14, 20),
            DateTime(2026, 10, 13, 12),
          ],
          today: today,
        ),
        2,
      );
    });

    test('время суток сессии не влияет на календарную дату', () {
      expect(
        streakDays(
          dates: [DateTime(2026, 10, 13, 23, 59), DateTime(2026, 10, 14, 0, 1)],
          today: today,
        ),
        2,
      );
    });

    test('тренировка позавчера при живой вчерашней не встречается — '
        'серия от вчерашней', () {
      expect(
        streakDays(
          dates: [DateTime(2026, 10, 13), DateTime(2026, 10, 11)],
          today: today,
        ),
        1,
      );
    });
  });
}
