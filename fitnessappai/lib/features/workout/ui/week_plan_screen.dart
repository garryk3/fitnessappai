import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/widgets/calendar/month_grid.dart';
import 'package:fitnessappai/core/ui/program_thumbnail.dart';
import 'package:fitnessappai/core/ui/status_badge.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_view_settings_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/quick_start_bar.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран «План»: сетка недели или календарь месяца с тренировочными днями.
class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({
    super.key,
    this.programRepository,
    this.workoutRepository,
    this.planViewSettingsRepository,
    this.planScheduleRepository,
    this.clock,
  });

  final ProgramRepository? programRepository;
  final WorkoutRepository? workoutRepository;
  final PlanViewSettingsRepository? planViewSettingsRepository;
  final PlanScheduleRepository? planScheduleRepository;

  /// Часы для детерминированных тестов: «сегодня» внутри экрана.
  final DateTime Function()? clock;

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  late final WeekPlanController _controller;
  late final PlanViewSettingsRepository _viewSettings;

  @override
  void initState() {
    super.initState();
    _viewSettings =
        widget.planViewSettingsRepository ??
        locator.get<PlanViewSettingsRepository>();
    _controller = WeekPlanController(
      programRepository:
          widget.programRepository ?? locator.get<ProgramRepository>(),
      workoutRepository:
          widget.workoutRepository ?? locator.get<WorkoutRepository>(),
      planScheduleRepository:
          widget.planScheduleRepository ??
          locator.get<PlanScheduleRepository>(),
      clock: widget.clock,
    );
    _restoreViewMode();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreViewMode() async {
    final mode = await _viewSettings.getViewMode();
    if (mode != PlanViewMode.week) {
      await _controller.setViewMode(mode);
    }
  }

  Future<void> _onModeChanged(PlanViewMode mode) async {
    await _viewSettings.setViewMode(mode);
    await _controller.setViewMode(mode);
  }

  Future<void> _skip(WeekPlanItem item) => _controller.markSkipped(item);

  Future<void> _unskip(WeekPlanItem item) => _controller.clearSkip(item);

  Future<void> _start(WeekPlanItem item) =>
      startPlannedWorkout(context, _controller, item);

  Future<void> _cancel(WeekPlanItem item) =>
      _controller.cancelSchedule(item.programDayId, item.scheduledDate);

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
    return Scaffold(
      appBar: AppBar(leading: const AppMenuButton(), title: Text(l10n.navPlan)),
      body: SignalBuilder(builder: (context) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    final mode = controller.viewMode.value;
    final today = controller.selectedDate.value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: SegmentedButton<PlanViewMode>(
            segments: [
              ButtonSegment(
                value: PlanViewMode.week,
                label: Text(l10n.weekPlanViewWeek),
              ),
              ButtonSegment(
                value: PlanViewMode.month,
                label: Text(l10n.weekPlanViewMonth),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => _onModeChanged(selection.first),
          ),
        ),
        if (mode == PlanViewMode.month)
          _buildMonthSwitcher(context, controller, l10n)
        else
          _buildWeekSwitcher(context, controller, l10n),
        Expanded(
          child: mode == PlanViewMode.month
              ? _buildMonthContent(context, controller, l10n, today)
              : _buildWeekContent(context, controller, l10n, today),
        ),
      ],
    );
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
      return const Center(child: CircularProgressIndicator());
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
          onDayTap: (date) => _onDayTap(context, controller, date, l10n),
        );
      },
    );
  }

  Widget _buildMonthSwitcher(
    BuildContext context,
    WeekPlanController controller,
    AppLocalizations l10n,
  ) {
    return MonthSwitcher(
      label: monthTitle(controller.monthStart.value),
      onPrevious: controller.canGoPrevMonth
          ? () => controller.shiftMonth(-1)
          : null,
      onNext: controller.canGoNextMonth ? () => controller.shiftMonth(1) : null,
    );
  }

  Widget _buildMonthContent(
    BuildContext context,
    WeekPlanController controller,
    AppLocalizations l10n,
    DateTime today,
  ) {
    final items = controller.items.value;
    if (controller.isLoading.value && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return MonthGridView(
      monthStart: controller.monthStart.value,
      today: today,
      onPrevious: controller.canGoPrevMonth
          ? () => controller.shiftMonth(-1)
          : null,
      onNext: controller.canGoNextMonth ? () => controller.shiftMonth(1) : null,
      cellBuilder: (context, date) => _buildMonthCell(
        context,
        controller.monthStart.value,
        items,
        today,
        date,
        l10n,
      ),
    );
  }

  Widget _buildMonthCell(
    BuildContext context,
    DateTime monthStart,
    List<WeekPlanItem> items,
    DateTime today,
    DateTime date,
    AppLocalizations l10n,
  ) {
    if (date.month != monthStart.month || date.year != monthStart.year) {
      return const SizedBox(height: 52);
    }
    final dayItems = _itemsForDay(items, date);
    final isToday = _sameDay(date, today);
    final theme = Theme.of(context);
    final (background, foreground, border) = _monthCellStyle(
      dayItems,
      date,
      theme.colorScheme,
    );
    final tooltip = dayItems.map((e) => e.programName).join(', ');
    return MonthDayCell(
      day: date.day,
      background: background,
      foreground: foreground,
      border: isToday ? Border.all(color: theme.colorScheme.primary) : border,
      tooltip: tooltip,
      isToday: isToday,
      showWorkoutIcon: dayItems.isNotEmpty,
      onTap: () => _showDayActions(context, _controller, date, l10n),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.weekPlanPastDateGuard)));
        return Future.value();
      }
      return _showScheduleSheet(context, controller, date, l10n);
    }
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat('d MMMM yyyy', 'ru').format(date),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in dayItems)
              _MonthDayActionTile(
                item: item,
                isToday: _sameDay(date, controller.selectedDate.value),
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
                onCancel: () {
                  Navigator.of(sheetContext).pop();
                  controller.cancelSchedule(item.programDayId, date);
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
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _ScheduleSheet(date: date, controller: controller),
    );
  }
}

