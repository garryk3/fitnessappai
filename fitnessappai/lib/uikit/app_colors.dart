// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Цветовые токены UI-кита.
///
/// Правила `ban_colors`/`ban_color` запрещают сырые `Colors.*` и `Color(...)`
/// вне `lib/uikit/` (см. `DESIGN.md`: цвета берутся из `ColorScheme`). Сюда
/// выносятся только нейтральные константы, у которых нет роли в `ColorScheme`.
///
/// Для смысловых цветов используйте роли темы:
/// `Theme.of(context).colorScheme.primary` и т.п., а не константы отсюда.
abstract final class AppColors {
  /// Полностью прозрачный цвет (замена `Colors.transparent`).
  static const Color transparent = Color(0x00000000);

  /// Контент (иконка/текст) поверх градиента `AppGradients.primaryCta`.
  ///
  /// Всегда белый: `onPrimary` тёмной темы тёмный и на градиенте даёт
  /// ~2.2:1 (контрастный дефект дизайн-ревью 54.9), а у светлой темы
  /// `onPrimary` уже белый — одна константа ведёт себя одинаково в обеих
  /// темах (так же поступает `AppGradientButton`).
  static const Color primaryCtaContent = Colors.white;
}
