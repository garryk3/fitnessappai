/// Ближайший привязанный день недели к [todayWeekday].
///
/// Из [weekdays] (значения 1..7, возможны `null` — дни без привязки)
/// возвращается первый день **не раньше** сегодняшнего, а если таких нет —
/// первый в году (wrap на следующую неделю). `null` — привязок нет.
///
/// Семантика зеркалит выбор «ближайшего дня» на домашнем экране (48.x), но
/// возвращает только номер дня недели — карточке списка программ нужна лишь
/// подпись.
int? nearestWeekday({
  required Iterable<int?> weekdays,
  required int todayWeekday,
}) {
  final bound = weekdays.whereType<int>().toList()..sort();
  if (bound.isEmpty) {
    return null;
  }
  for (final weekday in bound) {
    if (weekday >= todayWeekday) {
      return weekday;
    }
  }
  return bound.first;
}
