// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Иконка UI-кита — единственная точка рендера иконок в приложении.
///
/// Материальный [Icon] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppIcon] (иначе падает правило `ban_icon_widget`).
///
/// Полный пасстхру сигнатуры [Icon]: незаданные параметры берутся из
/// окружного `IconTheme` (как у голого [Icon]). [icon] может быть `null` —
/// так же, как у [Icon], и тогда рендерится пустое место размера [size].
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
    this.blendMode,
    this.fontWeight,
  }) : assert(fill == null || (0.0 <= fill && fill <= 1.0)),
       assert(weight == null || (0.0 < weight)),
       assert(opticalSize == null || (0.0 < opticalSize));

  /// Глиф иконки; `null` — пустое место (как у [Icon]).
  final IconData? icon;

  /// Размер; при `null` — из `IconTheme`.
  final double? size;

  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;

  /// Цвет; при `null` — из `IconTheme`.
  final Color? color;

  final List<Shadow>? shadows;

  /// Подпись для скринридера.
  final String? semanticLabel;

  final TextDirection? textDirection;
  final bool? applyTextScaling;
  final BlendMode? blendMode;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      fill: fill,
      weight: weight,
      grade: grade,
      opticalSize: opticalSize,
      color: color,
      shadows: shadows,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      applyTextScaling: applyTextScaling,
      blendMode: blendMode,
      fontWeight: fontWeight,
    );
  }
}
