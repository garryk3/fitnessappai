// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_text.dart';

/// Текстовая кнопка UI-кита.
///
/// Материальный [TextButton] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppTextButton] (иначе падает правило
/// `ban_text_button_widget`).
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.autofocus = false,
    this.tooltip,
  });

  /// Подпись кнопки; при [busy] заменяется спиннером.
  final String label;

  /// `null` — кнопка неактивна.
  final VoidCallback? onPressed;

  /// Необязательная иконка перед подписью.
  final IconData? icon;

  /// `true` — спиннер вместо подписи, кнопка неактивна.
  final bool busy;

  final bool autofocus;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final effective = enabled ? onPressed : null;
    final Widget labelWidget = busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : AppText(label);

    final Widget button = (icon == null || busy)
        ? TextButton(
            onPressed: effective,
            autofocus: autofocus,
            child: labelWidget,
          )
        : TextButton.icon(
            onPressed: effective,
            autofocus: autofocus,
            icon: AppIcon(icon!),
            label: labelWidget,
          );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
