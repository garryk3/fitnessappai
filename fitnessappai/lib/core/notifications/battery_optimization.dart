import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Доступ к исключению приложения из оптимизации батареи (задача 48.7).
///
/// Оптимизация батареи — основной инструмент, которым OEM (Xiaomi, Huawei,
/// Samsung) душит фоновые будильники: система откладывает их до выхода
/// приложения на экран, и напоминание приходит только вместе с ручным
/// открытием. Исключение нужно не всем, поэтому запрос живёт отдельной
/// кнопкой в настройках, а не всплывает сам.
abstract class BatteryOptimizationGateway {
  /// Исключено ли приложение из оптимизации батареи сейчас.
  ///
  /// `null` — статуса нет (не Android, канал не ответил): вызывающий обязан
  /// показать это как «неизвестно», а не выдумывать значение.
  Future<bool?> isIgnoring();

  /// Открывает системный диалог исключения и возвращает актуальный статус
  /// после ответа пользователя. Ошибка — сигнал показать её пользователю.
  Future<bool?> request();
}

/// Реализация через `MethodChannel` к `MainActivity` (Android).
///
/// Канал живёт только на Android: на других платформах запрос исключения не
/// имеет смысла, а ожидание ответа от несуществующего обработчика висит
/// вечно (так ведёт себя и тестовое окружение), поэтому сразу возвращается
/// `null`. На Android ответ приходит из `onActivityResult`, то есть после
/// закрытия системного диалога — устаревать статусу негде.
class MethodChannelBatteryOptimization implements BatteryOptimizationGateway {
  const MethodChannelBatteryOptimization();

  static const MethodChannel channel = MethodChannel(
    'com.example.fitnessappai/battery',
  );

  /// Подстраховка от зависшего канала: лучше спрятать плитку, чем держать
  /// секцию настроек в состоянии загрузки вечно.
  static const Duration _timeout = Duration(seconds: 10);

  /// Диалог исключения ждёт ответа человека, поэтому сюда обычный таймаут
  /// канала не годится: через 10 секунд «Allow» ещё не нажали, а секция уже
  /// показала бы ошибку и потеряла бы поздний успешный ответ. Запас в
  /// минуты — на решение пользователя; если ответа нет и тогда, ошибка
  /// честнее вечной загрузки.
  static const Duration _requestTimeout = Duration(minutes: 2);

  @override
  Future<bool?> isIgnoring() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      return await channel
          .invokeMethod<bool>('isIgnoringBatteryOptimizations')
          .timeout(_timeout);
    } on TimeoutException {
      return null;
    }
  }

  @override
  Future<bool?> request() async {
    if (!Platform.isAndroid) {
      return null;
    }
    return channel
        .invokeMethod<bool>('requestIgnoreBatteryOptimizations')
        .timeout(_requestTimeout);
  }
}
