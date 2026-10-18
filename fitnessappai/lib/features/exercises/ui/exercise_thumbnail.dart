import 'package:flutter/material.dart';

import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

/// Миниатюра упражнения: заглушка с иконкой, если нет изображения/анимации.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({
    super.key,
    this.exercise,
    this.mediaCache,
    this.size = 32,
  });

  final Exercise? exercise;
  final MediaCache? mediaCache;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = this.exercise;
    final mediaCache = this.mediaCache;
    final provider = (exercise == null || mediaCache == null)
        ? null
        : mediaCache.imageFor(
            exercise.thumbnailPath ?? exercise.animationPath,
            blob: exercise.thumbnailBlob ?? exercise.animationBlob,
            cacheWidth: (size * 2).round(),
          );
    if (provider == null) {
      return _placeholder(theme);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: AppImage(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return AppContainer(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: AppIcon(
        // Иконка по типу упражнения (54.6) — та же логика, что в заглушке
        // run-экрана; без упражнения — силовая по умолчанию.
        _placeholderIcon(exercise?.type),
        size: size * 0.56,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  static IconData _placeholderIcon(ExerciseType? type) => switch (type) {
    ExerciseType.bodyweight => Icons.accessibility_new,
    ExerciseType.plank => Icons.self_improvement,
    ExerciseType.distance => Icons.directions_run,
    _ => Icons.fitness_center,
  };
}
