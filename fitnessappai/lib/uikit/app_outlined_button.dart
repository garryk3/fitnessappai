// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_text.dart';

/// Контурная кнопка UI-кита.
///
/// Материальный [OutlinedButton] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppOutlinedButton] (иначе падает правило
/// `ban_outlined_button_widget`).
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconSize,
    this.busy = false,
    this.expanded = false,
    this.autofocus = false,
    this.tooltip,
  });

  /// Подпись кнопки; при [busy] заменяется спиннером.
  final String label;

  /// `null` — кнопка неактивна.
  final VoidCallback? onPressed;

  /// Необязательная иконка перед подписью.
  final IconData? icon;

  /// Размер иконки; `null` — из окружного `IconTheme`.
  final double? iconSize;

  /// `true` — спиннер вместо подписи, кнопка неактивна.
  final bool busy;

  /// `true` — кнопка растягивается на всю ширину.
  final bool expanded;

  final bool autofocus;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final effective = enabled ? onPressed : null;
    final Widget labelWidget = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : AppText(label);

    final Widget button = (icon == null || busy)
        ? OutlinedButton(
            onPressed: effective,
            autofocus: autofocus,
            child: labelWidget,
          )
        : OutlinedButton.icon(
            onPressed: effective,
            autofocus: autofocus,
            icon: AppIcon(icon!, size: iconSize),
            label: labelWidget,
          );

    final Widget wrapped = expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return tooltip == null
        ? wrapped
        : Tooltip(message: tooltip!, child: wrapped);
  }
}
