/// День программы для резолвера «ближайшего дня»: минимум данных, который
/// нужен правилу — идентификатор и привязка к дню недели. Подходит и для
/// `ProgramDay` (список программ), и для `ProgramDayDetail` (главная).
typedef UpcomingDayCandidate = ({int? id, int? dayOfWeek});

/// Назначение дня программы из плана на конкретную дату — подмножество
/// `PlanScheduleItem`, достаточное для резолвера.
typedef UpcomingDaySchedule = ({int dayId, DateTime date});

/// Ближайший день программы с учётом назначений плана.
///
/// Правила (перенесены из `HomeController`, 64.4):
///
/// - **Шаблонный ближайший день** — первый привязанный день недели не раньше
///   [today] (wrap на следующую неделю), иначе первый привязанный; если
///   привязок нет — первый непривязанный день. У непривязанного дня даты нет.
/// - **Дата шаблонного дня** — соответствующая дата текущей недели (при wrap
///   — плюс 7 дней).
/// - **Назначение из плана** раньше шаблонной даты — побеждает оно: так
///   перенесённая/назначенная тренировка показывается на обоих экранах.
///   Назначения в прошлом игнорируются (функция не зависит от того, какое
///   окно дат передал вызывающий).
///
/// Возвращает `dayId` (может быть `null`, если дней нет) и дату выбранного
/// дня (`null` — у дня нет ни привязки, ни назначения).
({int? dayId, DateTime? date}) resolveUpcomingDay({
  required Iterable<UpcomingDayCandidate> days,
  required DateTime today,
  Iterable<UpcomingDaySchedule> scheduled = const [],
}) {
  final candidates = days.toList();
  final template = _findUpcomingDay(candidates, today.weekday);
  DateTime? templateDate;
  final templateWeekday = template?.dayOfWeek;
  if (templateWeekday != null) {
    // Дата шаблонного дня: всегда не раньше сегодня (при переносе на
    // следующую неделю — +7 дней).
    final offset = templateWeekday >= today.weekday
        ? templateWeekday - today.weekday
        : templateWeekday - today.weekday + 7;
    templateDate = _dateOnly(today.add(Duration(days: offset)));
  }

  final dayIds = <int>{
    for (final day in candidates)
      if (day.id != null) day.id!,
  };
  UpcomingDaySchedule? nearest;
  for (final item in scheduled) {
    if (!dayIds.contains(item.dayId)) {
      continue;
    }
    final date = _dateOnly(item.date);
    if (date.isBefore(_dateOnly(today))) {
      // Прошлое назначение ближайшим днём быть не может.
      continue;
    }
    if (nearest == null || date.isBefore(_dateOnly(nearest.date))) {
      nearest = (dayId: item.dayId, date: date);
    }
  }
  if (nearest != null &&
      (templateDate == null ||
          _dateOnly(nearest.date).isBefore(templateDate))) {
    return (dayId: nearest.dayId, date: _dateOnly(nearest.date));
  }
  return (dayId: template?.id, date: templateDate);
}

/// Ближайший шаблонный день программы по дню недели, начиная с
/// [todayWeekday] (1 = Пн … 7 = Вс), с wrap на начало недели.
///
/// Если привязанных дней нет — возвращает первый непривязанный день.
UpcomingDayCandidate? _findUpcomingDay(
  List<UpcomingDayCandidate> days,
  int todayWeekday,
) {
  final bound = days.where((d) => d.dayOfWeek != null).toList()
    ..sort((a, b) => a.dayOfWeek!.compareTo(b.dayOfWeek!));
  if (bound.isNotEmpty) {
    for (final day in bound) {
      if (day.dayOfWeek! >= todayWeekday) {
        return day;
      }
    }
    return bound.first;
  }
  final unlinked = days.where((d) => d.dayOfWeek == null).toList();
  if (unlinked.isNotEmpty) {
    return unlinked.first;
  }
  return null;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
