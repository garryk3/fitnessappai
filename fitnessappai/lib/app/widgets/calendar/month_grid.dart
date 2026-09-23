import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';

/// Заголовок месяца с капитализацией, общий для плана и истории.
String monthTitle(DateTime month) {
  final formatted = DateFormat('LLLL yyyy', 'ru').format(month);
  return formatted[0].toUpperCase() + formatted.substring(1);
}

/// Переключатель месяца: стрелки + заголовок.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.label,
    required this.onPrevious,
    this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
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
            onPressed: onPrevious,
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

/// Сетка дня в месячном календаре (дизайн «Плана»): номер дня сверху-слева,
/// иконка тренировки снизу-справа.
class MonthDayCell extends StatelessWidget {
  const MonthDayCell({
    super.key,
    required this.day,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.border,
    this.tooltip,
    this.showWorkoutIcon = false,
    this.isToday = false,
    this.fillHeight = false,
  });

  final int day;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final String? tooltip;
  final bool showWorkoutIcon;

  /// Сегодня: номер дня подсвечивается primary (рамка — через [border]).
  final bool isToday;

  /// true — ячейка растягивается на высоту строки (режим заполнения),
  /// false — фиксированная высота 52 для прокручиваемой сетки.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cell = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: fillHeight ? double.infinity : 52,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$day',
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isToday ? theme.colorScheme.primary : foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (showWorkoutIcon)
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
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return cell;
    }
    return Tooltip(message: tooltip!, child: cell);
  }
}

/// Месячная сетка (пн–вс): общая раскладка хедеров, пустых ячеек, свайпа
/// и политики высоты для плана и истории.
class MonthGridView extends StatefulWidget {
  const MonthGridView({
    super.key,
    required this.monthStart,
    required this.today,
    required this.cellBuilder,
    this.fillHeight = false,
    this.onPrevious,
    this.onNext,
  });

  final DateTime monthStart;

  /// Эталонная «сегодня»-дата для рамки текущего дня.
  final DateTime today;

  /// Строит ячейку сетки; вызывается для каждого дня, включая дни
  /// соседних месяцев (пустые ячейки возвращает сам экран).
  final Widget Function(BuildContext context, DateTime date) cellBuilder;

  /// true — строки заполняют доступную высоту (Expanded, «История»);
  /// false — прокручиваемый список с фиксированной высотой ячеек.
  final bool fillHeight;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<MonthGridView> createState() => _MonthGridViewState();
}

class _MonthGridViewState extends State<MonthGridView> {
  static const double _swipeThreshold = 100;
  double _dragOffset = 0;

  void _onDragStart(DragStartDetails details) {
    _dragOffset = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragOffset += details.delta.dx;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset <= -_swipeThreshold && widget.onNext != null) {
      widget.onNext!();
    } else if (_dragOffset >= _swipeThreshold && widget.onPrevious != null) {
      widget.onPrevious!();
    }
    _dragOffset = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final month = widget.monthStart;
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final weekCount = ((leadingBlanks + daysInMonth) / 7).ceil();
    final gridStart = firstDay.subtract(Duration(days: leadingBlanks));

    final dayNames = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];

    final headerRow = Row(
      children: [
        for (final name in dayNames)
          Expanded(
            child: Center(child: Text(name, style: _headerStyle(context))),
          ),
      ],
    );

    final weekRows = <Widget>[
      for (var row = 0; row < weekCount; row++)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < 7; col++) ...[
              Expanded(
                child: widget.cellBuilder(
                  context,
                  gridStart.add(Duration(days: row * 7 + col)),
                ),
              ),
              if (col < 6) const SizedBox(width: 6),
            ],
          ],
        ),
    ];

    final grid = GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: widget.fillHeight
          ? Column(children: [for (final row in weekRows) Expanded(child: row)])
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                headerRow,
                const SizedBox(height: 8),
                for (var i = 0; i < weekRows.length; i++) ...[
                  weekRows[i],
                  if (i < weekRows.length - 1) const SizedBox(height: 6),
                ],
              ],
            ),
    );

    if (widget.fillHeight) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: headerRow,
          ),
          Expanded(child: grid),
        ],
      );
    }
    return grid;
  }

  TextStyle? _headerStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}
