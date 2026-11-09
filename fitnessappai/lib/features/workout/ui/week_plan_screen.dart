import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/widgets/calendar/month_grid.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/ui/status_badge.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/quick_start_bar.dart';
import 'package:fitnessappai/features/workout/ui/reminder_time_dialog.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

/// Экран «План»: единый календарь-месяц с тренировочными днями (59.5).
///
/// Тап по любой ячейке открывает дравер действий дня (59.2-паттерн);
/// навигация месяцами — вперёд без ограничения, назад по пройденным
/// (59.5.в).
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

  /// Запуск тренировки из плана (только сегодняшний день — 59.5.д).
  Future<void> _start(WeekPlanItem item) async {
    await startPlannedWorkout(context, _controller, item);
  }

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

    return Column(
      children: [
        _buildMonthSwitcher(controller),
        Expanded(child: _buildMonthContent(controller, l10n, today)),
      ],
    );
  }

  Widget _buildMonthSwitcher(WeekPlanController controller) {
    final month = controller.monthStart.value;
    return MonthSwitcher(
      label: monthTitle(month),
      onPrevious: controller.canGoPrevMonth
          ? () => controller.shiftMonth(-1)
          : null,
      // 59.5.в: вперёд — без ограничения.
      onNext: () => controller.shiftMonth(1),
    );
  }

  /// Месяц: единственный вид плана (59.5.а) — календарь с индикацией
  /// тренировочных дней; тап по дню открывает дравер действий дня (59.5.б,
  /// перенос логики недели).
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
    // Календарь занимает всю высоту: информация о дне — по тапу в дравере
    // (59.5.б), фиксированная карточка под сеткой удалена.
    return MonthGridView(
      monthStart: month,
      today: today,
      fillHeight: true,
      onPrevious: controller.canGoPrevMonth
          ? () => controller.shiftMonth(-1)
          : null,
      onNext: () => controller.shiftMonth(1),
      cellBuilder: (context, date) =>
          _buildMonthCell(context, controller, date, month, today, l10n),
    );
  }

  /// Ячейка календаря месяца: тренировочный день — `primaryContainer` плюс
  /// иконки групп мышц; «сегодня» — glow (тёмная тема) и рамка. Тап по любому
  /// дню открывает дравер действий дня (59.5.б — логика недели).
  Widget _buildMonthCell(
    BuildContext context,
    WeekPlanController controller,
    DateTime date,
    DateTime month,
    DateTime today,
    AppLocalizations l10n,
  ) {
    if (date.month != month.month || date.year != month.year) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final dayItems = _itemsForDay(controller.items.value, date);
    final isTraining = dayItems.isNotEmpty;
    final isToday = _sameDay(date, today);
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
      border: isToday ? Border.all(color: colorScheme.primary) : null,
      onTap: () => _onDayTap(context, controller, date, l10n),
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
      // 59.5 + design-review: каждый элемент дня — отдельная карточка. При
      // двух и более назначениях на дату строка «Время и напоминание»
      // однозначно относится к своей тренировке (конвенция 55.4, паттерн
      // day_sessions_sheet), заголовки внутри карточки — единый язык.
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppListTile(
              dense: true,
              // 59.5 + design-review Low: contentPadding 12 — одна левая
              // грань текста заголовка и блока действий (4dp перекос).
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: title,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: switch (status) {
                // 59.5: день без действий (будущий) — бейдж статуса вместо
                // пустой строки: тап по дню должен объяснять его состояние.
                WeekPlanStatus.pending when actions.isEmpty => StatusBadge(
                  status: status,
                ),
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
                    if (actions.contains(DayAction.skip))
                      AppTextButton(
                        label: l10n.weekPlanSkip,
                        onPressed: onSkip,
                      ),
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
            AppListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: const AppIcon(Icons.access_time, size: 20),
              title: AppText(l10n.weekPlanTimeAction),
              subtitle: AppText(item.timeLabel ?? l10n.weekPlanNoTime),
              onTap: onEditTime,
            ),
          ],
        ),
      ),
    );
  }
}

List<WeekPlanItem> _itemsForDay(List<WeekPlanItem> items, DateTime day) =>
    items.where((item) => _sameDay(item.scheduledDate, day)).toList();

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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
