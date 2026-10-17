import 'dart:developer';

import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_cleanup.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/domain/plan_schedule_item.dart';

/// Режим отображения плана тренировок: сетка недели или календарь месяца (54.5).
enum WeekPlanView { week, month }

/// Статус запланированного тренировочного дня на неделе.
///
/// [pastSkipped] — невыполненная тренировка из истёкшей тренировочной недели:
/// отображается как «Пропущено», но только в отображении (в БД не пишется).
/// Перенос тренировки допускается только внутри её тренировочной недели
/// (задача 47.2), поэтому такой день действий не имеет.
enum WeekPlanStatus { pending, performed, rescheduled, skipped, pastSkipped }

/// Действия, доступные для тренировки в дне плана (задача 47.1).
enum DayAction { start, reschedule, skip, unskip, remove }

/// Запланированная на дату тренировка: день программы с вычисленным статусом.
class WeekPlanItem {
  const WeekPlanItem({
    required this.programDayId,
    required this.dayIndex,
    required this.programName,
    required this.dayOfWeek,
    required this.scheduledDate,
    required this.status,
    this.imagePath,
    this.dayTitle,
    this.isManual = false,
    this.muscleKeys = const [],
    this.reminderHour,
    this.reminderMinute,
    this.reminderEnabled = false,
  });

  final int programDayId;
  final int dayIndex;
  final String programName;

  /// Кастомное название дня тренировки, null — «День N».
  final String? dayTitle;

  /// Путь к изображению программы (может отсутствовать).
  final String? imagePath;

  /// День недели по расписанию: 1 = Пн … 7 = Вс, null — не привязан.
  final int? dayOfWeek;

  /// Дата, на которую закреплён день.
  final DateTime scheduledDate;
  final WeekPlanStatus status;

  /// Назначение создано вручную (запись в `plan_schedule`) — «кастомная»
  /// тренировка. Дни программы (в т.ч. непривязанные, показываемые на
  /// «сегодня» автоматически) удалить из плана нельзя.
  final bool isManual;

  /// Ключи групп мышц дня (54.5): для календаря месяца. Уникальны в рамках
  /// списка; пусто — данных нет (repos не передан или у дня нет упражнений).
  final List<String> muscleKeys;

  /// Время тренировки (48.10); `null` — время не задано.
  ///
  /// Час и минута задаются только вместе. Берётся из строки `plan_schedule`
  /// для этой даты, поэтому есть и у дня по привязке: строка создаётся, как
  /// только пользователь задаёт время, но состояние карточки (`isManual`,
  /// крестик удаления) от неё не меняется.
  final int? reminderHour;
  final int? reminderMinute;

  /// Включено ли одноразовое напоминание (управляет только уведомлением).
  final bool reminderEnabled;

  /// Есть ли заданное время.
  bool get hasTime => reminderHour != null && reminderMinute != null;

