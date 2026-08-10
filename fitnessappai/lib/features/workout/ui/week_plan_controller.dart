import 'package:signals/signals.dart';

import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Статус запланированного тренировочного дня на неделе.
enum WeekPlanStatus { pending, performed, rescheduled, skipped }

/// Запланированная на дату тренировка: день программы с вычисленным статусом.
class WeekPlanItem {
  const WeekPlanItem({
    required this.programDayId,
    required this.dayIndex,
    required this.programName,
    required this.dayOfWeek,
    required this.scheduledDate,
    required this.status,
  });

  final int programDayId;
  final int dayIndex;
  final String programName;

  /// День недели по расписанию: 1 = Пн … 7 = Вс.
  final int dayOfWeek;

  /// Дата, на которую закреплён день в текущей неделе.
  final DateTime scheduledDate;
  final WeekPlanStatus status;
}

/// Управляет планом недели: сетка дней, статусы, пропуски, смена недели.
class WeekPlanController {
  WeekPlanController({
    required this.programRepository,
    required this.workoutRepository,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now {
    weekStart.value = _mondayOf(_dateOnly(_now()));
    selectedDate.value = _dateOnly(_now());
    _load();
  }

  final ProgramRepository programRepository;
  final WorkoutRepository workoutRepository;
  final DateTime Function() _now;

  final Signal<List<WeekPlanItem>> items = Signal(<WeekPlanItem>[]);
  final Signal<bool> isLoading = Signal(false);

  /// Понедельник отображаемой недели.
  final Signal<DateTime> weekStart = Signal(DateTime.now());

  /// Сегодняшняя дата.
  final Signal<DateTime> selectedDate = Signal(DateTime.now());

  Future<void> refresh() => _load();

  /// Смещает отображаемую неделю на [delta] недель.
  void shiftWeek(int delta) {
    weekStart.value = weekStart.value.add(Duration(days: 7 * delta));
    _load();
  }

  Future<void> markSkipped(WeekPlanItem item) async {
    await workoutRepository.markSkipped(item.programDayId, weekStart.value);
    await _load();
  }

  Future<void> clearSkip(WeekPlanItem item) async {
    await workoutRepository.clearSkip(item.programDayId, weekStart.value);
    await _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final week = weekStart.value;
      final summaries = await programRepository.getPrograms();
      final scheduled = <WeekPlanItem>[];
      for (final summary in summaries) {
        final detail = await programRepository.getProgram(summary.program.id!);
        if (detail == null) {
          continue;
        }
        for (final day in detail.days) {
          final dayOfWeek = day.day.dayOfWeek;
          if (dayOfWeek == null || day.day.id == null) {
            continue;
          }
          scheduled.add(
            WeekPlanItem(
              programDayId: day.day.id!,
              dayIndex: day.day.dayIndex,
              programName: detail.program.name,
              dayOfWeek: dayOfWeek,
              scheduledDate: week.add(Duration(days: dayOfWeek - 1)),
              status: WeekPlanStatus.pending,
            ),
          );
        }
      }

      final dayIds = scheduled.map((e) => e.programDayId).toSet();
      final sessionsByDay = <int, List<WorkoutSession>>{};
      for (final id in dayIds) {
        sessionsByDay[id] = await workoutRepository.getSessions(id, week);
      }
      final skippedDayIds = (await workoutRepository.getSkips(
        week,
      )).map((mark) => mark.programDayId).toSet();

      final result = <WeekPlanItem>[];
      for (final item in scheduled) {
        result.add(
          WeekPlanItem(
            programDayId: item.programDayId,
            dayIndex: item.dayIndex,
            programName: item.programName,
            dayOfWeek: item.dayOfWeek,
            scheduledDate: item.scheduledDate,
            status: _statusOf(
              item,
              sessionsByDay[item.programDayId] ?? const <WorkoutSession>[],
              skippedDayIds,
            ),
          ),
        );
      }
      result.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      items.value = result;
    } finally {
      isLoading.value = false;
    }
  }

  WeekPlanStatus _statusOf(
    WeekPlanItem item,
    List<WorkoutSession> sessions,
    Set<int> skippedDayIds,
  ) {
    if (sessions.isNotEmpty) {
      final latest = sessions.first;
      final sameDay = _sameDay(latest.performedDate, item.scheduledDate);
      return sameDay ? WeekPlanStatus.performed : WeekPlanStatus.rescheduled;
    }
    if (skippedDayIds.contains(item.programDayId)) {
      return WeekPlanStatus.skipped;
    }
    return WeekPlanStatus.pending;
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _mondayOf(DateTime value) =>
    _dateOnly(value).subtract(Duration(days: value.weekday - 1));

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
