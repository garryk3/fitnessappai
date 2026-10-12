// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Иконка UI-кита — единственная точка рендера иконок в приложении.
///
/// Материальный [Icon] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppIcon] (иначе падает правило `ban_icon_widget`).
///
/// Если [size]/[color] не заданы, значения берутся из окружного `IconTheme`
/// (как у голого [Icon]).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  /// Глиф иконки.
  final IconData icon;

  /// Размер; при `null` — из `IconTheme`.
  final double? size;

  /// Цвет; при `null` — из `IconTheme`.
  final Color? color;

  /// Подпись для скринридера.
  final String? semanticLabel;

  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
