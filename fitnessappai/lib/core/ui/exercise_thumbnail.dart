import 'package:flutter/material.dart';

import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/media/media_cache.dart';

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
      borderRadius: BorderRadius.circular(8),
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.fitness_center,
        size: size * 0.56,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