class _WeekSwitcher extends StatelessWidget {
  const _WeekSwitcher({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
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
          IconButton(
            onPressed: onPrev,
            tooltip: l10n.weekPlanPrevWeek,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Text(label, style: theme.textTheme.titleMedium),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: l10n.weekPlanNextWeek,
            icon: const Icon(Icons.chevron_right),
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
    this.onDayTap,
  });

  final List<DateTime> days;
  final List<WeekPlanItem> items;
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

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
                onStart: onStart,
                onSkip: onSkip,
                onUnskip: onUnskip,
                onCancel: onCancel,
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
    this.onDayTap,
  });

  final List<DateTime> days;
  final List<WeekPlanItem> items;
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

  /// Тап по дню — открыть планирование или действия дня.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
            onStart: onStart,
            onSkip: onSkip,
            onUnskip: onUnskip,
            onCancel: onCancel,
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
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onCancel,
    this.onDayTap,
  });

  final DateTime date;
  final List<WeekPlanItem> items;
  final bool isToday;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

  /// Тап по дню — открыть планирование или действия дня.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final header = _DayHeader(date: date, isToday: isToday);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) ...[
          header,
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlannedWorkoutCard(
                item: items[index],
                isToday: isToday,
                onStart: onStart,
                onSkip: onSkip,
                onUnskip: onUnskip,
                onCancel: onCancel,
              ),
            ),
          ),
        ] else
          GestureDetector(
            onTap: onDayTap == null ? null : () => onDayTap!(date),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: header,
            ),
          ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.items,
    required this.isToday,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    required this.onCancel,
    this.onDayTap,
  });

  final DateTime date;
  final List<WeekPlanItem> items;
  final bool isToday;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction onCancel;

  /// Тап по дню — открыть планирование или действия дня.
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onDayTap == null ? null : () => onDayTap!(date),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(date: date, isToday: isToday),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PlannedWorkoutCard(
                      item: item,
                      isToday: isToday,
                      onStart: onStart,
                      onSkip: onSkip,
                      onUnskip: onUnskip,
                      onCancel: onCancel,
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
  const _DayHeader({required this.date, required this.isToday});

  final DateTime date;
  final bool isToday;

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
            Text(
              _weekdayLabel(l10n, date.weekday),
              style: theme.textTheme.labelLarge?.copyWith(
                color: isToday ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.weekPlanToday,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          '${date.day}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    if (!isToday) {
      return header;
    }
    // Текущий день выделяем цветным блоком для наглядности.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: header,
    );
  }
}

class _PlannedWorkoutCard extends StatelessWidget {
  const _PlannedWorkoutCard({
    required this.item,
    required this.isToday,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    this.onCancel,
  });

  final WeekPlanItem item;
  final bool isToday;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;
  final _WorkoutAction? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = item.status;

    // Крестик отмены показываем только для ручных назначений (dayOfWeek == null)
    // в статусе ожидания — постоянные программы привязаны к дню недели.
    final showCancel =
        status == WeekPlanStatus.pending &&
        item.dayOfWeek == null &&
        onCancel != null;

