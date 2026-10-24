import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/widgets/calendar/month_grid.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_thumbnail.dart';
import 'package:fitnessappai/features/workout/data/plan_cleanup.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/ui/status_badge.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/quick_start_bar.dart';
import 'package:fitnessappai/features/workout/ui/reminder_time_dialog.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

/// Экран «План»: сетка недели и календарь месяца с тренировочными днями.
///
/// Переключатель Неделя/Месяц (54.5, образец `templates/IMG_20260920_204446`):
/// месяц — визуальный слой над теми же данными планирования, навигация
/// ограничена текущим и следующим периодом (прошлое закрыто, 51.2).
class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({
    super.key,
    this.programRepository,
    this.workoutRepository,
    this.planScheduleRepository,
    this.exerciseRepository,
    this.clock,
  });

  final ProgramRepository? programRepository;
  final WorkoutRepository? workoutRepository;
  final PlanScheduleRepository? planScheduleRepository;

  /// Каталог упражнений для иконок групп мышц в календаре месяца (54.5).
  final ExerciseRepository? exerciseRepository;

  /// Часы для детерминированных тестов: «сегодня» внутри экрана.
  final DateTime Function()? clock;

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  late final WeekPlanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WeekPlanController(
      programRepository:
          widget.programRepository ?? locator.get<ProgramRepository>(),
      workoutRepository:
          widget.workoutRepository ?? locator.get<WorkoutRepository>(),
      planScheduleRepository:
          widget.planScheduleRepository ??
          locator.get<PlanScheduleRepository>(),
      exerciseRepository:
          widget.exerciseRepository ?? _resolveExerciseRepository(),
      reminders: _resolveReminders(),
      clock: widget.clock,
    );
  }

  /// Каталог упражнений (54.5) регистрируется не во всех окружениях: в
  /// виджет-тестах контейнер может быть пустым — иконки групп мышц просто
  /// не показываются («без данных — без элементов»).
  ExerciseRepository? _resolveExerciseRepository() {
    try {
      return locator.get<ExerciseRepository>();
    } on StateError {
      return null;
    }
  }

  /// Одноразовые напоминания (48.10) регистрируются не во всех окружениях:
  /// в виджет-тестах контейнер может быть пустым, поэтому подключаем их
  /// только когда сервис действительно есть — как в `main.dart`.
  ReminderService? _resolveReminders() {
    try {
      return locator.get<ReminderService>();
    } on StateError {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _skip(WeekPlanItem item) => _controller.markSkipped(item);

  Future<void> _unskip(WeekPlanItem item) => _controller.clearSkip(item);

  /// Запуск тренировки из плана.
  ///
  /// Для переноса («Перенести на сегодня») день-источник НЕ очищается сразу:
  /// раньше он становился пустым ещё до выполнения тренировки, а выход без
  /// завершения ничего не менял (задача 48.4). Вместо этого неделя-источник
  /// пробрасывается до экрана выполнения, и отметка `rescheduled` ставится там
  /// только после фактического сохранения сессии (задачи 47.3 и 48.4).
  Future<void> _start(WeekPlanItem item) async {
    final actions = dayActionsFor(item, _controller.selectedDate.value);
    final rescheduleWeekStart = actions.contains(DayAction.reschedule)
        ? mondayOf(item.scheduledDate)
        : null;
    await startPlannedWorkout(
      context,
      _controller,
      item,
      rescheduleWeekStart: rescheduleWeekStart,
    );
  }

  Future<void> _cancel(WeekPlanItem item) =>
      _controller.cancelSchedule(item.programDayId, item.scheduledDate);

  /// Правка времени и напоминания уже назначенной тренировки (48.10).
  ///
  /// Прошедшая дата закрыта той же защитой, что и назначение (47.1/48.9):
  /// напоминание всё равно не сработало бы, а строка назначения прошлой
  /// недели на следующей загрузке удаляется (47.4).
  Future<void> _editTime(WeekPlanItem item) async {
    final l10n = AppLocalizations.of(context);
    if (_isPast(item.scheduledDate, _controller.selectedDate.value)) {
      showAppSnackBar(
        ScaffoldMessenger.of(context),
        l10n.weekPlanPastDateGuard,
      );
      return;
    }
    final result = await showReminderTimeDialog(
      context,
      hour: item.reminderHour,
      minute: item.reminderMinute,
      reminderEnabled: item.reminderEnabled,
    );
    if (result == null || !mounted) {
      return;
    }
    await _controller.setReminder(
      item.programDayId,
      item.scheduledDate,
      hour: result.hour,
      minute: result.minute,
      reminderEnabled: result.reminderEnabled,
    );
  }

  /// Обрабатывает тап по дню в сетке недели и календаре месяца.
  ///
  /// Пустой день — открывает лист планирования, занятый — действия дня.
  Future<void> _onDayTap(
    BuildContext context,
    WeekPlanController controller,
    DateTime date,
    AppLocalizations l10n,
  ) {
    return _showDayActions(context, controller, date, l10n);
  }

  bool _isPast(DateTime date, DateTime today) {
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    return d.isBefore(t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppTopBar(
        leading: const AppMenuButton(),
        title: l10n.navPlan,
        large: true,
      ),
      body: SignalBuilder(builder: (context) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    final today = controller.selectedDate.value;
    final view = controller.view.value;

    return Column(
      children: [
        _buildViewSegment(context, controller, l10n),
        if (view == WeekPlanView.week) ...[
          _buildWeekSwitcher(context, controller, l10n),
          Expanded(child: _buildWeekContent(context, controller, l10n, today)),
        ] else ...[
          _buildMonthSwitcher(controller),
          Expanded(child: _buildMonthContent(controller, l10n, today)),
        ],
      ],
    );
  }

  /// Переключатель вида Неделя/Месяц (54.5, сегмент 54.1, образец 204446).
  Widget _buildViewSegment(
    BuildContext context,
    WeekPlanController controller,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Center(
        child: AppSegmentedButton<WeekPlanView>(
          segments: [
            AppSegment(
              value: WeekPlanView.week,
              label: l10n.progressPeriodWeek,
            ),
            AppSegment(
              value: WeekPlanView.month,
              label: l10n.progressPeriodMonth,
            ),
          ],
          selected: {controller.view.value},
          onSelectionChanged: (selection) =>
              controller.setView(selection.first),
        ),
      ),
    );
  }

  Widget _buildMonthSwitcher(WeekPlanController controller) {
    final month = controller.monthStart.value;
    return MonthSwitcher(
      label: monthTitle(month),
      onPrevious: controller.canGoPrevMonth
          ? () => controller.shiftMonth(-1)
          : null,
      onNext: controller.canGoNextMonth ? () => controller.shiftMonth(1) : null,
    );
  }

  /// Месяц: календарь с индикацией тренировочных дней и карточка дня (54.5).
  ///
  /// Действий (начать/перенести/пропустить) в месяце нет — это визуальный
  /// слой над данными планирования; тап по тренировке в карточке открывает
  /// подготовку к ней.
  Widget _buildMonthContent(
    WeekPlanController controller,
    AppLocalizations l10n,
    DateTime today,
  ) {
    final month = controller.monthStart.value;
    final items = controller.items.value;
    if (controller.isLoading.value && items.isEmpty) {
      return const Center(child: AppSpinner());
    }
    if (controller.hasError.value && items.isEmpty) {
      return _buildLoadError(context, controller, l10n);
    }
    final selected = controller.effectiveMonthDate;
    return Column(
      children: [
        // Календарь доминирует: сетка забирает высоту после карточки дня
        // (карточка — non-flex со своим интринсиком, максимум 240 со
        // скроллом — иначе два flex:1 делили высоту строго 50/50).
        Expanded(
          child: MonthGridView(
            monthStart: month,
            today: today,
            fillHeight: true,
            onPrevious: controller.canGoPrevMonth
                ? () => controller.shiftMonth(-1)
                : null,
            onNext: controller.canGoNextMonth
                ? () => controller.shiftMonth(1)
                : null,
            cellBuilder: (context, date) =>
                _buildMonthCell(context, controller, date, month, today),
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _MonthDayCard(
              date: selected,
              items: _itemsForDay(items, selected),
              today: today,
              actionable: _monthWorkoutActionable,
              onOpen: _start,
            ),
          ),
      ],
    );
  }

  /// Ячейка календаря месяца: тренировочный день — `primaryContainer` плюс
  /// иконки групп мышц; «сегодня» — glow (тёмная тема) и рамка; выбранный
  /// день — акцентная рамка.
  Widget _buildMonthCell(
    BuildContext context,
    WeekPlanController controller,
    DateTime date,
    DateTime month,
    DateTime today,
  ) {
    if (date.month != month.month || date.year != month.year) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final dayItems = _itemsForDay(controller.items.value, date);
    final isTraining = dayItems.isNotEmpty;
    final isToday = _sameDay(date, today);
    final selected = controller.effectiveMonthDate;
    final isSelected = selected != null && _sameDay(date, selected);
    final cell = MonthDayCell(
      day: date.day,
      fillHeight: true,
      background: isTraining
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      foreground: isTraining
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurfaceVariant,
      isToday: isToday,
      icons: _cellMuscleIcons(dayItems),
      border: isSelected || isToday
          ? Border.all(color: colorScheme.primary, width: isSelected ? 1.5 : 1)
          : null,
      onTap: () => controller.selectMonthDate(date),
    );
    if (!isToday) {
      return cell;
    }
    // «Сегодня»: неон-обводка и свечение по токенам `AppGlow` (в светлой
    // теме остаётся только рамка — как у всего glow в редизайне 54).
    return AppGlowContainer(
      radius: AppRadii.md,
      intensity: 0.8,
      showBorder: false,
      child: cell,
    );
  }

  /// До двух иконок групп мышц дня: дедупликация по ассету (грудь и пресс —
  /// один ассет «press»), порядок — порядок загрузки.
  List<Widget> _cellMuscleIcons(List<WeekPlanItem> dayItems) {
    final keys = MuscleGroupIcon.dedupeByAsset([
      for (final item in dayItems) ...item.muscleKeys,
    ]);
    return [
      // 16dp — минимум читаемости иконок-ассетов по базе (16–18dp в
      // «Упражнениях»/детали); две по 16 + зазор 2 влезают в контент ячейки.
      for (final key in keys.take(2)) MuscleGroupIcon(muscleKey: key, size: 16),
    ];
  }

  /// Тап по строке тренировки карточки месяца (54.5) — тот же гейтинг, что
  /// в недельном виде (47.1): запуск/перенос разрешает только
  /// `dayActionsFor` (сам [`_start`] вычисляет `rescheduleWeekStart`).
  /// Выполненные/пропущенные/ручные и прочие строки без действий —
  /// информационные, обработчика тапа не имеют.
  bool _monthWorkoutActionable(WeekPlanItem item) {
    final actions = dayActionsFor(item, _controller.selectedDate.value);
    return actions.contains(DayAction.start) ||
        actions.contains(DayAction.reschedule);
  }

  Widget _buildWeekSwitcher(
    BuildContext context,
    WeekPlanController controller,
    AppLocalizations l10n,
  ) {
    final weekStart = controller.weekStart.value;
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    return _WeekSwitcher(
      label: _weekRangeLabel(days.first, days.last, l10n),
      onPrev: controller.canGoPrevWeek ? () => controller.shiftWeek(-1) : null,
      onNext: controller.canGoNextWeek ? () => controller.shiftWeek(1) : null,
    );
  }

  Widget _buildWeekContent(
    BuildContext context,
    WeekPlanController controller,
    AppLocalizations l10n,
    DateTime today,
  ) {
    final items = controller.items.value;
    if (controller.isLoading.value && items.isEmpty) {
      return const Center(child: AppSpinner());
    }
    if (controller.hasError.value && items.isEmpty) {
      // 53.3: сбой чтения БД показываем явно, а не маскируем пустой неделей.
      return _buildLoadError(context, controller, l10n);
    }
    if (items.isEmpty) {
      return _WeekEmpty(
        l10n: l10n,
        onSchedule: () =>
            _onDayTap(context, controller, controller.selectedDate.value, l10n),
      );
    }
    final weekStart = controller.weekStart.value;
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppBreakpoints.isExpanded(constraints.maxWidth)) {
          return _WeekGrid(
            days: days,
            items: items,
            today: today,
            onStart: _start,
            onSkip: _skip,
            onUnskip: _unskip,
            onCancel: _cancel,
            onEditTime: _editTime,
            onDayTap: (date) => _onDayTap(context, controller, date, l10n),
          );
        }
        return _WeekList(
          days: days,
          items: items,
          today: today,
          onStart: _start,
          onSkip: _skip,
          onUnskip: _unskip,
          onCancel: _cancel,
          onEditTime: _editTime,
          onDayTap: (date) => _onDayTap(context, controller, date, l10n),
        );
      },
    );
  }

  /// Явное состояние ошибки загрузки плана (53.3): сообщение и повтор.
  Widget _buildLoadError(
    BuildContext context,
    WeekPlanController controller,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          AppText(
            l10n.weekPlanLoadError,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppTextButton(
            label: l10n.weekPlanRetry,
            onPressed: controller.refresh,
          ),
        ],
      ),
    );
  }

  Future<void> _showDayActions(
    BuildContext context,
    WeekPlanController controller,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final dayItems = controller.items.value
        .where((item) => _sameDay(item.scheduledDate, date))
        .toList();
    if (dayItems.isEmpty) {
      // Не планируем на прошедшие даты.
      if (_isPast(date, controller.selectedDate.value)) {
        showAppSnackBar(
          ScaffoldMessenger.of(context),
          l10n.weekPlanPastDateGuard,
        );
        return Future.value();
      }
      return _showScheduleSheet(context, controller, date, l10n);
    }
    return showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: AppListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppText(
                DateFormat('d MMMM yyyy', 'ru').format(date),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in dayItems)
              _DayActionTile(
                item: item,
                today: controller.selectedDate.value,
                onStart: () {
                  Navigator.of(sheetContext).pop();
                  _start(item);
                },
                onSkip: () {
                  Navigator.of(sheetContext).pop();
                  _skip(item);
                },
                onUnskip: () {
                  Navigator.of(sheetContext).pop();
                  _unskip(item);
                },
                // Пункт «Время и напоминание» (48.10): для дня, у которого
                // времени ещё нет, это единственный способ его задать.
                onEditTime: () {
                  Navigator.of(sheetContext).pop();
                  _editTime(item);
                },
                onCancel: () {
                  Navigator.of(sheetContext).pop();
                  controller.cancelSchedule(item.programDayId, date);
                },
              ),
            // 48.9: к действиям над существующими тренировками добавляем
            // планирование ещё одной. Отдельным разделителем — иначе неотличимо
            // от действия над чужой тренировкой.
            const AppDivider(height: 24),
            AppListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const AppIcon(Icons.edit_calendar),
              title: AppText(l10n.weekPlanScheduleTitle),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(sheetContext).pop();
                // Та же защита, что и у пустого дня: в прошедшей дате лист
                // планирования молча ничего не сделал бы (48.9).
                if (_isPast(date, controller.selectedDate.value)) {
                  showAppSnackBar(messenger, l10n.weekPlanPastDateGuard);
                  return;
                }
                _showScheduleSheet(context, controller, date, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleSheet(
    BuildContext context,
    WeekPlanController controller,
    DateTime date,
    AppLocalizations l10n,
  ) {
    return showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _ScheduleSheet(date: date, controller: controller),
    );
  }
}

