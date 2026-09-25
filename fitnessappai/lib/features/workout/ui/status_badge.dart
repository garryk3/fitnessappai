import 'package:flutter/material.dart';

import 'package:fitnessappai/app/theme/status_colors.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Бейдж статуса тренировки: «Запланировано», «Выполнено», «Пропущено» и т.д.
///
/// Используется на экране плана и на главном экране.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final WeekPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color, foreground, border) = switch (status) {
      WeekPlanStatus.pending => (
        l10n.schedulePending,
        colorScheme.statusPendingContainer,
        colorScheme.statusPendingOnContainer,
        null,
      ),
      WeekPlanStatus.performed => (
        l10n.schedulePerformed,
        colorScheme.statusPerformedContainer,
        colorScheme.statusPerformedOnContainer,
        null,
      ),
      WeekPlanStatus.rescheduled => (
        l10n.scheduleRescheduled,
        colorScheme.statusRescheduledContainer,
        colorScheme.statusRescheduledOnContainer,
        null,
      ),
      WeekPlanStatus.skipped || WeekPlanStatus.pastSkipped => (
        l10n.scheduleSkipped,
        colorScheme.statusSkippedContainer,
        colorScheme.statusSkippedOnContainer,
        Border.all(color: colorScheme.statusSkippedOutline, width: 1.2),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == WeekPlanStatus.skipped ||
              status == WeekPlanStatus.pastSkipped) ...[
            Icon(Icons.remove, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
