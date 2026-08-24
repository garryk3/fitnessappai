import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

/// Кэш [ImageProvider] по пути файла.
///
/// Возвращает один и тот же экземпляр [ImageProvider] для одного пути
/// (и [cacheWidth]), чтобы Flutter не создавал дубликаты при перестроениях.
class MediaCache {
  final Map<String, ImageProvider> _cache = <String, ImageProvider>{};
  final Map<String, ImageProvider> _blobCache = <String, ImageProvider>{};

  /// Возвращает провайдер для файла по [path].
  ///
  /// Если [path] передан и файл существует, создаёт [FileImage].
  /// Если файл по [path] не существует, но передан [blob], использует его
  /// как fallback (для данных, импортированных из другой БД).
  /// Если оба равны `null`, возвращает `null`.
  ///
  /// [cacheWidth] ограничивает размер декодируемого изображения и учитывается
  /// в ключе кэша: разные [cacheWidth] дают разные провайдеры.
  ImageProvider? imageFor(
    String? path, {
    Uint8List? blob,
    int? cacheWidth,
  }) {
    if (path != null && File(path).existsSync()) {
      return _cache.putIfAbsent(
        _key(path, cacheWidth),
        () => ResizeImage.resizeIfNeeded(
          cacheWidth,
          null,
          FileImage(File(path)),
        ),
      );
    }
    if (blob != null && blob.isNotEmpty) {
      final blobKey = _blobKey(blob, cacheWidth);
      return _blobCache.putIfAbsent(
        blobKey,
        () => ResizeImage.resizeIfNeeded(cacheWidth, null, MemoryImage(blob)),
      );
    }
    if (path != null) {
      return _cache.putIfAbsent(
        _key(path, cacheWidth),
        () => ResizeImage.resizeIfNeeded(
          cacheWidth,
          null,
          FileImage(File(path)),
        ),
      );
    }
    return null;
  }

  /// Удаляет из кэша провайдеры для файла по [path] (например, после
  /// удаления файла), чтобы не оставались ссылки на несуществующий путь.
  void remove(String path) {
    _cache.removeWhere((key, _) => key.startsWith('$path::'));
  }

  /// Очищает кэш (например, после удаления файлов).
  void clear() {
    _cache.clear();
    _blobCache.clear();
  }

  String _key(String path, int? cacheWidth) => '$path::$cacheWidth';

  String _blobKey(Uint8List blob, int? cacheWidth) =>
      'blob::${blob.lengthInBytes}::${blob.hashCode}::$cacheWidth';
}