  /// Время в формате `HH:mm`; `null`, если времени нет.
  String? get timeLabel {
    final hour = reminderHour;
    final minute = reminderMinute;
    if (hour == null || minute == null) {
      return null;
    }
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  /// Ключ строки `plan_schedule` для этой тренировки (`programDayId|дата`).
  String get scheduleKey =>
      '$programDayId|${_dateOnly(scheduledDate).millisecondsSinceEpoch}';
}

/// Набор действий дня для [item] на дату [today] (задача 47.1).
///
/// - «Кастомное» назначение ([WeekPlanItem.isManual]) умеет только одно —
///   удаление из расписания: переносить и пропускать его нечего;
/// - тренировку программы можно начать (сегодня) или перенести на сегодня;
/// - пропуск и отмена пропуска доступны только тренировкам текущего дня
///   (амендмент второй партии TASKS.md);
/// - выполненные, перенесённые и тренировки из истёкшей недели (перенос
///   возможен только внутри своей тренировочной недели, 47.2) действий не имеют.
Set<DayAction> dayActionsFor(WeekPlanItem item, DateTime today) {
  if (item.status == WeekPlanStatus.skipped) {
    return _sameDay(item.scheduledDate, today) ? {DayAction.unskip} : const {};
  }
  if (item.status != WeekPlanStatus.pending) {
    return const {};
  }
  if (item.isManual) {
    return {DayAction.remove};
  }
  if (_sameDay(item.scheduledDate, today)) {
    return {DayAction.start, DayAction.skip};
  }
  return {DayAction.reschedule};
}

/// Управляет планом тренировок: сетка недели, календарь месяца (54.5),
/// статусы, пропуски.
///
/// Вид «Месяц» вернулся в 54.5 как визуальный слой над теми же данными
/// планирования: навигация ограничена текущим и следующим периодом, назад —
/// только из следующего на текущий. Прошлое в плане не просматривается
/// (51.2): выполненные тренировки доступны на экране «История».
class WeekPlanController {
  WeekPlanController({
    required this.programRepository,
    required this.workoutRepository,
    this.exerciseRepository,
    this.planScheduleRepository,
    this.reminders,
    DateTime Function()? clock,
    DataChangeNotifier? changes,
  }) : _now = clock ?? DateTime.now {
    final today = _dateOnly(_now());
    weekStart.value = mondayOf(today);
    monthStart.value = DateTime(today.year, today.month, 1);
    selectedDate.value = today;
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final ProgramRepository programRepository;
  final WorkoutRepository workoutRepository;

  /// Каталог упражнений для иконок групп мышц в календаре месяца (54.5);
  /// `null` — без иконок (виджет-тесты, окружения без зарегистрированного
  /// сервиса).
  final ExerciseRepository? exerciseRepository;

  final PlanScheduleRepository? planScheduleRepository;

  /// Одноразовые напоминания ручных назначений (48.10); `null` — без
  /// уведомлений (виджет-тесты, окружения без зарегистрированного сервиса).
  final ReminderService? reminders;

  final DateTime Function() _now;
  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<List<WeekPlanItem>> items = Signal(<WeekPlanItem>[]);
  final Signal<bool> isLoading = Signal(false);

  /// Ошибка последней загрузки плана (53.3): без неё сбой чтения БД был
  /// неотличим от пустой недели — пользователь с существующими тренировками
  /// видел «Нет запланированных тренировок». Сбрасывается перед каждой
  /// загрузкой; при успешной — остаётся `false`, данные важнее ошибки.
  final Signal<bool> hasError = Signal(false);

  /// Понедельник отображаемой недели.
  final Signal<DateTime> weekStart = Signal(DateTime.now());

  /// Сегодняшняя дата.
  final Signal<DateTime> selectedDate = Signal(DateTime.now());

  /// Отображаемый вид плана (54.5): сетка недели или календарь месяца.
  final Signal<WeekPlanView> view = Signal(WeekPlanView.week);

  /// Первое число отображаемого месяца.
  final Signal<DateTime> monthStart = Signal(DateTime.now());

  /// Выбранный в календаре день месяца для карточки под сеткой (54.5).
  ///
  /// `null` — выбора не было; отображаемую дату считает [effectiveMonthDate].
  final Signal<DateTime?> monthSelectedDate = Signal(null);

  /// Переключает вид плана, загружая данные соответствующего периода.
  void setView(WeekPlanView next) {
    if (view.value == next) {
      return;
    }
    view.value = next;
    // Сброс старого периода: сетка нового рисуется сразу по новым данным,
    // без «pop-in» устаревших тренировок (design-review 54.5, находка 1).
    // `refresh()` item'ы не трогает — авто-перезагрузки без мигания.
    items.value = const [];
    _load();
  }

  /// Дата, выбранная в календаре месяца: всегда внутри отображаемого месяца.
  ///
  /// По умолчанию — «сегодня», когда оно в этом месяце; иначе — 1-е число
  /// месяца (карточка дня показывается всегда, 54.5).
  DateTime? get effectiveMonthDate {
    final stored = monthSelectedDate.value;
    final month = monthStart.value;
    if (stored != null &&
        stored.year == month.year &&
        stored.month == month.month) {
      return stored;
    }
    final today = _dateOnly(_now());
    return today.year == month.year && today.month == month.month
        ? today
        : DateTime(month.year, month.month, 1);
  }

  /// Выбирает день месяца в календаре (тап по ячейке).
  void selectMonthDate(DateTime date) =>
      monthSelectedDate.value = _dateOnly(date);

  /// Смещает отображаемый месяц на [delta] месяцев.
  void shiftMonth(int delta) {
    final current = monthStart.value;
    monthStart.value = DateTime(current.year, current.month + delta, 1);
    monthSelectedDate.value = null;
    // Сброс данных старого месяца — см. [setView] (design-review 54.5).
    items.value = const [];
    _load();
  }

  /// Можно ли перейти на следующий месяц: граница данных — текущая и следующая
  /// недели (47.10/51.2), поэтому дальше конца следующей недели не открываем.
  bool get canGoNextMonth {
    final maxDate = mondayOf(_dateOnly(_now())).add(const Duration(days: 13));
    final next = DateTime(monthStart.value.year, monthStart.value.month + 1, 1);
    return !next.isAfter(maxDate);
  }

  /// Можно ли перейти на предыдущий месяц: назад — только из следующего
  /// месяца на текущий (51.2), прошлое не просматривается.
  bool get canGoPrevMonth {
    final today = _dateOnly(_now());
    final currentMonth = DateTime(today.year, today.month, 1);
    return monthStart.value.isAfter(currentMonth);
  }

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

  /// Можно ли перейти на следующую неделю.
  ///
  /// План показывает только текущую и следующую недели (47.10).
  bool get canGoNextWeek => weekStart.value.isBefore(
    mondayOf(_dateOnly(_now())).add(const Duration(days: 7)),
  );

  /// Можно ли перейти на предыдущую неделю.
  ///
  /// Назад можно только из следующей недели на текущую: раньше текущей
  /// недели навигация запрещена (51.2). Прошлое в плане не просматривается —
  /// выполненные тренировки доступны на экране «История».
  bool get canGoPrevWeek =>
      weekStart.value.isAfter(mondayOf(_dateOnly(_now())));

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
      mondayOf(item.scheduledDate),
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
      mondayOf(item.scheduledDate),
    );
    await _load();
  }

