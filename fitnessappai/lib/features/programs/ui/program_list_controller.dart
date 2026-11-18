// ignore_for_file: prefer_initializing_formals
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/upcoming_day.dart';
import 'package:fitnessappai/core/domain/weekly_progress.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Элемент карточки программы: модель, дни и количество упражнений.
class ProgramListItem {
  const ProgramListItem({
    required this.program,
    required this.days,
    required this.exercisesCount,
    this.weekProgress,
    this.upcomingDate,
    this.upcomingDayId,
  });

  final Program program;

  /// Дни программы в порядке индексов.
  final List<ProgramDay> days;
  final int exercisesCount;

  /// Недельный прогресс (выполненные дни / всего) по правилам 48.2 —
  /// считается только при наличии репозитория сессий; `null` — данных нет.
  final ({int performed, int assigned})? weekProgress;

  /// Дата ближайшего дня программы (65.1): дата назначения из плана, если
  /// оно раньше ближайшего шаблонного дня, иначе дата шаблонного дня недели.
  /// `null` — у программы нет привязанных дней и назначений; подпись
  /// «Ближайший день» в этом случае не показывается.
  final DateTime? upcomingDate;

  /// Идентификатор ближайшего дня программы (65.1) — им же запускается
  /// тренировка по кнопке «Начать», чтобы действие совпадало с подписью
  /// и с hero-карточкой Главной (64.4). `null` — ближайшего дня нет.
  final int? upcomingDayId;

  /// Процент недельного выполнения; `null` — нет данных.
  int? get weekPercent => weekProgress == null
      ? null
      : weeklyProgressPercent(
          performedDays: weekProgress!.performed,
          assignedDays: weekProgress!.assigned,
        );
}

/// Управляет списком программ: загрузка, обновление, удаление.
class ProgramListController {
  ProgramListController(
    this._repository, {
    DataChangeNotifier? changes,
    ReminderService? reminderService,
    WorkoutRepository? workoutRepository,
    PlanScheduleRepository? planScheduleRepository,
    DateTime Function()? clock,
  }) : _reminderService = reminderService,
       _workoutRepository = workoutRepository,
       _planScheduleRepository = planScheduleRepository,
       _clock = clock ?? DateTime.now {
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final ProgramRepository _repository;
  final ReminderService? _reminderService;
  final WorkoutRepository? _workoutRepository;
  final PlanScheduleRepository? _planScheduleRepository;
  final DateTime Function() _clock;
  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<List<ProgramListItem>> items = Signal(<ProgramListItem>[]);
  final Signal<bool> isLoading = Signal(false);

  Future<void> refresh() => _load();

  Future<void> deleteProgram(int programId) async {
    if (_reminderService != null) {
      final days = await _repository.getDays(programId);
      // cancelDays снимает и еженедельные, и одноразовые напоминания ручных
      // назначений (48.10) — после каскадного удаления plan_schedule
      // отменить их будет уже нечем.
      await _reminderService.cancelDays([
        for (final day in days)
          if (day.id != null) day.id!,
      ]);
    }
    await _repository.delete(programId);
  }

  /// Делает программу активной и перепланирует напоминания её дней (47.8).
  Future<void> setActive(int programId) async {
    await _repository.setActive(programId);
    await _syncReminders(programId, activate: true);
  }

  /// Деактивирует программу и отменяет напоминания её дней (47.8).
  ///
  /// Настройки напоминаний в БД сохраняются, поэтому повторная активация
  /// снова их запланирует.
  Future<void> deactivate(int programId) async {
    await _repository.deactivate(programId);
    await _syncReminders(programId, activate: false);
  }

  Future<void> _syncReminders(int programId, {required bool activate}) async {
    final service = _reminderService;
    if (service == null) {
      return;
    }
    final days = await _repository.getDays(programId);
    final dayIds = [
      for (final day in days)
        if (day.id != null) day.id!,
    ];
    if (activate) {
      await service.rescheduleDays(dayIds);
    } else {
      await service.cancelDays(dayIds);
    }
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final summaries = await _repository.getPrograms();
      // Один снимок «сегодня» на загрузку: неделя, окно назначений и
      // резолвер обязаны считать от одной даты (иначе на границе суток
      // подпись разъедется на день).
      final today = _dateOnly(_clock());
      final sessions = await _loadWeekSessions(today);
      final scheduled = await _loadScheduled(today);
      final list = <ProgramListItem>[];
      for (final summary in summaries) {
        final days = await _repository.getDays(summary.program.id!);
        final upcoming = resolveUpcomingDay(
          days: [
            for (final day in days) (id: day.id, dayOfWeek: day.dayOfWeek),
          ],
          today: today,
          scheduled: scheduled,
        );
        list.add(
          ProgramListItem(
            program: summary.program,
            days: days,
            exercisesCount: summary.exercisesCount,
            weekProgress: sessions == null
                ? null
                : weeklyProgramProgress(
                    days: days,
                    sessions: sessions,
                    programId: summary.program.id!,
                  ),
            upcomingDate: upcoming.date,
            upcomingDayId: upcoming.dayId,
          ),
        );
      }
      items.value = list;
    } finally {
      isLoading.value = false;
    }
  }

  /// Назначения плана на ближайшую неделю (65.1) — один запрос на загрузку,
  /// раскладка по программам внутри цикла. Репозитория нет — пустой список:
  /// карточка считает ближайший день только по шаблону.
  Future<List<UpcomingDaySchedule>> _loadScheduled(DateTime today) async {
    final repository = _planScheduleRepository;
    if (repository == null) {
      return const [];
    }
    final items = await repository.getForRange(
      today,
      today.add(const Duration(days: 6)),
    );
    return [
      for (final item in items)
        (dayId: item.programDayId, date: item.scheduledDate),
    ];
  }

  /// Сессии текущей недели `[пн, пн+7)`; `null` — репозитория нет, тогда
  /// недельный прогресс карточек не считается (без данных — без кольца).
  Future<List<WorkoutSession>?> _loadWeekSessions(DateTime today) async {
    final repository = _workoutRepository;
    if (repository == null) {
      return null;
    }
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    return repository.getSessionsBetween(
      weekStart,
      weekStart.add(const Duration(days: 7)),
    );
  }

  void dispose() {
    _reloadSubscription.dispose();
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
