import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Скачивает APK новой версии во временную папку приложения (64.1).
abstract class ApkDownloader {
  /// Скачивает [url] и возвращает путь к сохранённому файлу.
  /// Бросает исключение при ошибке сети/записи или таймауте — вызывающий
  /// код решает, как сообщить пользователю.
  Future<String> download(Uri url);
}

/// Реализация через `dart:io` HttpClient (без новых зависимостей).
///
/// Таймауты (fix task-reviewer): соединение — 15 с, чтение — 60 с на
/// ожидание ответа и 2 мин на всю операцию — иначе «чёрная дыра» сети
/// вешает non-dismissible диалог загрузки навсегда.
class HttpApkDownloader implements ApkDownloader {
  const HttpApkDownloader();

  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _responseTimeout = Duration(seconds: 60);
  static const Duration _overallTimeout = Duration(minutes: 2);

  @override
  Future<String> download(Uri url) => _download(url).timeout(_overallTimeout);

  Future<String> _download(Uri url) async {
    final dir = await getTemporaryDirectory();
    final apkDir = Directory('${dir.path}${Platform.pathSeparator}apk');
    await apkDir.create(recursive: true);
    final file = File('${apkDir.path}${Platform.pathSeparator}update.apk');

    final client = HttpClient()..connectionTimeout = _connectTimeout;
    try {
      final request = await client.getUrl(url).timeout(_connectTimeout);
      final response = await request.close().timeout(_responseTimeout);
      if (response.statusCode != 200) {
        throw HttpException('Не удалось скачать APK: ${response.statusCode}');
      }
      final sink = file.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();
      } on Exception {
        await sink.close();
        rethrow;
      }
    } finally {
      client.close(force: true);
    }
    return file.path;
  }
}
