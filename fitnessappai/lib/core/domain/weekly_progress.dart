import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';

/// Процент выполнения программы за неделю: [performedDays] выполненных из
/// [assignedDays].
///
/// `assignedDays` — знаменатель правила из 48.2: число дней программы для
/// программы с непривязанными днями, число закреплённых дней для полностью
/// привязанной. `null` — знаменатель пуст.
///
/// Значение **не ограничено сверху**: для программы с непривязанными днями
/// выполнить можно больше, чем дней в программе — кольцо ограничивает только
/// саму дугу, подпись показывает реальное значение.
///
/// Перенесено из `home_controller.dart` (54.4): та же функция нужна
/// списку программ.
int? weeklyProgressPercent({
  required int performedDays,
  required int assignedDays,
}) {
  if (assignedDays <= 0) {
    return null;
  }
  return (performedDays / assignedDays * 100).round();
}

/// Недельный прогресс программы: выполненные дни ([performed]) и общий
/// знаменатель ([assigned]) — по правилам 48.2.
///
/// [sessions] — сессии **за текущую неделю** (вызывающая сторона ограничивает
/// окно, например `[пн, пн+7)`).
///
/// Два правила (48.2):
///
/// - **Программа с непривязанными днями** (`dayOfWeek == null`): сколько дней
///   «по расписанию» выполнено, посчитать нельзя — числитель = число сессий
///   этой программы за неделю (по `programId`: сессия переживает удаление дня и
///   не удваивается), знаменатель = число дней программы.
/// - **Полностью привязанная программа:** числитель = число дней, у которых
///   есть хотя бы одна сессия за неделю (по `programDayId`), знаменатель =
///   число дней программы.
///
/// `null` — дней у программы нет (оценивать нечего).
({int performed, int assigned})? weeklyProgramProgress({
  required List<ProgramDay> days,
  required List<WorkoutSession> sessions,
  required int programId,
}) {
  if (days.isEmpty) {
    return null;
  }
  final unlinked = days.any((day) => day.dayOfWeek == null);
  final performed = unlinked
      ? sessions.where((session) => session.programId == programId).length
      : days.where((day) {
          final id = day.id;
          return id != null && sessions.any((s) => s.programDayId == id);
        }).length;
  return (performed: performed, assigned: days.length);
}
