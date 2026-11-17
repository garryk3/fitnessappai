import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/workout/domain/plan_schedule_item.dart';
import 'package:fitnessappai/core/domain/workout_streak.dart' as streak;
import 'package:fitnessappai/core/domain/weekly_progress.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';

/// Чистая функция недельного процента перенесена в домен (54.4) — re-export
/// для существующих потребителей `home_controller.dart`.
export 'package:fitnessappai/core/domain/weekly_progress.dart'
    show weeklyProgressPercent;

/// Последняя тренировка на домашнем экране.
class HomeWorkoutItem {
  const HomeWorkoutItem({
    required this.session,
    required this.exercisesCount,
    this.displayDuration,
  });

  final WorkoutSession session;

  /// Количество различных упражнений в сессии.
  final int exercisesCount;

  /// Длительность для карточки (58.2): тренированное время, не время ввода
  /// метрик. `null` — не вычислена (fallback — старое wall-clock).
  final Duration? displayDuration;

  Duration get duration =>
      displayDuration ?? session.endedAt.difference(session.startedAt);
}

/// Информация об одной активной программе для домашнего экрана.
class ActiveProgramInfo {
  const ActiveProgramInfo({
    required this.program,
    required this.upcomingDay,
    this.upcomingDate,
    required this.exerciseNames,
    this.todayStatus,
    this.weeklyProgressPercent,
  });

  final Program program;
  final ProgramDay? upcomingDay;

  /// Дата ближайшего дня (64.4): дата запланированного назначения, если оно
  /// раньше ближайшего шаблонного дня, иначе дата шаблонного дня недели.
  /// `null` — у дня нет ни даты (непривязанный день), ни назначения.
  final DateTime? upcomingDate;

  final List<String> exerciseNames;

  /// Статус тренировки на сегодня, если ближайший день совпадает с сегодняшним.
  final WeekPlanStatus? todayStatus;

  /// Процент выполнения программы на текущей неделе; для программы с
  /// непривязанными днями (48.2) — доля сессий недели от всех дней программы
  /// и поэтому может превышать 100; `null` — у программы нет дней.
  final int? weeklyProgressPercent;
}

