/// Общие детали формы параметров упражнения (55.4): шапка-карточка с
/// миниатюрой и поле-степпер в карточке.
///
/// Используются экранами одиночных параметров (`/exercises/:id/params`)
/// и параметров позиции дня программы — единый паттерн образца
/// «Параметры упражнения» (54.4/55.1), без дублирования в двух фичах.
library;

import 'package:flutter/material.dart';

import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_thumbnail.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Шапка-карточка формы: миниатюра 64 + название упражнения
/// (`titleLarge` w600, максимум 2 строки с ellipsis).
class ExerciseParamsHeaderCard extends StatelessWidget {
  const ExerciseParamsHeaderCard({
    super.key,
    required this.exercise,
    this.mediaCache,
  });

  /// Упражнение; у позиции дня программы может отсутствовать — тогда
  /// рендерится пустое имя и заглушка миниатюры.
  final Exercise? exercise;
  final MediaCache? mediaCache;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ExerciseThumbnail(
            exercise: exercise,
            mediaCache: mediaCache,
            size: 64,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppText(
              exercise?.name ?? '',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Поле-степпер в карточке формы параметров: иконочный бейдж, крупное
/// полужирное значение (`titleLarge` w600), тултипы «+ / −» (l10n).
class ExerciseParamsStepperField extends StatelessWidget {
  const ExerciseParamsStepperField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    required this.icon,
    this.step = 1,
    this.decimals = false,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final IconData icon;
  final double step;
  final bool decimals;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: AppNumberStepper(
          controller: controller,
          label: label,
          validator: validator,
          icon: icon,
          step: step,
          decimals: decimals,
          helperText: helperText,
          // Крупное полужирное значение — как в образце «Параметры упражнения».
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          increaseTooltip: l10n.commonIncrease,
          decreaseTooltip: l10n.commonDecrease,
        ),
      ),
    );
  }
}
