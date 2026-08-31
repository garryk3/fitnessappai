import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Режим отображения плана тренировок: сетка недели или календарь месяца.
enum PlanViewMode { week, month }

/// Статус запланированного тренировочного дня на неделе.
///
/// [pastSkipped] — прошедшая невыполненная тренировка старше окна переноса:
/// отображается как «Пропущено», но только в отображении (в БД не пишется).
enum WeekPlanStatus { pending, performed, rescheduled, skipped, pastSkipped }

/// Максимум дней в прошлом, когда тренировку ещё можно перенести/выполнить.
const int rescheduleWindowDays = 3;

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

  /// Дата, на которую закреплён день.
  final DateTime scheduledDate;
  final WeekPlanStatus status;
}

/// Управляет планом тренировок: сетка недели/месяца, статусы, пропуски.
class WeekPlanController {
  WeekPlanController({
    required this.programRepository,
    required this.workoutRepository,
    DateTime Function()? clock,
    DataChangeNotifier? changes,
  }) : _now = clock ?? DateTime.now {
    final today = _dateOnly(_now());
    weekStart.value = _mondayOf(today);
    selectedDate.value = today;
    monthStart.value = DateTime(today.year, today.month, 1);
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

  /// Первый день отображаемого месяца.
  final Signal<DateTime> monthStart = Signal(DateTime.now());

  /// Сегодняшняя дата.
  final Signal<DateTime> selectedDate = Signal(DateTime.now());

  /// Режим отображения: неделя или месяц.
  final Signal<PlanViewMode> viewMode = Signal(PlanViewMode.week);

  Future<void> refresh() => _load();

  /// Ближайшая запланированная (pending) тренировка или `null`, если такой нет.
  ///
  /// Сначала возвращает ближайшую по дате начиная с сегодняшнего дня, иначе —
  /// первую pending в отображаемом периоде.
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

  /// Смещает отображаемый месяц на [delta] месяцев.
  void shiftMonth(int delta) {
    final month = monthStart.value;
    monthStart.value = DateTime(month.year, month.month + delta, 1);
    _load();
  }

  /// Переключает режим отображения [mode] и перезагружает план.
  Future<void> setViewMode(PlanViewMode mode) async {
    if (viewMode.value == mode) {
      return;
    }
    viewMode.value = mode;
    await _load();
  }

  /// Проверяет, существует ли тренировочный день в базе.
  Future<bool> dayExists(int programDayId) async =>
      await programRepository.getDay(programDayId) != null;

  Future<void> markSkipped(WeekPlanItem item) async {
    if (!await dayExists(item.programDayId)) {
      await _load();
      return;
    }
    await workoutRepository.markSkipped(
      item.programDayId,
      _mondayOf(item.scheduledDate),
    );
    await _load();
  }

  Future<void> clearSkip(WeekPlanItem item) async {
    if (!await dayExists(item.programDayId)) {
      await _load();
      return;
    }
    await workoutRepository.clearSkip(
      item.programDayId,
      _mondayOf(item.scheduledDate),
    );
    await _load();
  }

  Future<void> _load() async {
    final mode = viewMode.value;
    if (mode == PlanViewMode.month) {
      final month = monthStart.value;
      final rangeStart = DateTime(month.year, month.month, 1);
      final rangeEnd = DateTime(month.year, month.month + 1, 0);
      await _loadRange(rangeStart, rangeEnd);
      return;
    }
    final week = weekStart.value;
    await _loadRange(week, week.add(const Duration(days: 6)));
  }

  Future<void> _loadRange(DateTime rangeStart, DateTime rangeEnd) async {
    isLoading.value = true;
    try {
      final now = _dateOnly(_now());
      final summaries = await programRepository.getPrograms();
      final plannedItems = <WeekPlanItem>[];
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
            // Непривязанные дни показываем на «сегодня», если оно в диапазоне.
            if (_inRange(now, rangeStart, rangeEnd) &&
                _isProgramActiveOn(detail.program, now)) {
              plannedItems.add(
                WeekPlanItem(
                  programDayId: day.day.id!,
                  dayIndex: day.day.dayIndex,
                  programName: detail.program.name,
                  dayOfWeek: null,
                  scheduledDate: now,
                  status: WeekPlanStatus.pending,
                ),
              );
            }
          } else {
            for (
              var date = rangeStart;
              !date.isAfter(rangeEnd);
              date = date.add(const Duration(days: 1))
            ) {
              if (date.weekday != dayOfWeek ||
                  !_isProgramActiveOn(detail.program, date)) {
                continue;
              }
              plannedItems.add(
                WeekPlanItem(
                  programDayId: day.day.id!,
                  dayIndex: day.day.dayIndex,
                  programName: detail.program.name,
                  dayOfWeek: dayOfWeek,
                  scheduledDate: date,
                  status: WeekPlanStatus.pending,
                ),
              );
            }
          }
        }
      }

