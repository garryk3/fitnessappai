// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Разделитель UI-кита (обёртка [Divider]).
///
/// Материальные [Divider]/[VerticalDivider] разрешены только внутри
/// `lib/uikit/`; в UI приложения используйте [AppDivider] / [AppVerticalDivider].
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height, this.thickness});

  /// Вертикальный отступ вокруг линии; `null` — M3-дефолт (16).
  final double? height;

  /// Толщина линии; `null` — из темы.
  final double? thickness;

  @override
  Widget build(BuildContext context) {
    return Divider(height: height, thickness: thickness);
  }
}

/// Вертикальный разделитель UI-кита (обёртка [VerticalDivider]).
class AppVerticalDivider extends StatelessWidget {
  const AppVerticalDivider({super.key, this.width, this.thickness});

  /// Горизонтальный отступ вокруг линии; `null` — M3-дефолт (16).
  final double? width;

  /// Толщина линии; `null` — из темы.
  final double? thickness;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(width: width, thickness: thickness);
  }
}
