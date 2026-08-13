import 'dart:io';

import 'package:flutter/painting.dart';

/// Кэш [ImageProvider] по пути файла.
///
/// Возвращает один и тот же экземпляр [ImageProvider] для одного пути
/// (и [cacheWidth]), чтобы Flutter не создавал дубликаты при перестроениях.
class MediaCache {
  final Map<String, ImageProvider> _cache = <String, ImageProvider>{};

  /// Возвращает провайдер для файла по [path].
  ///
  /// [cacheWidth] ограничивает размер декодируемого изображения и учитывается
  /// в ключе кэша: разные [cacheWidth] дают разные провайдеры.
  ImageProvider imageFor(String path, {int? cacheWidth}) {
    return _cache.putIfAbsent(
      _key(path, cacheWidth),
      () => ResizeImage.resizeIfNeeded(cacheWidth, null, FileImage(File(path))),
    );
  }

  /// Удаляет из кэша провайдеры для файла по [path] (например, после
  /// удаления файла), чтобы не оставались ссылки на несуществующий путь.
  void remove(String path) {
    _cache.removeWhere((key, _) => key.startsWith('$path::'));
  }

  /// Очищает кэш (например, после удаления файлов).
  void clear() => _cache.clear();

  String _key(String path, int? cacheWidth) => '$path::$cacheWidth';
}