class _WeekSwitcher extends StatelessWidget {
  const _WeekSwitcher({required this.label, this.onPrev, required this.onNext});

  final String label;

  /// Переход на предыдущую неделю; `null`, если показана текущая неделя —
  /// из неё назад нельзя (нижняя граница навигации, 51.2).
  final VoidCallback? onPrev;

  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          AppIconButton(
            onPressed: onPrev,
            tooltip: l10n.weekPlanPrevWeek,
            icon: const AppIcon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: AppText(label, style: theme.textTheme.titleMedium),
            ),
          ),
          AppIconButton(
            onPressed: onNext,
            tooltip: l10n.weekPlanNextWeek,
            icon: const AppIcon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

typedef _WorkoutAction = void Function(WeekPlanItem item);

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.days,
    required this.items,
    required this.today,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onCancel,
    required this.onEditTime,
    this.onDayTap,
  });

  final List<DateTime> days;
  final List<WeekPlanItem> items;
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

  /// Правка времени и напоминания тренировки (48.10).
  final _WorkoutAction onEditTime;

  /// Тап по дню — открыть планирование или действия дня.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < days.length; i++) ...[
            Expanded(
              child: _DayColumn(
                date: days[i],
                items: _itemsForDay(items, days[i]),
                isToday: _sameDay(days[i], today),
                today: today,
                onStart: onStart,
                onSkip: onSkip,
                onUnskip: onUnskip,
                onCancel: onCancel,
                onEditTime: onEditTime,
                onDayTap: onDayTap,
              ),
            ),
            if (i < days.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _WeekList extends StatelessWidget {
  const _WeekList({
    required this.days,
    required this.items,
    required this.today,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onCancel,
    required this.onEditTime,
    this.onDayTap,
  });

  final List<DateTime> days;
  final List<WeekPlanItem> items;
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

  /// Правка времени и напоминания тренировки (48.10).
  final _WorkoutAction onEditTime;

  /// Тап по дню — открыть планирование или действия дня.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    return AppListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _DayCard(
            date: date,
            items: _itemsForDay(items, date),
            isToday: _sameDay(date, today),
            today: today,
            onStart: onStart,
            onSkip: onSkip,
            onUnskip: onUnskip,
            onCancel: onCancel,
            onEditTime: onEditTime,
            onDayTap: onDayTap,
          ),
        );
      },
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.items,
    required this.isToday,
    required this.today,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onCancel,
    required this.onEditTime,
    this.onDayTap,
  });

  final DateTime date;
  final List<WeekPlanItem> items;
  final bool isToday;

  /// Сегодняшняя дата — определяет набор доступных действий (47.1).
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

  /// Правка времени и напоминания тренировки (48.10).
  final _WorkoutAction onEditTime;

  /// Тап по дню — открыть планирование или действия дня.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    // Заголовок дня тапается в обоих случаях: у занятого дня он открывает
    // лист действий, у пустого — планирование (47.16).
    final header = AppGestureDetector(
      onTap: onDayTap == null ? null : () => onDayTap!(date),
      behavior: HitTestBehavior.opaque,
      child: _DayHeader(
        date: date,
        isToday: isToday,
        times: _timeLabels(items),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) ...[
          header,
          const SizedBox(height: 8),
          AppListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlannedWorkoutCard(
                item: items[index],
                today: today,
                onStart: onStart,
                onSkip: onSkip,
                onUnskip: onUnskip,
                onCancel: onCancel,
                onEditTime: onEditTime,
              ),
            ),
          ),
        ] else
          Padding(padding: const EdgeInsets.only(bottom: 24), child: header),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.items,
    required this.isToday,
    required this.today,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onCancel,
    required this.onEditTime,
    this.onDayTap,
  });

  final DateTime date;
  final List<WeekPlanItem> items;
  final bool isToday;

  /// Сегодняшняя дата — определяет набор доступных действий (47.1).
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

  /// Правка времени и напоминания тренировки (48.10).
  final _WorkoutAction onEditTime;

  /// Тап по дню — открыть планирование или действия дня.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: AppInkWell(
        onTap: onDayTap == null ? null : () => onDayTap!(date),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(
                date: date,
                isToday: isToday,
                times: _timeLabels(items),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PlannedWorkoutCard(
                      item: item,
                      today: today,
                      onStart: onStart,
                      onSkip: onSkip,
                      onUnskip: onUnskip,
                      onCancel: onCancel,
                      onEditTime: onEditTime,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.isToday,
    this.times = const [],
  });

  final DateTime date;
  final bool isToday;

  /// Времена тренировок дня рядом с датой (48.10), по возрастанию.
  ///
  /// Пусто у дней без заданного времени — так и должно быть: время в плане
  /// необязательно.
  final List<String> times;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText(
              _weekdayLabel(l10n, date.weekday),
              style: theme.textTheme.labelLarge?.copyWith(
                color: isToday ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 6),
              AppContainer(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: AppText(
                  l10n.weekPlanToday,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        AppText(
          '${date.day}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        if (times.isNotEmpty)
          AppText(
            times.join(', '),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isToday
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
    if (!isToday) {
      return header;
    }
    // Текущий день выделяем цветным блоком для наглядности.
    return AppContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: header,
    );
  }
}

class _PlannedWorkoutCard extends StatelessWidget {
  const _PlannedWorkoutCard({
    required this.item,
    required this.today,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onEditTime,
    this.onCancel,
  });

  final WeekPlanItem item;

  /// Сегодняшняя дата — определяет набор доступных действий (47.1).
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction? onCancel;

  /// Правка времени и напоминания (48.10) — тап по строке времени карточки.
  final _WorkoutAction onEditTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = item.status;
    final actions = dayActionsFor(item, today);

    // Крестик удаления — только для ручных назначений из plan_schedule.
    final showCancel = actions.contains(DayAction.remove) && onCancel != null;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProgramThumbnail(imagePath: item.imagePath, size: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        item.programName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppText(
                        '${item.dayTitle ?? l10n.programBuilderDay(item.dayIndex + 1)} · '
                        '${DateFormat('d MMMM yyyy', 'ru').format(item.scheduledDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showCancel)
                  AppIconButton(
                    onPressed: () => onCancel!(item),
                    tooltip: l10n.weekPlanRemove,
                    visualDensity: VisualDensity.compact,
                    icon: const AppIcon(Icons.close, size: 18),
                  ),
                if (showCancel) const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatusBadge(status: status),
                  ),
                ),
              ],
            ),
            if (item.hasTime) ...[
              const SizedBox(height: 4),
              AppInkWell(
                onTap: () => onEditTime(item),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                // 53.3: единственный вход в «Время и напоминание» — тап-таргет
                // поднят до минимума Material (48dp), контент центрируется.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const AppIcon(Icons.access_time, size: 14),
                        const SizedBox(width: 4),
                        AppText(
                          item.timeLabel!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (item.reminderEnabled) ...[
                          const SizedBox(width: 4),
                          AppIcon(
                            Icons.notifications_active,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (status == WeekPlanStatus.pending) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                // Выравнивание ряда по центру — пилюля выше text-кнопки
                // «Пропустить» (дизайн-ревью 55.3 Low).
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (actions.contains(DayAction.start))
                    // 55.3: primary-действие дня — pill-CTA (паттерн 54.4/54.7).
                    AppGradientButton(
                      pill: true,
                      onPressed: () => onStart(item),
                      icon: Icons.play_arrow,
                      label: l10n.weekPlanStart,
                    ),
                  if (actions.contains(DayAction.reschedule))
                    AppButton(
                      tonal: true,
                      icon: Icons.event_repeat_outlined,
                      label: l10n.weekPlanReschedule,
                      onPressed: () => onStart(item),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  if (actions.contains(DayAction.skip))
                    AppTextButton(
                      label: l10n.weekPlanSkip,
                      onPressed: () => onSkip(item),
                    ),
                ],
              ),
            ],
            if (actions.contains(DayAction.unskip))
              Align(
                alignment: Alignment.centerRight,
                child: AppTextButton(
                  label: l10n.weekPlanUnskip,
                  onPressed: () => onUnskip(item),
                  icon: Icons.undo,
                  iconSize: 18,
                ),
              ),
            if (status == WeekPlanStatus.pastSkipped) ...[
              const SizedBox(height: 8),
              const _MissedWorkoutHint(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Подсказка под пропущенной тренировкой: перенос возможен только внутри
/// своей тренировочной недели (задача 47.2).
class _MissedWorkoutHint extends StatelessWidget {
  const _MissedWorkoutHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return AppContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: AppText(
              AppLocalizations.of(context).weekPlanMissedHint,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekEmpty extends StatelessWidget {
  const _WeekEmpty({required this.l10n, this.onSchedule});

  final AppLocalizations l10n;

  /// Тап по пустой неделе — открыть планирование на сегодня.
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            Icons.event_note_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          AppText(
            l10n.weekPlanEmpty,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AppText(
            l10n.weekPlanHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          // 53.3: подсказка вела в конструктор, а тап по экрану открывал лист
          // планирования — affordance теперь явный, а не «угадай по тапу».
          if (onSchedule != null) ...[
            const SizedBox(height: 20),
            AppGradientButton(
              label: l10n.weekPlanScheduleTitle,
              onPressed: onSchedule,
            ),
          ],
        ],
      ),
    );
    if (onSchedule == null) {
      return Center(child: content);
    }
    return Center(
      child: AppInkWell(
        onTap: onSchedule,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: content,
      ),
    );
  }
}

class _DayActionTile extends StatelessWidget {
  const _DayActionTile({
    required this.item,
    required this.today,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onEditTime,
    this.onCancel,
  });

  final WeekPlanItem item;

  /// Сегодняшняя дата — определяет набор доступных действий (47.1).
  final DateTime today;
  final VoidCallback onStart;
  final VoidCallback onSkip;
  final VoidCallback onUnskip;
  final VoidCallback? onCancel;

  /// Правка времени и напоминания (48.10) — пункт «Время и напоминание».
  ///
  /// Для дня без времени это единственный способ его задать: на карточке
  /// строки в этом случае нет.
  final VoidCallback onEditTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = item.status;
    final actions = dayActionsFor(item, today);
    final title = AppText(
      '${item.programName} → '
      '${item.dayTitle ?? l10n.programBuilderDay(item.dayIndex + 1)}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: title,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: switch (status) {
              WeekPlanStatus.pending => Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (actions.contains(DayAction.start))
                    // 55.3: primary-действие дня — pill-CTA (паттерн 54.4/54.7).
                    AppGradientButton(
                      pill: true,
                      onPressed: onStart,
                      icon: Icons.play_arrow,
                      label: l10n.weekPlanStart,
                    ),
                  if (actions.contains(DayAction.reschedule))
                    AppButton(
                      tonal: true,
                      icon: Icons.event_repeat_outlined,
                      label: l10n.weekPlanReschedule,
                      onPressed: onStart,
                    ),
                  if (actions.contains(DayAction.skip))
                    AppTextButton(label: l10n.weekPlanSkip, onPressed: onSkip),
                  // Удаление — единственное действие кастомного назначения,
                  // поэтому с подписью, а не голым крестиком.
                  if (actions.contains(DayAction.remove) && onCancel != null)
                    AppTextButton(
                      label: l10n.weekPlanRemove,
                      onPressed: onCancel,
                      icon: Icons.close,
                      iconSize: 18,
                    ),
                ],
              ),
              WeekPlanStatus.skipped =>
                actions.contains(DayAction.unskip)
                    ? AppTextButton(
                        label: l10n.weekPlanUnskip,
                        onPressed: onUnskip,
                        icon: Icons.undo,
                        iconSize: 18,
                      )
                    : StatusBadge(status: status),
              WeekPlanStatus.performed ||
              WeekPlanStatus.rescheduled ||
              WeekPlanStatus.pastSkipped => StatusBadge(status: status),
            },
          ),
          if (status == WeekPlanStatus.pastSkipped) ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _MissedWorkoutHint(),
            ),
          ],
          AppListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const AppIcon(Icons.access_time, size: 20),
            title: AppText(l10n.weekPlanTimeAction),
            subtitle: AppText(item.timeLabel ?? l10n.weekPlanNoTime),
            onTap: onEditTime,
          ),
        ],
      ),
    );
  }
}

