import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Пишет диагностику напоминаний в лог, доступный и в release-сборке.
///
/// [developer.log] из `dart:developer` вырезается из AOT-кода, поэтому в
/// release он не оставляет следов: ошибка планирования уведомлений выглядит
/// как «ничего не произошло». [debugPrint] доходит до logcat и в release, зато
/// медленный и не структурированный, поэтому оба канала дополняют друг друга.
///
/// Вызывать только для диагностики: сбой планирования уведомлений не должен
/// прерывать работу приложения.
void logNotificationIssue(
  String message, {
  Object? error,
  StackTrace? stackTrace,
  String name = 'ReminderService',
}) {
  developer.log(message, error: error, stackTrace: stackTrace, name: name);
  debugPrint(error == null ? '[$name] $message' : '[$name] $message: $error');
}
