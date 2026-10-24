// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Pull-to-refresh UI-кита (обёртка [RefreshIndicator]).
///
/// Материальный [RefreshIndicator] разрешён только внутри `lib/uikit/`;
/// в UI приложения используйте [AppRefresh]. Спиннер — M3-дефолт
/// (цвет/размер от темы).
class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.onRefresh, required this.child});

  /// Асинхронное обновление данных.
  final Future<void> Function() onRefresh;

  /// Прокручиваемое содержимое.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}
