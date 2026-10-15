// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/uikit/app_container.dart';

/// Контейнер с неоновой обводкой и свечением (редизайн 54, DESIGN.md §11).
///
/// Статичный glow: без анимаций, не более одного свечения на виджет —
/// сам контейнер рисует единственную тень. Свечение рисуется только в
/// тёмной теме; в светлой остаётся неон-обводка (`border`) — активность
/// элемента без перегрузки светлого фона. Роль — активный/выделенный
/// элемент (текущая тренировка, выбранная карточка); не использовать
/// для декоративной подсветки нескольких элементов сразу.
class AppGlowContainer extends StatelessWidget {
  const AppGlowContainer({
    super.key,
    required this.child,
    this.color,
    this.radius = AppRadii.lg,
    this.intensity = 1.0,
    this.borderWidth = 1.5,
    this.showBorder = true,
    this.padding,
    this.margin,
  });

  /// Содержимое контейнера.
  final Widget child;

  /// Цвет свечения/обводки; по умолчанию — `colorScheme.primary`.
  final Color? color;

  /// Скругление контейнера (токен `AppRadii`).
  final double radius;

  /// Интенсивность свечения: `AppGlow.alpha * intensity` (1.0 — базовая).
  final double intensity;

  /// Толщина неоновой обводки; 0 — обводка не рисуется.
  final double borderWidth;

  /// false — только свечение без неоновой обводки.
  final bool showBorder;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color glowColor = color ?? scheme.primary;
    final bool glow = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    return AppContainer(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: showBorder && borderWidth > 0
            ? Border.all(
                color: glowColor.withValues(alpha: AppGlow.borderAlpha),
                width: borderWidth,
              )
            : null,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: AppGlow.alpha * intensity),
                  blurRadius: AppGlow.radius,
                  spreadRadius: AppGlow.spread,
                ),
              ]
            : const [],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}
