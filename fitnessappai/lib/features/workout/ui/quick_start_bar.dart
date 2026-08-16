import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Запускает подготовку к тренировке [item]: при удалённом дне показывает
/// SnackBar и обновляет план, иначе открывает экран подготовки.
Future<void> startPlannedWorkout(
  BuildContext context,
  WeekPlanController controller,
  WeekPlanItem item,
) async {
  final exists = await controller.dayExists(item.programDayId);
  if (!context.mounted) {
    return;
  }
  if (!exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).workoutPrepareNotFound),
      ),
    );
    await controller.refresh();
    return;
  }
  context.push('/workout/prepare/${item.programDayId}');
}
