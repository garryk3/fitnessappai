// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/notifications/battery_optimization.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';

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
  final Signal<String?> error = Signal<String?>(null);

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
      error.value = 'Не удалось проверить разрешения';
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
      error.value = 'Не удалось запросить исключение из оптимизации батареи';
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
      error.value = 'Не удалось запросить разрешение';
    } finally {
      isLoading.value = false;
    }
  }
}