    return Card(
      margin: EdgeInsets.zero,
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
                      Text(
                        item.programName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
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
                  IconButton(
                    onPressed: () => onCancel!(item),
                    tooltip: l10n.weekPlanRemove,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
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
            if (status == WeekPlanStatus.pending) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => onStart(item),
                    icon: Icon(
                      isToday ? Icons.play_arrow : Icons.event_repeat_outlined,
                    ),
                    label: Text(
                      isToday ? l10n.weekPlanStart : l10n.weekPlanReschedule,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSkip(item),
                    child: Text(l10n.weekPlanSkip),
                  ),
                ],
              ),
            ],
            if (status == WeekPlanStatus.skipped)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onUnskip(item),
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text(l10n.weekPlanUnskip),
                ),
              ),
          ],
        ),
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
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.weekPlanEmpty,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.weekPlanHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    if (onSchedule == null) {
      return Center(child: content);
    }
    return Center(
      child: InkWell(
        onTap: onSchedule,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

(Color, Color, BoxBorder?) _monthCellStyle(
  List<WeekPlanItem> dayItems,
  DateTime date,
  ColorScheme colorScheme,
) {
  if (dayItems.isEmpty) {
    return (
      colorScheme.surfaceContainerLow,
      colorScheme.onSurfaceVariant,
      null,
    );
  }
  final anyPerformed = dayItems.any(
    (e) => e.status == WeekPlanStatus.performed,
  );
  final anySkipped = dayItems.any((e) => e.status == WeekPlanStatus.skipped);
  if (anyPerformed) {
    return (colorScheme.primaryContainer, colorScheme.onPrimaryContainer, null);
  }
  if (_isPast(date) || anySkipped) {
    // Прошедший день без выполнения или пропуск — нейтральная отмена
    // (НЕ error; красный зарезервирован под ошибки, см. DESIGN.md).
    return (
      colorScheme.surfaceContainerHighest,
      colorScheme.onSurfaceVariant,
      Border.all(color: colorScheme.outline, width: 1),
    );
  }
  return (
    colorScheme.secondaryContainer,
    colorScheme.onSecondaryContainer,
    null,
  );
}

bool _isPast(DateTime date) {
  final now = _dateOnly(DateTime.now());
  return date.isBefore(now);
}

class _MonthDayActionTile extends StatelessWidget {
  const _MonthDayActionTile({
    required this.item,
    required this.isToday,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
    this.onCancel,
  });

  final WeekPlanItem item;
  final bool isToday;
  final VoidCallback onStart;
  final VoidCallback onSkip;
  final VoidCallback onUnskip;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = item.status;
    final title = Text(
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
          ListTile(
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
                  FilledButton.tonalIcon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      isToday ? l10n.weekPlanStart : l10n.weekPlanReschedule,
                    ),
                  ),
                  TextButton(onPressed: onSkip, child: Text(l10n.weekPlanSkip)),
                  if (onCancel != null) ...[
                    IconButton(
                      onPressed: onCancel,
                      tooltip: l10n.weekPlanRemove,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ],
              ),
              WeekPlanStatus.skipped => TextButton.icon(
                onPressed: onUnskip,
                icon: const Icon(Icons.undo, size: 18),
                label: Text(l10n.weekPlanUnskip),
              ),
              WeekPlanStatus.performed ||
              WeekPlanStatus.rescheduled ||
              WeekPlanStatus.pastSkipped => StatusBadge(status: status),
            },
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

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

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

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    final programs = await widget.controller.programRepository.getPrograms();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    // Auto-select if only one program.
    if (programs.length == 1) {
      await _selectProgram(programs.first);
    }
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

  void _schedule(int programDayId) {
    widget.controller.scheduleDay(programDayId, widget.date);
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
            Text(
              l10n.weekPlanScheduleTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMMM yyyy', 'ru').format(widget.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
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
    return FutureBuilder<List<ProgramSummary>>(
      future: widget.controller.programRepository.getPrograms(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final programs = snapshot.data!;
        if (programs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.weekPlanScheduleNoPrograms)),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.weekPlanScheduleSelectProgram,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            for (final summary in programs)
              ListTile(
                title: Text(summary.program.name),
                subtitle: Text('${summary.exercisesCount} упражнений'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectProgram(summary),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDayList(AppLocalizations l10n, ThemeData theme) {
    final detail = _programDetail;
    if (detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _selectedProgram = null;
                _programDetail = null;
              }),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
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
          ListTile(
            title: Text(
              day.day.title ?? l10n.programBuilderDay(day.day.dayIndex + 1),
            ),
            subtitle: Text(
              day.day.dayOfWeek != null
                  ? _weekdayLabel(l10n, day.day.dayOfWeek!)
                  : 'Без привязки',
            ),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => _schedule(day.day.id!),
          ),
      ],
    );
  }
}
