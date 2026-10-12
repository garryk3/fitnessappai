// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_icon.dart';

/// Изображение UI-кита — единственная точка рендера картинок в приложении.
///
/// Материальный [Image] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppImage] (иначе падает правило `ban_image_widget`).
///
/// Если [errorBuilder] не задан, при ошибке показывается нейтральная иконка
/// «битое изображение» — так в UI не остаётся пустого места.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.errorBuilder,
    this.frameBuilder,
    this.loadingBuilder,
    this.cacheWidth,
    this.cacheHeight,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
  });

  /// Источник изображения (asset/network/file/memory provider).
  final ImageProvider image;

  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageFrameBuilder? frameBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Image(
      image: cacheWidth == null && cacheHeight == null
          ? image
          : ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, image),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment ?? Alignment.center,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder:
          errorBuilder ??
          (context, error, stackTrace) => AppIcon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );
  }
}
