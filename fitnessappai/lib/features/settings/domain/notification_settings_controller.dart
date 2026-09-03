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

  /// Запрашивает разрешения и обновляет статус.
  Future<void> requestPermissions() async {
    isLoading.value = true;
    error.value = null;
    try {
      status.value = await _reminderService.requestPermissions();
    } catch (e) {
      error.value = 'Не удалось запросить разрешения';
    } finally {
      isLoading.value = false;
    }
  }
}
