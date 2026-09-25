import 'package:flutter/material.dart';

/// Миниатюра UI-кита: картинка по [image] с заглушкой, если изображения нет.
/// Нейтральный компонент — готовый [ImageProvider] задаёт вызывающий код.
class AppThumbnail extends StatelessWidget {
  const AppThumbnail({
    super.key,
    this.image,
    this.size,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.placeholderIcon = Icons.fitness_center,
  });

  final ImageProvider? image;
  final double? size;

  /// Альтернатива [size]: независимые ширина/высота.
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;

  double get _width => width ?? size ?? 56;
  double get _height => height ?? size ?? 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = this.image;
    final icon = Icon(
      placeholderIcon,
      size: _width * 0.56,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final placeholder = Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: borderRadius,
      ),
      child: icon,
    );
    if (image == null) {
      return placeholder;
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image(
        image: image,
        width: _width,
        height: _height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}
