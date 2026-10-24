// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Подсказка UI-кита (обёртка [Tooltip]).
///
/// Материальный [Tooltip] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppTooltip]. На мобильных открывается по
/// long-press; сообщение читается screen reader'ом.
class AppTooltip extends StatelessWidget {
  const AppTooltip({super.key, required this.message, required this.child});

  /// Текст подсказки.
  final String message;

  /// Целевой виджет (иконка-кнопка, кастомный CTA, ячейка сетки).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Пустое сообщение — M3 не покажет тултип, но виджет-обёртка останется
    // в дереве; без смысла оборачиваем ребёнок напрямую (контракт month_grid).
    if (message.isEmpty) {
      return child;
    }
    return Tooltip(message: message, child: child);
  }
}
