import 'package:flutter/services.dart';

/// Запускает установку скачанного APK через систему Android (64.1).
abstract class ApkInstaller {
  /// Открывает системный установщик для файла [apkPath]. Возвращает
  /// `false`, если установка не стартовала (нет платформенной реализации
  /// или системный отказ).
  Future<bool> install(String apkPath);
}

/// Реализация через `MethodChannel` к `MainActivity` (канал `file_saver`,
/// тот же, что у экспорта истории — 64.1).
class MethodChannelApkInstaller implements ApkInstaller {
  const MethodChannelApkInstaller();

  static const MethodChannel _channel = MethodChannel(
    'com.example.fitnessappai/file_saver',
  );

  @override
  Future<bool> install(String apkPath) async {
    try {
      final result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': apkPath,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
