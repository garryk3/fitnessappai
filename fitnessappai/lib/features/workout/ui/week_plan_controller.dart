import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
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

  /// День недели по расписанию: 1 = Пн … 7 = Вс, null — не привязан.
  final int? dayOfWeek;

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
    DataChangeNotifier? changes,
  }) : _now = clock ?? DateTime.now {
    weekStart.value = _mondayOf(_dateOnly(_now()));
    selectedDate.value = _dateOnly(_now());
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final ProgramRepository programRepository;
  final WorkoutRepository workoutRepository;
  final DateTime Function() _now;
  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<List<WeekPlanItem>> items = Signal(<WeekPlanItem>[]);
  final Signal<bool> isLoading = Signal(false);

  /// Понедельник отображаемой недели.
  final Signal<DateTime> weekStart = Signal(DateTime.now());

  /// Сегодняшняя дата.
  final Signal<DateTime> selectedDate = Signal(DateTime.now());

  Future<void> refresh() => _load();

  /// Ближайшая запланированная (pending) тренировка или `null`, если такой нет.
  ///
  /// Сначала возвращает ближайшую по дате начиная с сегодняшнего дня, иначе —
  /// первую pending в отображаемой неделе.
  WeekPlanItem? get nextPending {
    final now = _dateOnly(_now());
    WeekPlanItem? earliest;
    for (final item in items.value) {
      if (item.status != WeekPlanStatus.pending) {
        continue;
      }
      if (!item.scheduledDate.isBefore(now)) {
        return item;
      }
      earliest ??= item;
    }
    return earliest;
  }

  /// Смещает отображаемую неделю на [delta] недель.
  void shiftWeek(int delta) {
    weekStart.value = weekStart.value.add(Duration(days: 7 * delta));
    _load();
  }

  /// Проверяет, существует ли тренировочный день в базе.
  Future<bool> dayExists(int programDayId) async =>
      await programRepository.getDay(programDayId) != null;

  Future<void> markSkipped(WeekPlanItem item) async {
    if (!await dayExists(item.programDayId)) {
      await _load();
      return;
    }
    await workoutRepository.markSkipped(item.programDayId, weekStart.value);
    await _load();
  }

  Future<void> clearSkip(WeekPlanItem item) async {
    if (!await dayExists(item.programDayId)) {
      await _load();
      return;
    }
    await workoutRepository.clearSkip(item.programDayId, weekStart.value);
    await _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final week = weekStart.value;
      final now = _dateOnly(_now());
      final summaries = await programRepository.getPrograms();
      final scheduled = <WeekPlanItem>[];
      final unlinked = <WeekPlanItem>[];
      for (final summary in summaries) {
        final detail = await programRepository.getProgram(summary.program.id!);
        if (detail == null) {
          continue;
        }
        for (final day in detail.days) {
          final dayOfWeek = day.day.dayOfWeek;
          if (day.day.id == null) {
            continue;
          }
          if (dayOfWeek == null) {
            // Непривязанные дни показываем как запланированные на сегодня.
            unlinked.add(
              WeekPlanItem(
                programDayId: day.day.id!,
                dayIndex: day.day.dayIndex,
                programName: detail.program.name,
                dayOfWeek: null,
                scheduledDate: now,
                status: WeekPlanStatus.pending,
              ),
            );
          } else {
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
      }

      final allItems = [...scheduled, ...unlinked];
      final dayIds = allItems.map((e) => e.programDayId).toSet();
      final sessionsByDay = <int, List<WorkoutSession>>{};
      for (final id in dayIds) {
        sessionsByDay[id] = await workoutRepository.getSessions(id, week);
      }
      final skippedDayIds = (await workoutRepository.getSkips(
        week,
      )).map((mark) => mark.programDayId).toSet();

      final result = <WeekPlanItem>[];
      for (final item in allItems) {
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

  void dispose() {
    _reloadSubscription.dispose();
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
