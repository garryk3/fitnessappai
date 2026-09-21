// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/notifications/reminder_service.dart';

/// Контроллер секции «Уведомления» в настройках.
///
/// Проверяет и запрашивает разрешения на уведомления и точные будильники.
class NotificationSettingsController extends ChangeNotifier {
  NotificationSettingsController({required ReminderService reminderService})
    : _reminderService = reminderService;

  final ReminderService _reminderService;

  final Signal<bool> isLoading = Signal(false);
  final Signal<NotificationPermissionStatus?> status =
      Signal<NotificationPermissionStatus?>(null);
  final Signal<String?> error = Signal<String?>(null);

  /// Загружает текущий статус разрешений.
  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      status.value = await _reminderService.checkPermissions();
    } catch (e) {
      error.value = 'Не удалось проверить разрешения';
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
