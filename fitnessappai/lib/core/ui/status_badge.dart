import 'package:flutter/material.dart';

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
    final (label, color, foreground) = switch (status) {
      WeekPlanStatus.pending => (
        l10n.schedulePending,
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      WeekPlanStatus.performed => (
        l10n.schedulePerformed,
        colorScheme.primary,
        colorScheme.onPrimary,
      ),
      WeekPlanStatus.rescheduled => (
        l10n.scheduleRescheduled,
        colorScheme.tertiary,
        colorScheme.onTertiary,
      ),
      WeekPlanStatus.skipped => (
        l10n.scheduleSkipped,
        colorScheme.error,
        colorScheme.onError,
      ),
      WeekPlanStatus.pastSkipped => (
        l10n.scheduleSkipped,
        colorScheme.error,
        colorScheme.onError,
      ),
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
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
