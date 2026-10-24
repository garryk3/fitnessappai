// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Меню-иконка UI-кита (обёртка [PopupMenuButton]).
///
/// Материальный [PopupMenuButton] разрешён только внутри `lib/uikit/`;
/// в UI приложения используйте [AppPopupMenuButton] и пункты [AppPopupMenuItem].
class AppPopupMenuButton<T> extends StatelessWidget {
  const AppPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.initialValue,
    this.tooltip,
    this.enabled = true,
    this.padding = const EdgeInsets.all(8),
  });

  /// Построение пунктов меню; используйте [AppPopupMenuItem].
  final List<AppPopupMenuItem<T>> Function(BuildContext context) itemBuilder;

  /// Вызывается при выборе пункта со значением `value`.
  final ValueChanged<T?>? onSelected;

  /// Изначально подсвеченный пункт.
  final T? initialValue;

  /// Семантическая подсказка иконки; `null` — без подсказки.
  final String? tooltip;

  /// Доступность пунктов меню (M3-дефолт `true`).
  final bool enabled;

  /// Отступы; M3-дефолт — 8 со всех сторон (иконка без визуала).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      initialValue: initialValue,
      tooltip: tooltip,
      enabled: enabled,
      padding: padding,
      itemBuilder: (context) => itemBuilder(context)
          .map((item) => PopupMenuItem<T>(value: item.value, child: item.child))
          .toList(),
    );
  }
}

/// Пункт меню UI-кита (пасс-тру [PopupMenuItem]).
class AppPopupMenuItem<T> {
  const AppPopupMenuItem({this.value, required this.child});

  /// Значение, передаваемое в [AppPopupMenuButton.onSelected].
  final T? value;

  /// Содержимое пункта.
  final Widget child;
}
