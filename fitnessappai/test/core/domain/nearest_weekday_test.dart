import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/nearest_weekday.dart';

void main() {
  group('nearestWeekday', () {
    test('привязок нет (пусто или только null) → null', () {
      expect(nearestWeekday(weekdays: const [], todayWeekday: 3), isNull);
      expect(
        nearestWeekday(weekdays: const [null, null], todayWeekday: 3),
        isNull,
      );
    });

    test('сегодняшний день предпочтён будущему, если он сегодня', () {
      expect(nearestWeekday(weekdays: const [1, 4, 6], todayWeekday: 4), 4);
    });

    test('ближайший будущий день', () {
      expect(nearestWeekday(weekdays: const [1, 4, 6], todayWeekday: 3), 4);
    });

    test('все дни раньше сегодняшнего — wrap на следующую неделю', () {
      expect(nearestWeekday(weekdays: const [1, 3, 5], todayWeekday: 6), 1);
    });

    test('вход несортирован — порядок не влияет', () {
      expect(nearestWeekday(weekdays: const [7, 2, 5], todayWeekday: 3), 5);
    });

    test('null-дни пропускаются', () {
      expect(
        nearestWeekday(weekdays: const [null, 5, null], todayWeekday: 2),
        5,
      );
      expect(nearestWeekday(weekdays: const [null, 1], todayWeekday: 2), 1);
    });
  });
}