String _weekRangeLabel(DateTime start, DateTime end, AppLocalizations l10n) {
  final fmt = DateFormat('d MMMM', 'ru');
  if (start.year == end.year && start.month == end.month) {
    return '${start.day}–${fmt.format(end)}';
  }
  return '${fmt.format(start)} – ${fmt.format(end)}';
}

List<WeekPlanItem> _itemsForDay(List<WeekPlanItem> items, DateTime day) =>
    items.where((item) => _sameDay(item.scheduledDate, day)).toList();

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Времена тренировок дня для заголовка — «09:00, 18:00» (48.10).
///
/// Порядок берётся из порядка списка (план сортирует карточки по возрастанию
/// времени, см. `WeekPlanController._byDateThenTime`), дубли одного времени
/// схлопываются.
List<String> _timeLabels(List<WeekPlanItem> items) {
  final labels = <String>{};
  for (final item in items) {
    final label = item.timeLabel;
    if (label != null) {
      labels.add(label);
    }
  }
  return labels.toList();
}

String _weekdayLabel(AppLocalizations l10n, int weekday) => switch (weekday) {
  1 => l10n.weekdayMon,
  2 => l10n.weekdayTue,
  3 => l10n.weekdayWed,
  4 => l10n.weekdayThu,
  5 => l10n.weekdayFri,
  6 => l10n.weekdaySat,
  7 => l10n.weekdaySun,
  _ => '',
};

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.date, required this.controller});

  final DateTime date;
  final WeekPlanController controller;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  ProgramSummary? _selectedProgram;
  ProgramDetail? _programDetail;
  bool _loading = true;

  /// Программы листа (53.3): раньше подтягивались немемоизированным
  /// `FutureBuilder` в `build()` — двойной запрос к БД и мелькающий спиннер
  /// при любом rebuild листа. Теперь грузятся один раз в `_loadPrograms`.
  List<ProgramSummary>? _programs;

  /// Ошибка загрузки программ листа (53.3).
  bool _loadError = false;

  /// Шаг «время» (48.10): день выбран, осталось время и подтверждение.
  ProgramDay? _selectedDay;

  /// Время шага; `null` — без времени, назначение как раньше.
  TimeOfDay? _time;

  /// Галочка напоминания шага; включается только вместе со временем.
  bool _reminderOn = false;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final programs = await widget.controller.programRepository.getPrograms();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = false;
        _programs = programs;
      });
      // Auto-select if only one program.
      if (programs.length == 1) {
        await _selectProgram(programs.first);
      }
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  /// Повтор загрузки программ после ошибки (53.3).
  void _retryPrograms() {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    _loadPrograms();
  }

  Future<void> _selectProgram(ProgramSummary summary) async {
    final detail = await widget.controller.programRepository.getProgram(
      summary.program.id!,
    );
    if (!mounted) return;
    setState(() {
      _selectedProgram = summary;
      _programDetail = detail;
    });
  }

  void _selectDay(ProgramDay day) {
    final programDayId = day.id!;
    // 48.9: день программы, уже назначенный на эту дату, schedule() принял бы
    // молча (insertOrIgnore по уникальному ключу {programDayId, scheduledDate}).
    // Решение владельца — не создавать ложное ожидание: показать «уже
    // запланировано» и закрыть лист.
    final alreadyScheduled = widget.controller.items.value.any(
      (item) =>
          item.programDayId == programDayId &&
          _sameDay(item.scheduledDate, widget.date),
    );
    if (alreadyScheduled) {
      final messenger = ScaffoldMessenger.of(context);
      final l10n = AppLocalizations.of(context);
      Navigator.of(context).pop();
      showAppSnackBar(messenger, l10n.weekPlanAlreadyScheduled);
      return;
    }
    // 48.10: перед назначением — шаг времени и напоминания.
    setState(() {
      _selectedDay = day;
    });
  }

  /// Подтверждает назначение с выбранным временем (48.10).
  ///
  /// Время можно не задать: `hour`/`minute` тогда уходят в `null` и
  /// назначение происходит ровно как до 48.10.
  Future<void> _confirm() async {
    final day = _selectedDay;
    if (day == null) {
      return;
    }
    final time = _time;
    await widget.controller.scheduleDay(
      day.id!,
      widget.date,
      hour: time?.hour,
      minute: time?.minute,
      reminderEnabled: time != null && _reminderOn,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              l10n.weekPlanScheduleTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            AppText(
              DateFormat('d MMMM yyyy', 'ru').format(widget.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: AppSpinner())
            else if (_selectedDay != null)
              _buildTimeStep(l10n, theme)
            else if (_selectedProgram == null)
              _buildProgramList(l10n)
            else
              _buildDayList(l10n, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramList(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: AppSpinner());
    }
    if (_loadError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                l10n.weekPlanScheduleLoadError,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AppTextButton(
                label: l10n.weekPlanRetry,
                onPressed: _retryPrograms,
              ),
            ],
          ),
        ),
      );
    }
    final programs = _programs ?? const <ProgramSummary>[];
    if (programs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: AppText(l10n.weekPlanScheduleNoPrograms)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          l10n.weekPlanScheduleSelectProgram,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        for (final summary in programs)
          AppListTile(
            title: AppText(summary.program.name),
            subtitle: AppText(
              l10n.programExercisesCount(summary.exercisesCount),
            ),
            trailing: const AppIcon(Icons.chevron_right),
            onTap: () => _selectProgram(summary),
          ),
      ],
    );
  }

  Widget _buildDayList(AppLocalizations l10n, ThemeData theme) {
    final detail = _programDetail;
    if (detail == null) {
      return const Center(child: AppSpinner());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIconButton(
              onPressed: () => setState(() {
                _selectedProgram = null;
                _programDetail = null;
              }),
              icon: const AppIcon(Icons.arrow_back),
            ),
            Expanded(
              child: AppText(
                detail.program.name,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final day in detail.days)
          AppListTile(
            title: AppText(
              day.day.title ?? l10n.programBuilderDay(day.day.dayIndex + 1),
            ),
            subtitle: AppText(
              day.day.dayOfWeek != null
                  ? _weekdayLabel(l10n, day.day.dayOfWeek!)
                  : l10n.programBuilderDayNoWeekday,
            ),
            trailing: const AppIcon(Icons.add_circle_outline),
            onTap: () => _selectDay(day.day),
          ),
      ],
    );
  }

  /// Шаг «время и напоминание» перед назначением (48.10).
  ///
  /// Назначение подтверждается здесь: время необязательно, поэтому кнопка
  /// активна всегда и без времени назначение происходит как раньше.
  Widget _buildTimeStep(AppLocalizations l10n, ThemeData theme) {
    final day = _selectedDay!;
    final detail = _programDetail;
    final dayTitle = day.title ?? l10n.programBuilderDay(day.dayIndex + 1);
    final heading = detail == null
        ? dayTitle
        : '${detail.program.name} → $dayTitle';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIconButton(
              onPressed: () => setState(() {
                _selectedDay = null;
              }),
              icon: const AppIcon(Icons.arrow_back),
            ),
            Expanded(
              child: AppText(
                heading,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppText(l10n.weekPlanTimeAction, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        ReminderTimeFields(
          time: _time,
          reminderEnabled: _reminderOn,
          onTimeChanged: (value) => setState(() {
            _time = value;
          }),
          onReminderChanged: (value) => setState(() {
            _reminderOn = value;
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppGradientButton(
            label: l10n.weekPlanScheduleConfirm,
            onPressed: _confirm,
          ),
        ),
      ],
    );
  }
}

/// Карточка выбранного дня под календарем месяца (54.5, образец 204446):
/// дата и тренировки дня со статусами; тап по разрешённой тренировке
/// ([actionable]) открывает подготовку через `_start` с гейтингом 47.1.
class _MonthDayCard extends StatelessWidget {
  const _MonthDayCard({
    required this.date,
    required this.items,
    required this.today,
    required this.actionable,
    required this.onOpen,
  });

  final DateTime date;
  final List<WeekPlanItem> items;

  /// Сегодняшняя дата — бейдж «Сегодня» в шапке карточки.
  final DateTime today;

  /// Разрешает ли строка тренировки тап (`dayActionsFor`: start/reschedule).
  final bool Function(WeekPlanItem item) actionable;

  /// Тап по разрешённой тренировке — переход на день (подготовка).
  final _WorkoutAction onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isToday = _sameDay(date, today);
    // Карточка ограничена по высоте: при многих тренировках дня она
    // прокручивается внутри, не сжимая календарь.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: AppListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    DateFormat('d MMMM yyyy', 'ru').format(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isToday)
                  AppContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: AppText(
                      l10n.weekPlanToday,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AppText(
                  l10n.weekPlanEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MonthWorkoutRow(
                  item: item,
                  actionable: actionable(item),
                  onOpen: onOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Строка тренировки в карточке дня месяца: превью, «Программа → День N»,
/// время, статус; тап разрешён только для строк с действиями (47.1) —
/// иначе строка информационная (`onTap: null`).
class _MonthWorkoutRow extends StatelessWidget {
  const _MonthWorkoutRow({
    required this.item,
    required this.actionable,
    required this.onOpen,
  });

  final WeekPlanItem item;
  final bool actionable;
  final _WorkoutAction onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppInkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: actionable ? () => onOpen(item) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ProgramThumbnail(imagePath: item.imagePath, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${item.programName} → '
                    '${item.dayTitle ?? l10n.programBuilderDay(item.dayIndex + 1)}',
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.hasTime)
                    AppText(
                      item.timeLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: StatusBadge(status: item.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
