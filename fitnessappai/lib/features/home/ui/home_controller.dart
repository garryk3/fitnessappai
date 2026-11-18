import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/plan_day_status.dart';
import 'package:fitnessappai/core/domain/upcoming_day.dart';
import 'package:fitnessappai/features/workout/domain/plan_schedule_item.dart';
import 'package:fitnessappai/core/domain/workout_streak.dart' as streak;
import 'package:fitnessappai/core/domain/weekly_progress.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

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
        final resolved = resolveUpcomingDay(
          days: [
            for (final detailDay in detail.days)
              (id: detailDay.day.id, dayOfWeek: detailDay.day.dayOfWeek),
          ],
          today: today,
          scheduled: [
            for (final item in scheduledRange)
              (dayId: item.programDayId, date: item.scheduledDate),
          ],
        );
        ProgramDay? upcomingDay;
        for (final detailDay in detail.days) {
          if (detailDay.day.id == resolved.dayId) {
            upcomingDay = detailDay.day;
            break;
          }
        }
        final upcomingDate = resolved.date;
        final exerciseNames = await _exerciseNamesOf(detail, upcomingDay);
        final progress = await _weeklyProgress(
          detail.days,
          weekStart,
          program.id!,
        );

        // Статус тренировки на сегодня — по тем же правилам, что план (65.2):
        // «Перенесено» не выставляется, позднее выполнение в окне +3 дня
        // засчитывается как «Выполнено» на запланированной дате.
        WeekPlanStatus? todayStatus;
        if (upcomingDay != null &&
            upcomingDay.id != null &&
            upcomingDate != null &&
            _dateOnly(upcomingDate) == today) {
          final sessions = await workoutRepository.getSessions(
            upcomingDay.id!,
            weekStart,
          );
          todayStatus = planDayStatus(
            scheduledDate: upcomingDate,
            performedDates: [for (final s in sessions) s.performedDate],
            now: today,
          );
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
