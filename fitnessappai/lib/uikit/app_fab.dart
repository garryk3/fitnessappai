// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_icon.dart';

/// Floating action button UI-кита (обёртка [FloatingActionButton]).
///
/// Материальный [FloatingActionButton] разрешён только внутри
/// `lib/uikit/`; в UI приложения используйте [AppFab]. Основные CTA
/// экранов — [AppGradientButton] (54.x); FAB — только для системных
/// действий списков (создать программу/упражнение/замер, стоп-звук).
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.heroTag,
    this.mini = false,
  });

  /// Иконка.
  final IconData icon;

  /// `null` — кнопка неактивна.
  final VoidCallback? onPressed;

  /// Подсказка (long-press/screen reader).
  final String? tooltip;

  /// Уникальный тег hero-анимации между переходами (два FAB на стеке
  /// с одинаковым дефолт-тегом бросают исключение).
  final Object? heroTag;

  /// Компактный вариант (40dp, сегменты run-экрана).
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: mini,
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      child: AppIcon(icon),
    );
  }
}
