import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MediaCache cache;

  setUp(() => cache = MediaCache());

  test('imageFor возвращает один и тот же провайдер для одного пути', () {
    expect(
      identical(cache.imageFor('/tmp/a.png'), cache.imageFor('/tmp/a.png')),
      isTrue,
    );
  });

  test('imageFor создаёт отдельный провайдер для другого пути', () {
    expect(
      identical(cache.imageFor('/tmp/a.png'), cache.imageFor('/tmp/b.png')),
      isFalse,
    );
  });

  test('cacheWidth учитывается в ключе кэша', () {
    final full = cache.imageFor('/tmp/a.png');
    final resized = cache.imageFor('/tmp/a.png', cacheWidth: 100);
    expect(identical(full, resized), isFalse);
    expect(
      identical(cache.imageFor('/tmp/a.png', cacheWidth: 100), resized),
      isTrue,
    );
  });

  test('clear сбрасывает кэш', () {
    final before = cache.imageFor('/tmp/a.png');
    cache.clear();
    expect(identical(cache.imageFor('/tmp/a.png'), before), isFalse);
  });

  test('без cacheWidth возвращается FileImage, с cacheWidth - ResizeImage', () {
    expect(cache.imageFor('/tmp/a.png'), isA<FileImage>());
    expect(cache.imageFor('/tmp/a.png', cacheWidth: 200), isA<ResizeImage>());
  });
}
