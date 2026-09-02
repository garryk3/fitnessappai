import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navPlan)),
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
      onPrev: () => controller.shiftWeek(-1),
      onNext: () => controller.shiftWeek(1),
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
      return _WeekEmpty(l10n: l10n);
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
          );
        }
        return _WeekList(
          days: days,
          items: items,
          today: today,
          onStart: _start,
          onSkip: _skip,
          onUnskip: _unskip,
        );
      },
    );
  }

  Widget _buildMonthSwitcher(
    BuildContext context,
    WeekPlanController controller,
    AppLocalizations l10n,
  ) {
    return _MonthSwitcher(
      label: _monthLabel(controller.monthStart.value),
      onPrev: () => controller.shiftMonth(-1),
      onNext: () => controller.shiftMonth(1),
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
    return _MonthGrid(
      monthStart: controller.monthStart.value,
      items: items,
      today: today,
      onDayTap: (date, _) => _showDayActions(context, controller, date, l10n),
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
  final VoidCallback onPrev;
  final VoidCallback onNext;

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

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

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
            tooltip: l10n.weekPlanPrevMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Text(label, style: theme.textTheme.titleMedium),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: l10n.weekPlanNextMonth,
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
  });

  final List<DateTime> days;
  final List<WeekPlanItem> items;
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;

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
  });

  final List<DateTime> days;
  final List<WeekPlanItem> items;
  final DateTime today;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;

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
  });

  final DateTime date;
  final List<WeekPlanItem> items;
  final bool isToday;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayHeader(date: date, isToday: isToday),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const SizedBox(height: 24)
        else
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
              ),
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
  });

  final DateTime date;
  final List<WeekPlanItem> items;
  final bool isToday;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
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
                  ),
                ),
            ],
          ],
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
    return Column(
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
  }
}

class _PlannedWorkoutCard extends StatelessWidget {
  const _PlannedWorkoutCard({
    required this.item,
    required this.isToday,
    required this.onStart,
    required this.onSkip,
    required this.onUnskip,
  });

  final WeekPlanItem item;
  final bool isToday;
  final _WorkoutAction onStart;
  final _WorkoutAction onSkip;
  final _WorkoutAction onUnskip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = item.status;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.programName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: status),
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
  const _WeekEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
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
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.monthStart,
    required this.items,
    required this.today,
    required this.onDayTap,
  });

  final DateTime monthStart;
  final List<WeekPlanItem> items;
  final DateTime today;

  /// [date, items] — дата и привязанные тренировки при тапе по ячейке.
  final void Function(DateTime date, List<WeekPlanItem> items) onDayTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final firstDay = DateTime(monthStart.year, monthStart.month, 1);
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final cellCount = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final gridStart = firstDay.subtract(Duration(days: leadingBlanks));
    final theme = Theme.of(context);

    final dayNames = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        Row(
          children: [
            for (final name in dayNames)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < cellCount ~/ 7; row++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 7; col++) ...[
                Expanded(
                  child: _buildCell(
                    context,
                    gridStart.add(Duration(days: row * 7 + col)),
                  ),
                ),
                if (col < 6) const SizedBox(width: 6),
              ],
            ],
          ),
          if (row < cellCount ~/ 7 - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildCell(BuildContext context, DateTime date) {
    if (date.month != monthStart.month || date.year != monthStart.year) {
      return const SizedBox(height: 52);
    }
    final dayItems = _itemsForDay(items, date);
    final isToday = _sameDay(date, today);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (background, foreground, border) = _cellStyle(
      dayItems,
      date,
      colorScheme,
    );

    final tooltip = dayItems.map((e) => e.programName).join(', ');

    return Tooltip(
      message: dayItems.isEmpty ? '' : tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onDayTap(date, dayItems),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: isToday ? Border.all(color: colorScheme.primary) : border,
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isToday ? colorScheme.primary : foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (dayItems.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: foreground,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, BoxBorder?) _cellStyle(
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
      return (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
        null,
      );
    }
    if (_isPast(date)) {
      // Прошедший день без выполнения — «неуспешный» окрас.
      return (colorScheme.errorContainer, colorScheme.onErrorContainer, null);
    }
    if (anySkipped) {
      return (colorScheme.errorContainer, colorScheme.onErrorContainer, null);
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
    return ListTile(
      title: Text(
        item.programName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: switch (status) {
        WeekPlanStatus.pending => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonalIcon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                isToday ? l10n.weekPlanStart : l10n.weekPlanReschedule,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(onPressed: onSkip, child: Text(l10n.weekPlanSkip)),
            if (onCancel != null) ...[
              const SizedBox(width: 4),
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

String _monthLabel(DateTime month) {
  final formatted = DateFormat('LLLL yyyy', 'ru').format(month);
  return formatted[0].toUpperCase() + formatted.substring(1);
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
            title: Text('День ${day.day.dayIndex + 1}'),
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
