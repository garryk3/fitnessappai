import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

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
  });

  final Program program;
  final ProgramDay? upcomingDay;
  final List<String> exerciseNames;
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

  final Signal<bool> isLoading = Signal(true);
  final Signal<bool> hasPrograms = Signal(false);

  /// Все активные программы с информацией о ближайшем дне.
  final Signal<List<ActiveProgramInfo>> activePrograms = Signal(const []);

  /// Последние тренировки, свежие сверху.
  final Signal<List<HomeWorkoutItem>> recentWorkouts = Signal(const []);

  Future<void> refresh() => _load();

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final allActive = await programRepository.getActivePrograms();
      hasPrograms.value =
          allActive.isNotEmpty ||
          (await programRepository.getPrograms()).isNotEmpty;

      final infos = <ActiveProgramInfo>[];
      final today = _dateOnly(_now()).weekday;
      for (final program in allActive) {
        final detail = await programRepository.getProgram(program.id!);
        if (detail == null) {
          continue;
        }
        final upcomingDay = _findUpcomingDay(detail.days, today);
        final exerciseNames = await _exerciseNamesOf(detail, upcomingDay);
        infos.add(
          ActiveProgramInfo(
            program: program,
            upcomingDay: upcomingDay,
            exerciseNames: exerciseNames,
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