  /// Назначает тренировочный день [programDayId] на [date] с временем (48.10).
  ///
  /// Время необязательно: без него назначение происходит ровно как раньше.
  Future<void> scheduleDay(
    int programDayId,
    DateTime date, {
    int? hour,
    int? minute,
    bool reminderEnabled = false,
  }) async {
    final item = await planScheduleRepository?.schedule(
      programDayId,
      date,
      hour: hour,
      minute: minute,
      reminderEnabled: reminderEnabled,
    );
    if (item != null) {
      await _syncManualReminder(item, programDayId, date);
    }
    await _load();
  }

  /// Задаёт или меняет время и напоминание тренировки (48.10).
  ///
  /// Строку в `plan_schedule` создаёт при необходимости — так время можно
  /// назначить дню по привязке к дню недели. Состояние карточки при этом не
  /// меняется: дублей в плане не появляется, крестик удаления не добавляется.
  ///
  /// [hour] равен `null` — время убирается вместе с напоминанием.
  Future<void> setReminder(
    int programDayId,
    DateTime date, {
    required int? hour,
    required int? minute,
    required bool reminderEnabled,
  }) async {
    final item = await planScheduleRepository?.setReminder(
      programDayId,
      date,
      hour: hour,
      minute: minute,
      reminderEnabled: reminderEnabled,
    );
    if (item != null) {
      await _syncManualReminder(item, programDayId, date);
    }
    await _load();
  }

  /// Отменяет ручное назначение тренировочного дня на дату.
  ///
  /// Одноразовое напоминание снимается вместе с назначением (48.10): иначе
  /// уведомление пришло бы об удалённой из плана тренировке.
  Future<void> cancelSchedule(int programDayId, DateTime date) async {
    final item = await planScheduleRepository?.getFor(programDayId, date);
    await planScheduleRepository?.cancel(programDayId, date);
    if (item != null) {
      await reminders?.cancelManualReminder(item.id);
    }
    await _load();
  }

  /// Ставит или снимает одноразовое уведомление по свежей строке назначения
  /// (48.10).
  ///
  /// Без включённого напоминания вызывается только отмена: снимать
  /// нечего, а лишний вызов дешевле идемпотентен.
  Future<void> _syncManualReminder(
    PlanScheduleItem item,
    int programDayId,
    DateTime date,
  ) async {
    final service = reminders;
    if (service == null) {
      return;
    }
    final hour = item.reminderHour;
    final minute = item.reminderMinute;
    if (!item.reminderEnabled || hour == null || minute == null) {
      await service.cancelManualReminder(item.id);
      return;
    }
    final day = await programRepository.getDay(programDayId);
    if (day == null) {
      return;
    }
    final detail = await programRepository.getProgram(day.programId);
    if (detail == null) {
      return;
    }
    await service.scheduleManualReminder(
      scheduleId: item.id,
      programDayId: programDayId,
      date: date,
      hour: hour,
      minute: minute,
      programName: detail.program.name,
      dayNumber: day.dayIndex + 1,
    );
  }

  Future<void> _load() {
    if (view.value == WeekPlanView.month) {
      final month = monthStart.value;
      return _loadRange(
        DateTime(month.year, month.month, 1),
        DateTime(month.year, month.month + 1, 0),
      );
    }
    final week = weekStart.value;
    return _loadRange(week, week.add(const Duration(days: 6)));
  }

