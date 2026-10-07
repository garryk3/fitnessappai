import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';

/// Последняя тренировка на домашнем экране.
class HomeWorkoutItem {
  const HomeWorkoutItem({required this.session, required this.exercisesCount});

  final WorkoutSession session;

  /// Количество различных упражнений в сессии.
  final int exercisesCount;

  Duration get duration => session.endedAt.difference(session.startedAt);
}

/// Информация об одной активной программе для домашнего экрана.
class ActiveProgramInfo {
  const ActiveProgramInfo({
    required this.program,
    required this.upcomingDay,
    required this.exerciseNames,
    this.todayStatus,
    this.weeklyProgressPercent,
  });

  final Program program;
  final ProgramDay? upcomingDay;
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
      for (final program in allActive) {
        final detail = await programRepository.getProgram(program.id!);
        if (detail == null) {
          continue;
        }
        final upcomingDay = _findUpcomingDay(detail.days, todayWeekday);
        final exerciseNames = await _exerciseNamesOf(detail, upcomingDay);
        final progress = await _weeklyProgress(
          detail.days,
          weekStart,
          program.id!,
        );

        // Вычисляем статус тренировки на сегодня.
        WeekPlanStatus? todayStatus;
        if (upcomingDay != null &&
            upcomingDay.dayOfWeek == todayWeekday &&
            upcomingDay.id != null) {
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
            exerciseNames: exerciseNames,
            todayStatus: todayStatus,
            weeklyProgressPercent: progress,
          ),
        );
      }
      activePrograms.value = infos;

      final sessions = await workoutRepository.getAllSessions();
      final workouts = <HomeWorkoutItem>[];
      for (final session in sessions.take(3)) {
        final detail = await workoutRepository.getSession(session.id!);
        workouts.add(
          HomeWorkoutItem(
            session: session,
            exercisesCount: detail == null
                ? 0
                : detail.results.map((r) => r.exerciseName).toSet().length,
          ),
        );
      }
      recentWorkouts.value = workouts;
    } finally {
      isLoading.value = false;
    }
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

/// Процент выполнения программы за неделю: [performedDays] выполненных из
/// [assignedDays].
///
/// `assignedDays` — знаменатель правила из [_weeklyProgress]: число дней
/// программы для программы с непривязанными днями, число закреплённых дней
/// для полностью привязанной. `null` — знаменатель пуст.
///
/// Значение **не ограничено сверху**: для программы с непривязанными днями
/// выполнить можно больше, чем дней в программе (48.2).
int? weeklyProgressPercent({
  required int performedDays,
  required int assignedDays,
}) {
  if (assignedDays <= 0) {
    return null;
  }
  return (performedDays / assignedDays * 100).round();
}
