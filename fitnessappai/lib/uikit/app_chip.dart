// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Чип UI-кита (обёртка [Chip]).
///
/// Материальный [Chip] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppChip]. Чипы проекта — статические бейджи
/// (токен-фон/стили передаются с сайта), интерактивные Input/Choice
/// варианты не используются.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.avatar,
    this.labelStyle,
    this.backgroundColor,
    this.visualDensity,
    this.side,
    this.shape,
    this.materialTapTargetSize,
  });

  /// Подпись — обычно [AppText] (иногда со своим стилем).
  final Widget label;

  /// Виджет перед подписью (иконка, иконка мышцы).
  final Widget? avatar;

  /// Стиль подписи (перекрывает M3-дефолты чипа).
  final TextStyle? labelStyle;

  /// Фон чипа (токен-роли: `surfaceContainerHigh`,
  /// `secondaryContainer`, `primaryContainer` с тинтом).
  final Color? backgroundColor;

  final VisualDensity? visualDensity;

  /// Граница; `BorderSide.none` — без границы.
  final BorderSide? side;

  /// Форма (54.7: `StadiumBorder()` — пилюля мышц).
  final OutlinedBorder? shape;

  final MaterialTapTargetSize? materialTapTargetSize;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: label,
      avatar: avatar,
      labelStyle: labelStyle,
      backgroundColor: backgroundColor,
      visualDensity: visualDensity,
      side: side,
      shape: shape,
      materialTapTargetSize: materialTapTargetSize,
    );
  }
}
