// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/notifications/battery_optimization.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Вид ошибки секции «Уведомления» (без текста).
///
/// Текст локализуется на стороне экрана (`notificationErrorMessage`),
/// контроллер не хранит русские строки мимо `app_ru.arb`.
enum NotificationErrorKind {
  /// Не удалось проверить текущий статус разрешений.
  checkFailed,

  /// Не удалось запросить разрешение (уведомления / точные будильники).
  requestFailed,

  /// Не удалось запросить исключение из оптимизации батареи.
  batteryRequestFailed,
}

/// Контроллер секции «Уведомления» в настройках.
///
/// Проверяет и запрашивает разрешения на уведомления, точные будильники и
/// исключение из оптимизации батареи (задача 48.7).
class NotificationSettingsController extends ChangeNotifier {
  NotificationSettingsController({
    required ReminderService reminderService,
    BatteryOptimizationGateway? batteryOptimization,
  }) : _reminderService = reminderService,
       _batteryOptimization =
           batteryOptimization ?? const MethodChannelBatteryOptimization();

  final ReminderService _reminderService;

  /// Доступ к исключению из оптимизации батареи; по умолчанию — канал к
  /// нативной части (на не-Android плита прячется, см. [load]).
  final BatteryOptimizationGateway _batteryOptimization;

  final Signal<bool> isLoading = Signal(false);
  final Signal<NotificationPermissionStatus?> status =
      Signal<NotificationPermissionStatus?>(null);

  /// Последняя ошибка (структурированный вид): текст локализуется на стороне
  /// экрана (`notificationErrorMessage`), контроллер хранит только вид.
  final Signal<NotificationErrorKind?> error = Signal(null);

  /// Исключено ли приложение из оптимизации батареи: `null` — статус
  /// недоступен (не Android, канал не отвечает) и плитка не показывается.
  final Signal<bool?> batteryOptimizationExempt = Signal<bool?>(null);

  /// Загружает текущий статус разрешений.
  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      status.value = await _reminderService.checkPermissions();
    } catch (e) {
      error.value = NotificationErrorKind.checkFailed;
    }
    try {
      batteryOptimizationExempt.value = await _batteryOptimization.isIgnoring();
    } catch (e) {
      // Статуса нет (не Android, канал не ответил) — ошибка пользователю
      // не нужна, плитка просто не показывается (задача 48.7).
      batteryOptimizationExempt.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Запрашивает исключение из оптимизации батареи и обновляет статус.
  ///
  /// Системный диалог закрывается сам, метод возвращается с актуальным
  /// статусом — без отдельного перечитывания при возврате в приложение
  /// (задача 48.7).
  Future<void> requestBatteryOptimization() async {
    isLoading.value = true;
    error.value = null;
    try {
      batteryOptimizationExempt.value = await _batteryOptimization.request();
    } catch (e) {
      error.value = NotificationErrorKind.batteryRequestFailed;
    } finally {
      isLoading.value = false;
    }
  }

  /// Запрашивает разрешение на уведомления и обновляет статус.
  Future<void> requestNotifications() async {
    await _request(() => _reminderService.requestNotificationsPermission());
  }

  /// Запрашивает разрешение на точные будильники и обновляет статус.
  Future<void> requestExactAlarms() async {
    await _request(() => _reminderService.requestExactAlarmsPermission());
  }

  Future<void> _request(
    Future<NotificationPermissionStatus> Function() action,
  ) async {
    isLoading.value = true;
    error.value = null;
    try {
      status.value = await action();
    } catch (e) {
      error.value = NotificationErrorKind.requestFailed;
    } finally {
      isLoading.value = false;
    }
  }
}

/// Локализованное сообщение об ошибке секции «Уведомления».
///
/// Тексты — в `app_ru.arb` (`settingsNotificationsError*`); контроллер хранит
/// только вид ошибки.
String notificationErrorMessage(
  AppLocalizations l10n,
  NotificationErrorKind kind,
) => switch (kind) {
  NotificationErrorKind.checkFailed => l10n.settingsNotificationsErrorCheck,
  NotificationErrorKind.requestFailed => l10n.settingsNotificationsErrorRequest,
  NotificationErrorKind.batteryRequestFailed =>
    l10n.settingsNotificationsErrorBatteryRequest,
};