/// Управляет домашним экраном: активные программы, ближайшие дни,
/// последние тренировки.
class HomeController {
  HomeController({
    required this.programRepository,
    required this.exerciseRepository,
    required this.workoutRepository,
    this.planScheduleRepository,
    DateTime Function()? clock,
    DataChangeNotifier? changes,
  }) : _now = clock ?? DateTime.now {
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final ProgramRepository programRepository;
  final ExerciseRepository exerciseRepository;
  final WorkoutRepository workoutRepository;

  /// Назначения из плана (64.4): запланированный на дату день программы
  /// приоритетнее шаблонного дня недели в карточке ближайшего дня.
  final PlanScheduleRepository? planScheduleRepository;
  final DateTime Function() _now;
  late final ChangeReloadSubscription _reloadSubscription;

  /// Сессии текущей недели, выгружаются лениво и живут в рамках одного
  /// [_load] (задача 48.2): в цикле по активным программам запрос к БД один,
  /// а не по одному на программу.
  List<WorkoutSession>? _weekSessions;

  final Signal<bool> isLoading = Signal(true);
  final Signal<bool> hasPrograms = Signal(false);

  /// Все активные программы с информацией о ближайшем дне.
  final Signal<List<ActiveProgramInfo>> activePrograms = Signal(const []);

  /// Последние тренировки, свежие сверху.
  final Signal<List<HomeWorkoutItem>> recentWorkouts = Signal(const []);

  /// Длина серии подряд идущих дней с тренировками (54.3); 0 — пустая
  /// история или прерванная серия (бейдж в UI не показывается).
  final Signal<int> streakDays = Signal(0);

  Future<void> refresh() => _load();

  Future<void> _load() async {
    isLoading.value = true;
    _weekSessions = null;
    try {
      final allActive = await programRepository.getActivePrograms();
      hasPrograms.value =
          allActive.isNotEmpty ||
          (await programRepository.getPrograms()).isNotEmpty;

      final infos = <ActiveProgramInfo>[];
      final today = _dateOnly(_now());
      final todayWeekday = today.weekday;
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      // 64.4: назначения из плана на ближайшую неделю — один запрос на
      // загрузку, раскладка по программам внутри цикла.
      final scheduledRange = planScheduleRepository == null
          ? const <PlanScheduleItem>[]
          : await planScheduleRepository!.getForRange(
              today,
              today.add(const Duration(days: 6)),
            );
      for (final program in allActive) {
        final detail = await programRepository.getProgram(program.id!);
        if (detail == null) {
          continue;
        }
        final resolved = _resolveUpcoming(
          detail.days,
          today,
          todayWeekday,
          scheduledRange,
        );
        final upcomingDay = resolved.day;
        final upcomingDate = resolved.date;
        final exerciseNames = await _exerciseNamesOf(detail, upcomingDay);
        final progress = await _weeklyProgress(
          detail.days,
          weekStart,
          program.id!,
        );

        // Вычисляем статус тренировки на сегодня.
        WeekPlanStatus? todayStatus;
        if (upcomingDay != null &&
            upcomingDay.id != null &&
            upcomingDate != null &&
            _dateOnly(upcomingDate) == today) {
          final sessions = await workoutRepository.getSessions(
            upcomingDay.id!,
            weekStart,
          );
          if (sessions.isNotEmpty) {
            final latest = sessions.first;
            final sameDay = _sameDay(latest.performedDate, today);
            todayStatus = sameDay
                ? WeekPlanStatus.performed
                : WeekPlanStatus.rescheduled;
          } else {
            todayStatus = WeekPlanStatus.pending;
          }
        }

        infos.add(
          ActiveProgramInfo(
            program: program,
            upcomingDay: upcomingDay,
            upcomingDate: upcomingDate,
            exerciseNames: exerciseNames,
            todayStatus: todayStatus,
            weeklyProgressPercent: progress,
          ),
        );
      }
      activePrograms.value = infos;

      final sessions = await workoutRepository.getAllSessions();
      streakDays.value = streak.streakDays(
        dates: sessions.map((s) => s.performedDate),
        today: today,
      );
      final workouts = <HomeWorkoutItem>[];
      for (final session in sessions.take(3)) {
        final detail = await workoutRepository.getSession(session.id!);
        workouts.add(
          HomeWorkoutItem(
            session: session,
            exercisesCount: detail == null
                ? 0
                : detail.results.map((r) => r.exerciseName).toSet().length,
            // 58.2: тренированное время (временные подходы, не wall-clock).
            displayDuration: detail == null
                ? null
                : workoutDisplayDuration(session, detail.results),
          ),
        );
      }
      recentWorkouts.value = workouts;
    } finally {
      isLoading.value = false;
    }
  }

  /// Ближайший день программы с учётом запланированных назначений (64.4).
  ///
  /// Шаблонный ближайший день ([_findUpcomingDay]) сравнивается по дате с
  /// назначениями из плана этой программы на диапазон от сегодня; раньше
  /// побеждает запланированный день — он и является ближайшим. Дата
  /// шаблонного дня — его день недели текущей недели (перенос на следующую
  /// неделю для дней «позади сегодня»).
  ({ProgramDay? day, DateTime? date}) _resolveUpcoming(
    List<ProgramDayDetail> days,
    DateTime today,
    int todayWeekday,
    List<PlanScheduleItem> scheduledRange,
  ) {
    final templateDay = _findUpcomingDay(days, todayWeekday);
    DateTime? templateDate;
    if (templateDay?.dayOfWeek != null) {
      // Дата шаблонного дня: всегда не раньше сегодня (при переносе на
      // следующую неделю — +7 дней).
      final offset = templateDay!.dayOfWeek! >= todayWeekday
          ? templateDay.dayOfWeek! - todayWeekday
          : templateDay.dayOfWeek! - todayWeekday + 7;
      templateDate = _dateOnly(today.add(Duration(days: offset)));
    }
    final dayIds = {for (final d in days) d.day.id};
    PlanScheduleItem? scheduled;
    for (final item in scheduledRange) {
      if (!dayIds.contains(item.programDayId)) {
        continue;
      }
      final date = _dateOnly(item.scheduledDate);
      if (scheduled == null ||
          date.isBefore(_dateOnly(scheduled.scheduledDate))) {
        scheduled = item;
      }
    }
    if (scheduled != null &&
        (templateDate == null ||
            _dateOnly(scheduled.scheduledDate).isBefore(templateDate))) {
      final day = days
          .firstWhere((d) => d.day.id == scheduled!.programDayId)
          .day;
      return (day: day, date: _dateOnly(scheduled.scheduledDate));
    }
    return (day: templateDay, date: templateDate);
  }

  /// Ближайший день программы по дню недели, начиная с [todayWeekday]
  /// (1 = Пн … 7 = Вс) и с переносом на начало недели.
  /// Если привязанных дней нет — возвращает первый непривязанный день.
  ProgramDay? _findUpcomingDay(List<ProgramDayDetail> days, int todayWeekday) {
    final bound = days.where((d) => d.day.dayOfWeek != null).toList()
      ..sort((a, b) => a.day.dayOfWeek!.compareTo(b.day.dayOfWeek!));
    if (bound.isNotEmpty) {
      for (final detail in bound) {
        if (detail.day.dayOfWeek! >= todayWeekday) {
          return detail.day;
        }
      }
      return bound.first.day;
    }
    // Нет привязанных дней — ищем непривязанный.
    final unlinked = days.where((d) => d.day.dayOfWeek == null).toList();
    if (unlinked.isNotEmpty) {
      return unlinked.first.day;
    }
    return null;
  }

  /// Доля выполнения программы за текущую неделю [weekStart].
  ///
  /// Два правила (задача 48.2):
  ///
  /// - **Программа с непривязанными днями** (`dayOfWeek == null`, появились в
  ///   47.1): дни не привязаны к дням недели, поэтому «сколько из них
  ///   выполнено» по расписанию посчитать нельзя — знаменатель равен числу
  ///   дней программы, а числитель — число выполненных за неделю **сессий**
  ///   этой программы. Числитель считается по `programId`, а не по
  ///   `programDayId`: сессия пережит удаление дня, и по `programId` одна и
  ///   та же тренировка не удваивается. Значение может превысить 100 %
  ///   (сделал больше, чем дней в программе) — это осмысленно, кольцо
  ///   ограничивает только саму дугу.
  /// - **Полностью привязанная программа:** прежнее правило — доля
  ///   выполненных закреплённых дней из числа закреплённых.
  Future<int?> _weeklyProgress(
    List<ProgramDayDetail> days,
    DateTime weekStart,
    int programId,
  ) async {
    if (days.isEmpty) {
      return null;
    }
    if (days.any((d) => d.day.dayOfWeek == null)) {
      final sessions = _weekSessions ??= await workoutRepository
          .getSessionsBetween(
            weekStart,
            weekStart.add(const Duration(days: 7)),
          );
      final performed = sessions.where((s) => s.programId == programId).length;
      return weeklyProgressPercent(
        performedDays: performed,
        assignedDays: days.length,
      );
    }
    var performed = 0;
    for (final detail in days) {
      final id = detail.day.id;
      if (id == null) {
        // День без id не мог иметь сессий.
        continue;
      }
      final sessions = await workoutRepository.getSessions(id, weekStart);
      if (sessions.isNotEmpty) {
        performed++;
      }
    }
    return weeklyProgressPercent(
      performedDays: performed,
      assignedDays: days.length,
    );
  }

  Future<List<String>> _exerciseNamesOf(
    ProgramDetail detail,
    ProgramDay? day,
  ) async {
    if (day == null) {
      return const [];
    }
    final items = detail.days
        .where((d) => d.day.id == day.id)
        .expand((d) => d.mainExercises)
        .toList();
    final names = <String>[];
    for (final item in items) {
      if (item.exerciseId == null) {
        continue;
      }
      final exercise = await exerciseRepository.getById(item.exerciseId!);
      if (exercise != null) {
        names.add(exercise.name);
      }
    }
    return names;
  }

  void dispose() {
    _reloadSubscription.dispose();
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
