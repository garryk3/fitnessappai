import 'dart:io';
import 'dart:typed_data';

import 'package:fitnessappai/core/media/media_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late Directory mediaDir;

  MediaStore store({
    required Map<String, Uint8List> assets,
    MediaFilePicker? picker,
  }) {
    return MediaStore(
      directoryProvider: () async => tempDir,
      assetLoader: (path) async => assets[path] ?? Uint8List(0),
      filePicker: picker ?? () async => null,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media_store_test');
    mediaDir = Directory(p.join(tempDir.path, MediaStore.mediaSubDir));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('ensureAppMediaDir создаёт директорию медиа', () async {
    final dir = await store(assets: <String, Uint8List>{}).ensureAppMediaDir();
    expect(dir.path, mediaDir.path);
    expect(await dir.exists(), isTrue);
  });

  test('ensureAppMediaDir идемпотентен', () async {
    final s = store(assets: <String, Uint8List>{});
    final first = await s.ensureAppMediaDir();
    final second = await s.ensureAppMediaDir();
    expect(second.path, first.path);
    expect(await second.exists(), isTrue);
  });

  test('copyAssetToStorage копирует байты ассета в media', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final path = await store(
      assets: {'assets/anim/ex.webp': bytes},
    ).copyAssetToStorage('assets/anim/ex.webp');
    expect(p.basename(path), 'ex.webp');
    expect(p.dirname(path), mediaDir.path);
    expect(await File(path).readAsBytes(), bytes);
  });

  test('copyAssetToStorage не перезаписывает существующий файл', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final s = store(assets: {'a.webp': bytes});
    final first = await s.copyAssetToStorage('a.webp');
    final second = await s.copyAssetToStorage('a.webp');
    expect(p.basename(first), 'a.webp');
    expect(p.basename(second), 'a(1).webp');
    expect(await File(first).readAsBytes(), bytes);
    expect(await File(second).readAsBytes(), bytes);
  });

  test('importFromPicker копирует выбранный файл', () async {
    final source = File(p.join(tempDir.path, 'picked.gif'));
    final bytes = Uint8List.fromList([9, 8, 7]);
    await source.writeAsBytes(bytes);
    final path = await store(
      assets: <String, Uint8List>{},
      picker: () async => source.path,
    ).importFromPicker();
    expect(path, isNotNull);
    expect(await File(path!).readAsBytes(), bytes);
    expect(await source.exists(), isTrue);
  });

  test('importFromPicker возвращает null при отмене', () async {
    final s = store(assets: <String, Uint8List>{});
    expect(await s.importFromPicker(), isNull);
    expect(await mediaDir.exists(), isFalse);
  });

  test('deleteFile удаляет файл', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final s = store(assets: {'x.png': bytes});
    final path = await s.copyAssetToStorage('x.png');
    expect(await File(path).exists(), isTrue);
    await s.deleteFile(path);
    expect(await File(path).exists(), isFalse);
  });

  test('deleteFile не бросает исключение для отсутствующего файла', () async {
    final s = store(assets: <String, Uint8List>{});
    await expectLater(s.deleteFile('nonexistent.png'), completes);
  });
}
