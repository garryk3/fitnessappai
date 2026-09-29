import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Удаляет «протухшие» записи плана тренировок (задача 47.4).
///
/// По логике этапов 47.1–47.3 перенос возможен только внутри тренировочной
/// недели, поэтому ручные назначения (`plan_schedule`) и отметки недель
/// (`schedule_marks`) прошлых недель больше не влияют ни на что: их показ
/// запрещён, а хранить их незачем. История выполненных тренировок
/// (`workout_sessions`) не затрагивается — она живёт отдельно.
class PlanScheduleCleaner {
  const PlanScheduleCleaner({
    required this.workoutRepository,
    this.planScheduleRepository,
  });

  final WorkoutRepository workoutRepository;
  final PlanScheduleRepository? planScheduleRepository;

  /// Удаляет назначения и отметки недель раньше понедельника недели [now].
  ///
  /// Возвращает общее число удалённых строк (0 — чистить нечего).
  Future<int> cleanupOldSchedule(DateTime now) async {
    final monday = mondayOf(now);
    var removed = await workoutRepository.deleteMarksBefore(monday);
    final scheduleRepository = planScheduleRepository;
    if (scheduleRepository != null) {
      removed += await scheduleRepository.deleteBefore(monday);
    }
    return removed;
  }
}

/// Понедельник недели [value].
DateTime mondayOf(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}
