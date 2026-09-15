import 'package:flutter/material.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_cache.dart';

/// Миниатюра изображения программы: заглушка с иконкой, если изображения нет.
class ProgramThumbnail extends StatelessWidget {
  const ProgramThumbnail({super.key, this.imagePath, this.size = 56});

  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = locator.get<MediaCache>().imageFor(
      imagePath,
      cacheWidth: (size * 2).round(),
    );
    if (provider == null) {
      return _placeholder(theme);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fitness_center,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
