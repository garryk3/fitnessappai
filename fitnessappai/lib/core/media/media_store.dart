import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Провайдер директории приложения для медиа.
typedef MediaDirectoryProvider = Future<Directory> Function();

/// Загрузчик ассета по пути в bundle.
typedef AssetLoader = Future<Uint8List> Function(String assetPath);

/// Тип медиафайла, выбираемого системным пикером.
enum MediaFileType { any, image }

/// Пикер файлов; возвращает выбранный файл или `null` при отмене.
typedef MediaFilePicker = Future<XFile?> Function();

/// Бросается при неудачном импорте медиафайла (ошибка пикера, чтения или
/// копирования файла).
class MediaImportException implements Exception {
  MediaImportException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'MediaImportException($message${cause == null ? '' : ', cause: $cause'})';
}

/// Слой доступа к медиафайлам (анимации и изображения упражнений).
///
/// Копирует ассеты и импортированные файлы в поддиректорию `media`
/// внутри директории документов приложения.
class MediaStore {
  MediaStore({
    MediaDirectoryProvider directoryProvider = _defaultDirectoryProvider,
    AssetLoader assetLoader = _defaultAssetLoader,
    MediaFilePicker? filePicker,
  }) : this._(directoryProvider, assetLoader, filePicker);

  MediaStore._(this._directoryProvider, this._assetLoader, this._filePicker);

  static const String mediaSubDir = 'media';

  final MediaDirectoryProvider _directoryProvider;
  final AssetLoader _assetLoader;
  final MediaFilePicker? _filePicker;

  /// Возвращает директорию приложения для медиа, создавая её при необходимости.
  Future<Directory> ensureAppMediaDir() async {
    final docs = await _directoryProvider();
    final media = Directory(p.join(docs.path, mediaSubDir));
    if (!await media.exists()) {
      await media.create(recursive: true);
    }
    return media;
  }

  /// Копирует ассет из bundle в storage и возвращает путь к созданному файлу.
  Future<String> copyAssetToStorage(String assetPath) async {
    final bytes = await _assetLoader(assetPath);
    return _writeFile(p.basename(assetPath), bytes);
  }

  /// Открывает системный диалог выбора файла и копирует его в storage.
  ///
  /// Возвращает путь к созданному файлу или `null`, если выбор отменён.
  /// При ошибке пикера, чтения или копирования бросает [MediaImportException].
  Future<String?> importFromPicker({
    MediaFileType fileType = MediaFileType.any,
  }) async {
    final XFile? picked;
    try {
      final injected = _filePicker;
      picked = injected != null
          ? await injected()
          : await _platformPicker(fileType);
    } catch (e) {
      throw MediaImportException('Не удалось открыть выбор файла', cause: e);
    }
    if (picked == null) {
      return null;
    }
    try {
      return await _writeFile(picked.name, await picked.readAsBytes());
    } catch (e) {
      throw MediaImportException(
        'Не удалось скопировать файл "${picked.path}"',
        cause: e,
      );
    }
  }

  /// Удаляет файл по [path]. Отсутствующий файл не считается ошибкой.
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> _writeFile(String fileName, Uint8List bytes) async {
    final dir = await ensureAppMediaDir();
    final target = _uniqueFile(dir, fileName);
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  /// Ищет свободное имя файла: при конфликте добавляет `(1)`, `(2)` и т.д.
  File _uniqueFile(Directory dir, String fileName) {
    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var candidate = File(p.join(dir.path, fileName));
    var counter = 1;
    while (candidate.existsSync()) {
      candidate = File(p.join(dir.path, '$base($counter)$ext'));
      counter++;
    }
    return candidate;
  }
}

/// Директория приложения для медиа: documents, при сбое — support, затем temp.
Future<Directory> _defaultDirectoryProvider() async {
  try {
    return await getApplicationDocumentsDirectory();
  } on PlatformException {
    return _fallbackDirectory();
  } catch (_) {
    return _fallbackDirectory();
  }
}

Future<Directory> _fallbackDirectory() async {
  try {
    return await getApplicationSupportDirectory();
  } on PlatformException {
    return _tempDirectory();
  } catch (_) {
    return _tempDirectory();
  }
}

Future<Directory> _tempDirectory() async => getTemporaryDirectory();

Future<Uint8List> _defaultAssetLoader(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Системный пикер файлов с фильтром по [fileType].
///
/// Байты читаются через `withData`, поэтому результат работает и с
/// content-URI (Android) без обращения к `File`.
Future<XFile?> _platformPicker(MediaFileType fileType) async {
  final type = switch (fileType) {
    MediaFileType.any => FileType.any,
    MediaFileType.image => FileType.image,
  };
  final result = await FilePicker.platform.pickFiles(
    type: type,
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }
  return result.files.single.xFile;
}
