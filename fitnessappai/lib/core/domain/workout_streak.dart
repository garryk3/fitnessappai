/// Длина серии (streak) тренировок — подряд идущих дней с сессиями.
///
/// Чистая функция от дат выполненных тренировок и «сегодня» (для
/// детерминированных тестов «сегодня» передаётся явно). Считается только
/// календарная дата, время суток сессии не учитывается.
///
/// Семантика (редизайн 54, задача 54.3):
///
/// - серия **активна**, если последняя тренировка была сегодня или вчера
///   (сегодняшняя ещё не обязательна — вчерашняя серия живёт до конца дня);
/// - длина серии — число подряд идущих дней, оканчивающихся последней
///   тренировкой; разрыв в истории обрывает серию на нём;
/// - прерванная серия (последняя тренировка старше вчера) и пустая история
///   возвращают 0.
int streakDays({required Iterable<DateTime> dates, required DateTime today}) {
  final days = <DateTime>{};
  for (final date in dates) {
    days.add(_dateOnly(date));
  }
  if (days.isEmpty) {
    return 0;
  }

  var cursor = _dateOnly(today);
  if (!days.contains(cursor)) {
    // Сегодня ещё не тренировался — серия живёт, пока есть вчерашняя.
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) {
      return 0;
    }
  }

  var count = 0;
  while (days.contains(cursor)) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
