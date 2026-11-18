/// Статус запланированного тренировочного дня на конкретную дату.
///
/// [pastSkipped] — невыполненная тренировка прошедшего дня (59.5.г: день
/// прошёл без факта — «пропущено», включая вчера в текущей неделе);
/// отображается как «Пропущено», но только в отображении (в БД не пишется).
/// Такой день действий не имеет: планировать/запускать на прошлое нельзя.
///
/// [rescheduled] сохранён для исторических отметок и бейджа статуса; правилом
/// 64.8 (окно +3 дня) больше не выставляется — позднее выполнение
/// засчитывается как [performed] на запланированной дате.
enum WeekPlanStatus { pending, performed, rescheduled, skipped, pastSkipped }

/// Статус вхождения плана по правилам 59.5.г и 64.8 (единый источник для
/// плана и Главной).
///
/// Правила:
/// - сессия, выполненная в день вхождения или **позже** него в пределах
///   трёх дней, засчитывает вхождение — [WeekPlanStatus.performed] на
///   запланированной дате (64.8: позднее выполнение относится к исходному
///   дню);
/// - сессия **раньше** вхождения его не отмечает (регресс 43.7: иначе
///   сегодняшнее вхождение нельзя пропустить при вчерашней тренировке);
/// - сессия за окном +3 дня — чужое вхождение;
/// - будущее и сегодняшнее вхождение без факта — [WeekPlanStatus.pending]
///   (или [WeekPlanStatus.skipped], если день пропущен вручную);
/// - прошедший день без факта — [WeekPlanStatus.pastSkipped].
WeekPlanStatus planDayStatus({
  required DateTime scheduledDate,
  required Iterable<DateTime> performedDates,
  required DateTime now,
  bool isSkipped = false,
}) {
  final scheduled = _dateOnly(scheduledDate);
  // Нормализуем «сейчас» внутри функции: сравнение «вхождение ещё не
  // прошло» не должно зависеть от того, передал вызывающий дату или
  // дату со временем.
  final today = _dateOnly(now);
  final performed = performedDates.toList();
  if (performed.isNotEmpty) {
    const window = Duration(days: 3);
    final lateInWindow = performed.any((date) {
      final delta = _dateOnly(date).difference(scheduled);
      return delta >= Duration.zero && delta <= window;
    });
    if (lateInWindow) {
      return WeekPlanStatus.performed;
    }
    // Сессия чужой недели/вне окна: будущее и сегодняшнее вхождение ещё не
    // «прошло» (59.5.г) — остаётся в плане без отметки; прошедшее —
    // «Пропущено» по факту дня.
    if (!scheduled.isBefore(today)) {
      return isSkipped ? WeekPlanStatus.skipped : WeekPlanStatus.pending;
    }
    return WeekPlanStatus.pastSkipped;
  }
  if (isSkipped) {
    return WeekPlanStatus.skipped;
  }
  if (scheduled.isBefore(today)) {
    return WeekPlanStatus.pastSkipped;
  }
  return WeekPlanStatus.pending;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