      final sessionEnd = rangeEnd.add(const Duration(days: 1));
      final allSessions = await workoutRepository.getSessionsBetween(
        rangeStart,
        sessionEnd,
      );
      final sessionsByDayId = <int, List<WorkoutSession>>{};
      for (final session in allSessions) {
        final id = session.programDayId;
        if (id == null) {
          continue;
        }
        sessionsByDayId.putIfAbsent(id, () => <WorkoutSession>[]).add(session);
      }

      final skippedKeys = await _skippedKeysForRange(rangeStart, rangeEnd);

      final result = <WeekPlanItem>[];
      for (final item in plannedItems) {
        final weekStart = _mondayOf(item.scheduledDate);
        final isSkipped = skippedKeys.contains(
          '${item.programDayId}|${weekStart.millisecondsSinceEpoch}',
        );
        result.add(
          WeekPlanItem(
            programDayId: item.programDayId,
            dayIndex: item.dayIndex,
            programName: item.programName,
            dayOfWeek: item.dayOfWeek,
            scheduledDate: item.scheduledDate,
            status: _statusOf(
              item,
              sessionsByDayId[item.programDayId] ?? const <WorkoutSession>[],
              isSkipped,
              now,
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

  /// Собирает ключи пропусков `programDayId|weekStartMs` за период.
  Future<Set<String>> _skippedKeysForRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final keys = <String>{};
    final weekStarts = <int>{};
    for (
      var date = rangeStart;
      !date.isAfter(rangeEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final ws = _mondayOf(date);
      if (weekStarts.add(ws.millisecondsSinceEpoch)) {
        for (final mark in await workoutRepository.getSkips(ws)) {
          keys.add(
            '${mark.programDayId}|${mark.weekStart.millisecondsSinceEpoch}',
          );
        }
      }
    }
    return keys;
  }

  void dispose() {
    _reloadSubscription.dispose();
  }

  /// Проверяет, активна ли программа на [date] (период активности).
  ///
  /// Если программа никогда явно не активировалась (`activatedAt == null`),
  /// считаем её активной с самого начала. Период закрывается `deactivatedAt`.
  bool _isProgramActiveOn(Program program, DateTime date) {
    final activation = program.activatedAt;
    if (activation != null && date.isBefore(_dateOnly(activation))) {
      return false;
    }
    final deactivation = program.deactivatedAt;
    if (deactivation != null && !date.isBefore(_dateOnly(deactivation))) {
      return false;
    }
    return true;
  }

  WeekPlanStatus _statusOf(
    WeekPlanItem item,
    List<WorkoutSession> sessions,
    bool isSkipped,
    DateTime now,
  ) {
    if (sessions.isNotEmpty) {
      final latest = sessions.first;
      final sameDay = _sameDay(latest.performedDate, item.scheduledDate);
      return sameDay ? WeekPlanStatus.performed : WeekPlanStatus.rescheduled;
    }
    if (isSkipped) {
      return WeekPlanStatus.skipped;
    }
    if (now.difference(item.scheduledDate).inDays > rescheduleWindowDays) {
      return WeekPlanStatus.pastSkipped;
    }
    return WeekPlanStatus.pending;
  }
}

bool _inRange(DateTime date, DateTime rangeStart, DateTime rangeEnd) =>
    !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _mondayOf(DateTime value) =>
    _dateOnly(value).subtract(Duration(days: value.weekday - 1));

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
