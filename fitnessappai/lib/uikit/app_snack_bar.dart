// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_text.dart';

/// Показ снекбара UI-кита (обёртка [ScaffoldMessengerState.showSnackBar]).
///
/// Материальный [SnackBar] разрешён только внутри `lib/uikit/`; внешний вид
/// задается темой (`snackBarTheme`, этап 55.2): floating, фон
/// `surfaceContainerHighest`, радиус `AppRadii.lg`.
///
/// После `await` (async-gap) передавайте [ScaffoldMessengerState],
/// захваченный до приостановки: `showAppSnackBar(messenger, ...)`;
/// синхронный вызов — `showAppSnackBar(ScaffoldMessenger.of(context), ...)`.
void showAppSnackBar(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(SnackBar(content: AppText(message)));
}
