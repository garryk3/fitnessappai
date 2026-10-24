// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Линейный прогресс UI-кита (обёртка [LinearProgressIndicator]).
///
/// Материальный [LinearProgressIndicator] разрешён только внутри
/// `lib/uikit/`; в UI приложения используйте [AppLinearProgress].
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({super.key, this.value, this.minHeight});

  /// `null` — неопределённый (бегущая полоса).
  final double? value;

  /// Высота полосы; `null` — M3-дефолт (4).
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(value: value, minHeight: minHeight);
  }
}