  Future<void> _loadRange(DateTime rangeStart, DateTime rangeEnd) async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final now = _dateOnly(_now());
      final activePrograms = await programRepository.getActivePrograms();
      // Иконки групп мышц для календаря месяца (54.5): резолвим один раз
      // на загрузку, ключ — programDayId. Без репозитория — пусто.
      final groupsByExercise = exerciseRepository == null
          ? const <int, List<MuscleGroup>>{}
          : await exerciseRepository!.muscleGroupsByExercise();
      final muscleKeysByDayId = <int, List<String>>{};
      final plannedItems = <WeekPlanItem>[];
      for (final program in activePrograms) {
        final detail = await programRepository.getProgram(program.id!);
        if (detail == null) {
          continue;
        }
        for (final day in detail.days) {
          final dayOfWeek = day.day.dayOfWeek;
          if (day.day.id == null) {
            continue;
          }
          muscleKeysByDayId[day.day.id!] = _muscleKeysFor(
            day,
            groupsByExercise,
          );
          if (dayOfWeek == null) {
            // Непривязанные дни показываем на «сегодня», если оно в диапазоне.
            if (_inRange(now, rangeStart, rangeEnd) &&
                _isProgramActiveOn(detail.program, now)) {
              plannedItems.add(
                WeekPlanItem(
                  programDayId: day.day.id!,
                  dayIndex: day.day.dayIndex,
                  programName: detail.program.name,
                  imagePath: detail.program.imagePath,
                  dayTitle: day.day.title,
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
                  imagePath: detail.program.imagePath,
                  dayTitle: day.day.title,
                  dayOfWeek: dayOfWeek,
                  scheduledDate: date,
                  status: WeekPlanStatus.pending,
                ),
              );
            }
          }
        }
      }

      // Чистим записи прошлых недель перед чтением расписания (47.4).
      // Два DELETE-запроса по крошечным таблицам — дешевле, чем следить за тем,
      // не пережил ли экземпляр контроллера смену недели.
      await PlanScheduleCleaner(
        workoutRepository: workoutRepository,
        planScheduleRepository: planScheduleRepository,
      ).cleanupOldSchedule(now);

      // Добавляем ручные назначения из plan_schedule.
      final manualSchedule =
          await planScheduleRepository?.getForRange(rangeStart, rangeEnd) ??
          const <PlanScheduleItem>[];
      final existingKeys = <String>{
        for (final item in plannedItems)
          '${item.programDayId}|${_dateOnly(item.scheduledDate).millisecondsSinceEpoch}',
      };
      // Время показываем у всех тренировок на дату, включая дни по привязке:
      // у них строки в plan_schedule может не быть (время ещё не задавали),
      // а заданное — лежит в строке того же ключа {день, дата} и не создаёт
      // дубля (48.10).
      final timeByKey = <String, PlanScheduleItem>{
        for (final entry in manualSchedule)
          '${entry.programDayId}|${_dateOnly(entry.scheduledDate).millisecondsSinceEpoch}':
              entry,
      };
      for (final entry in manualSchedule) {
        final key =
            '${entry.programDayId}|${_dateOnly(entry.scheduledDate).millisecondsSinceEpoch}';
        if (existingKeys.contains(key)) {
          continue;
        }
        final day = await programRepository.getDay(entry.programDayId);
        if (day == null) {
          continue;
        }
        final programDetail = await programRepository.getProgram(day.programId);
        if (programDetail == null) {
          continue;
        }
        plannedItems.add(
          WeekPlanItem(
            programDayId: entry.programDayId,
            dayIndex: day.dayIndex,
            programName: programDetail.program.name,
            imagePath: programDetail.program.imagePath,
            dayTitle: day.title,
            dayOfWeek: null,
            scheduledDate: entry.scheduledDate,
            status: WeekPlanStatus.pending,
            isManual: true,
          ),
        );
        existingKeys.add(key);
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

      final marks = await _marksForRange(rangeStart, rangeEnd);

      final result = <WeekPlanItem>[];
      for (final item in plannedItems) {
        final weekStart = mondayOf(item.scheduledDate);
        final key = '${item.programDayId}|${weekStart.millisecondsSinceEpoch}';
        // Перенесённая тренировка очищает свой день-источник (47.3).
        if (marks.rescheduled.contains(key)) {
          continue;
        }
        final isSkipped = marks.skipped.contains(key);
        final time = timeByKey[item.scheduleKey];
        result.add(
          WeekPlanItem(
            programDayId: item.programDayId,
            dayIndex: item.dayIndex,
            programName: item.programName,
            imagePath: item.imagePath,
            // Кастомное название дня (48.12): без переноса здесь карточка и
            // лист действий всегда подставляли бы фолбэк «День N».
            dayTitle: item.dayTitle,
            dayOfWeek: item.dayOfWeek,
            scheduledDate: item.scheduledDate,
            isManual: item.isManual,
            muscleKeys: muscleKeysByDayId[item.programDayId] ?? const [],
            reminderHour: time?.reminderHour,
            reminderMinute: time?.reminderMinute,
            reminderEnabled: time?.reminderEnabled ?? false,
            status: _statusOf(
              item,
              sessionsByDayId[item.programDayId] ?? const <WorkoutSession>[],
              isSkipped,
              now,
            ),
          ),
        );
      }
      result.sort(_byDateThenTime);
      items.value = result;
    } on Exception catch (e, s) {
      // 53.3: ошибка чтения БД деградирует в явное состояние ошибки на экране
      // (с повтором), а не в «пустую неделю». Error (не Exception) летит выше.
      log('week plan load failed', error: e, stackTrace: s);
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Порядок карточек в плане: по дате, внутри дня — тренировки со временем
  /// по возрастанию, без времени — в конце (48.10).
  ///
  /// Равные даты раньше зависели от порядка обхода и могли «прыгать» между
  /// перезагрузками; третья составляющая — `programDayId` — делает порядок
  /// детерминированным полностью.
  static int _byDateThenTime(WeekPlanItem a, WeekPlanItem b) {
    final byDate = a.scheduledDate.compareTo(b.scheduledDate);
    if (byDate != 0) {
      return byDate;
    }
    final aTime = a.reminderHour == null || a.reminderMinute == null
        ? null
        : a.reminderHour! * 60 + a.reminderMinute!;
    final bTime = b.reminderHour == null || b.reminderMinute == null
        ? null
        : b.reminderHour! * 60 + b.reminderMinute!;
    if (aTime != bTime) {
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }
      return aTime.compareTo(bTime);
    }
    return a.programDayId.compareTo(b.programDayId);
  }

