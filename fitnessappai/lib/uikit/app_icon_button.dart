// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Кнопка-иконка UI-кита (обёртка [IconButton]).
///
/// Материальный [IconButton] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppIconButton] (иначе падает правило
/// `ban_icon_button_widget`). Тап-таргет и отступы — M3-дефолты
/// (≥48dp, доступность); иконку передавайте [AppIcon].
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.visualDensity,
  });

  /// Иконка (обычно `AppIcon(...)`, с размером по месту).
  final Widget icon;

  /// `null` — кнопка неактивна.
  final VoidCallback? onPressed;

  /// Подсказка (long-press/screen reader).
  final String? tooltip;

  /// Переопределение цвета иконки (иначе — из окружения/темы).
  final Color? color;

  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: icon,
      color: color,
      visualDensity: visualDensity,
    );
  }
}
