import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран «План недели»: сетка Пн–Вс с тренировочными днями и статусами.
class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({
    super.key,
    this.programRepository,
    this.workoutRepository,
    this.clock,
  });

  final ProgramRepository? programRepository;
  final WorkoutRepository? workoutRepository;

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
      clock: widget.clock,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _skip(WeekPlanItem item) => _controller.markSkipped(item);

  Future<void> _unskip(WeekPlanItem item) => _controller.clearSkip(item);

  Future<void> _start(WeekPlanItem item) async {
    final exists = await _controller.dayExists(item.programDayId);
    if (!mounted) {
      return;
    }
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).workoutPrepareNotFound),
        ),
      );
      await _controller.refresh();
      return;
    }
    context.push('/workout/prepare/${item.programDayId}');
  }

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
    final weekStart = controller.weekStart.value;
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final rangeLabel = _weekRangeLabel(days.first, days.last, l10n);

    return Column(
      children: [
        _WeekSwitcher(
          label: rangeLabel,
          onPrev: () => controller.shiftWeek(-1),
          onNext: () => controller.shiftWeek(1),
        ),
        if (controller.nextPending case final next?)
          _QuickStartBar(item: next, onStart: _start),
        Expanded(child: _buildContent(context, days)),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<DateTime> days) {
    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    final items = controller.items.value;
    if (controller.isLoading.value && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return _WeekEmpty(l10n: l10n);
    }
    final today = controller.selectedDate.value;
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

typedef _WorkoutAction = void Function(WeekPlanItem item);

/// Кнопка быстрого старта ближайшей запланированной тренировки.
class _QuickStartBar extends StatelessWidget {
  const _QuickStartBar({required this.item, required this.onStart});

  final WeekPlanItem item;
  final _WorkoutAction onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: FilledButton.icon(
        onPressed: () => onStart(item),
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.weekPlanQuickStart),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

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
                _StatusBadge(status: status),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final WeekPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      WeekPlanStatus.pending => (
        l10n.schedulePending,
        colorScheme.surfaceContainerHighest,
      ),
      WeekPlanStatus.performed => (l10n.schedulePerformed, colorScheme.primary),
      WeekPlanStatus.rescheduled => (
        l10n.scheduleRescheduled,
        colorScheme.tertiary,
      ),
      WeekPlanStatus.skipped => (l10n.scheduleSkipped, colorScheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
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
