import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Скачивает APK новой версии во временную папку приложения (64.1).
abstract class ApkDownloader {
  /// Скачивает [url] и возвращает путь к сохранённому файлу.
  /// Бросает исключение при ошибке сети/записи — вызывающий код решает,
  /// как сообщить пользователю.
  Future<String> download(Uri url);
}

/// Реализация через `dart:io` HttpClient (без новых зависимостей).
class HttpApkDownloader implements ApkDownloader {
  const HttpApkDownloader();

  @override
  Future<String> download(Uri url) async {
    final dir = await getTemporaryDirectory();
    final apkDir = Directory('${dir.path}${Platform.pathSeparator}apk');
    await apkDir.create(recursive: true);
    final file = File('${apkDir.path}${Platform.pathSeparator}update.apk');

    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('Не удалось скачать APK: ${response.statusCode}');
      }
      final sink = file.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close(force: true);
    }
    return file.path;
  }
}