  /// Собирает ключи отметок `programDayId|weekStartMs` за период, разделённые
  /// по статусу: пропуски и переносы (47.3).
  Future<_PlanMarks> _marksForRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final skipped = <String>{};
    final rescheduled = <String>{};
    final weekStarts = <int>{};
    for (
      var date = rangeStart;
      !date.isAfter(rangeEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final ws = mondayOf(date);
      if (weekStarts.add(ws.millisecondsSinceEpoch)) {
        for (final mark in await workoutRepository.getMarks(ws)) {
          final key =
              '${mark.programDayId}|${mark.weekStart.millisecondsSinceEpoch}';
          switch (mark.status) {
            case ScheduleMarkStatus.skipped:
              skipped.add(key);
            case ScheduleMarkStatus.rescheduled:
              rescheduled.add(key);
          }
        }
      }
    }
    return _PlanMarks(skipped: skipped, rescheduled: rescheduled);
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
      if (sameDay) {
        return WeekPlanStatus.performed;
      }
      // Будущую запись нельзя «перенести»: чужая сессия того же programDayId
      // принадлежит другому вхождению (например выполнение на своём дне), а
      // не этой будущей тренировке. Если вхождение пропущено — «Пропущено»,
      // иначе — «Запланировано».
      if (item.scheduledDate.isAfter(now)) {
        return isSkipped ? WeekPlanStatus.skipped : WeekPlanStatus.pending;
      }
      return WeekPlanStatus.rescheduled;
    }
    if (isSkipped) {
      return WeekPlanStatus.skipped;
    }
    if (mondayOf(item.scheduledDate).isBefore(mondayOf(now))) {
      return WeekPlanStatus.pastSkipped;
    }
    return WeekPlanStatus.pending;
  }
}

/// Отметки недели, разделённые по статусу: пропуски и переносы (47.3).
class _PlanMarks {
  const _PlanMarks({required this.skipped, required this.rescheduled});

  final Set<String> skipped;
  final Set<String> rescheduled;
}

bool _inRange(DateTime date, DateTime start, DateTime end) =>
    !date.isBefore(start) && !date.isAfter(end);

/// Ключи групп мышц тренировочного дня (54.5): по основным упражнениям дня,
/// без дублей. Пусто — если у дня нет упражнений или каталог не передан.
List<String> _muscleKeysFor(
  ProgramDayDetail day,
  Map<int, List<MuscleGroup>> groupsByExercise,
) {
  final keys = <String>[];
  for (final exercise in day.mainExercises) {
    final id = exercise.exerciseId;
    if (id == null) {
      continue;
    }
    for (final muscle in groupsByExercise[id] ?? const <MuscleGroup>[]) {
      if (!keys.contains(muscle.key)) {
        keys.add(muscle.key);
      }
    }
  }
  return keys;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
