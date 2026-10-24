// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Спиннер загрузки UI-кита (обёртка [CircularProgressIndicator]).
///
/// Материальный [CircularProgressIndicator] разрешён только внутри
/// `lib/uikit/`; в UI приложения используйте [AppSpinner]. Цвет и
/// `strokeWidth` — M3-дефолты (цвет из `ThemeData.colorScheme.primary`).
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.strokeWidth});

  /// Толщина дуги; `null` — M3-дефолт (4).
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(strokeWidth: strokeWidth);
  }
}
