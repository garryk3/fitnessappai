import 'package:flutter/material.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Область, предоставляющая пунктам навигации доступ к кнопке вызыва меню.
///
/// Оболочка навигации ([AdaptiveNavigation]) регистрирует свой callback —
/// на узких экранах открытие drawer-а, на широких — переключение rail-а
/// между сжатым и расширенным состоянием. Экраны-ветки читают его через
/// [MenuOpener.maybeOf], поэтому кнопка видна только внутри оболочки.
class MenuOpener extends InheritedWidget {
  const MenuOpener({super.key, required this.onOpenMenu, required super.child});

  final VoidCallback onOpenMenu;

  static MenuOpener? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MenuOpener>();

  @override
  bool updateShouldNotify(MenuOpener oldWidget) =>
      onOpenMenu != oldWidget.onOpenMenu;
}

/// Кнопка вызова меню в левом верхнем углу экрана (leading AppBar).
///
/// Показывает иконку только когда рядом есть [MenuOpener] (экран внутри
/// навигационной оболочки). Вне оболочки (например, в изолированных
/// виджет-тестах) отрисовывает пустое место, не ломая разметку AppBar.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    // На expanded-экранах toggle-иконка живёт в `leading` rail-а (левый верхний
    // угол экрана), здесь она не нужна — иначе иконка дублировалась бы.
    if (AppBreakpoints.isExpanded(MediaQuery.sizeOf(context).width)) {
      return const SizedBox.shrink();
    }
    final opener = MenuOpener.maybeOf(context);
    if (opener == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: l10n.navMenu,
      onPressed: opener.onOpenMenu,
    );
  }
}
