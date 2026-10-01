import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/sound/sound_settings_controller.dart';
import 'package:fitnessappai/app/sound/sound_settings_store.dart';

/// Хранилище-заглушка: держит настройки в памяти.
class _FakeStore extends SoundSettingsStore {
  bool enabled = true;
  String? filePath;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<String?> soundFilePath() async => filePath;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> setSoundFile(String? path) async => filePath = path;
}

/// Плеер-заглушка: считает вызовы play/stop.
class _FakeSoundService implements SoundService {
  final StreamController<bool> playing = StreamController<bool>.broadcast();
  int previews = 0;
  int stops = 0;
  int completions = 0;

  @override
  bool get isPlaying => false;

  @override
  Stream<bool> get isPlayingStream => playing.stream;

  @override
  Future<void> playCompletion() async => completions++;

  @override
  Future<void> preview() async => previews++;

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => playing.close();
}

void main() {
  late _FakeStore store;
  late _FakeSoundService soundService;
  late List<SoundSettingsSnapshot> applied;
  late SoundSettingsController controller;

  setUp(() {
    store = _FakeStore();
    soundService = _FakeSoundService();
    applied = [];
    controller = SoundSettingsController(
      repository: store,
      soundService: soundService,
      pickFile: () async => '/sounds/custom.mp3',
      onChanged: (snapshot) async => applied.add(snapshot),
    );
  });

  tearDown(() {
    controller.dispose();
    soundService.dispose();
  });

  test('load читает сохранённые настройки', () async {
    store.enabled = false;
    store.filePath = '/sounds/saved.mp3';

    await controller.load();

    expect(controller.isLoading.value, isFalse);
    expect(controller.enabled.value, isFalse);
    expect(controller.soundFilePath.value, '/sounds/saved.mp3');
  });

  test('переключатель сохраняется и сообщает о применении (47.5)', () async {
    await controller.setEnabled(false);

    expect(await store.isEnabled(), isFalse);
    expect(applied, hasLength(1));
    expect(applied.single.enabled, isFalse);
  });

  test('выбор файла сохраняется и сообщает о применении', () async {
    await controller.pickSoundFile();

    expect(await store.soundFilePath(), '/sounds/custom.mp3');
    expect(controller.soundFilePath.value, '/sounds/custom.mp3');
    expect(controller.hasError.value, isFalse);
    expect(applied.single.filePath, '/sounds/custom.mp3');
  });

  test('отмена выбора файла ничего не применяет', () async {
    controller = SoundSettingsController(
      repository: store,
      soundService: soundService,
      pickFile: () async => null,
      onChanged: (snapshot) async => applied.add(snapshot),
    );

    await controller.pickSoundFile();

    expect(applied, isEmpty);
    expect(controller.soundFilePath.value, isNull);
  });

  test('сброс файла очищает настройку и сообщает о применении', () async {
    await controller.pickSoundFile();
    applied.clear();

    await controller.resetSoundFile();

    expect(await store.soundFilePath(), isNull);
    expect(controller.soundFilePath.value, isNull);
    expect(applied, hasLength(1));
    expect(applied.single.filePath, isNull);
  });

  test('путь из хранилища имеет приоритет над путём пикера', () async {
    // Репозиторий копирует файл в постоянное хранилище и возвращает новый
    // путь — контроллер обязан показывать именно его (47.5).
    controller = SoundSettingsController(
      repository: _CopyingStore(),
      pickFile: () async => '/cache/picked.mp3',
    );

    await controller.pickSoundFile();

    expect(controller.soundFilePath.value, '/documents/reminder_sounds/p.mp3');
  });

  test('предпрослушивание переключается play/stop', () async {
    await controller.togglePreview();
    expect(soundService.previews, 1);
    expect(soundService.stops, 0);

    soundService.playing.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isPlaying.value, isTrue);

    await controller.togglePreview();
    expect(soundService.stops, 1);
  });

  test('ошибка выбора файла попадает в статус', () async {
    controller = SoundSettingsController(
      repository: store,
      pickFile: () async => throw Exception('нет доступа'),
    );

    await controller.pickSoundFile();

    expect(controller.hasError.value, isTrue);
    expect(controller.statusText.value, contains('Ошибка выбора звука'));
  });

  group('читаемость файла системой (48.1)', () {
    test('файл, доступный системе, подтверждается обычным статусом', () async {
      final readable = _ReadabilityStore(systemReadable: true);
      controller = SoundSettingsController(
        repository: readable,
        pickFile: () async => '/cache/picked.mp3',
        onChanged: (snapshot) async => applied.add(snapshot),
      );

      await controller.pickSoundFile();

      expect(controller.soundSystemReadable.value, isTrue);
      expect(controller.statusText.value, 'Звук сохранён');
      expect(applied.single.systemReadable, isTrue);
    });

    test('недоступный системе файл попадает в статус и в снимок', () async {
      // Канал уведомлений такой файл не воспроизведёт — молчаливый стандартный
      // сигнал вводил владельца в заблуждение (48.1).
      final private = _ReadabilityStore(systemReadable: false);
      controller = SoundSettingsController(
        repository: private,
        pickFile: () async => '/cache/picked.mp3',
        onChanged: (snapshot) async => applied.add(snapshot),
      );

      await controller.pickSoundFile();

      expect(controller.soundSystemReadable.value, isFalse);
      expect(controller.statusText.value, contains('системе недоступен'));
      expect(applied.single.systemReadable, isFalse);
    });

    test('состояние читаемости подхватывается при загрузке', () async {
      final private = _ReadabilityStore(systemReadable: false)
        ..filePath = '/x.mp3';

      controller = SoundSettingsController(repository: private);
      await controller.load();

      expect(controller.soundFilePath.value, '/x.mp3');
      expect(controller.soundSystemReadable.value, isFalse);
    });

    test('сброс файла оставляет читаемость включённой', () async {
      final private = _ReadabilityStore(systemReadable: false);
      controller = SoundSettingsController(
        repository: private,
        onChanged: (snapshot) async => applied.add(snapshot),
      );
      await controller.load();

      await controller.resetSoundFile();

      expect(controller.soundSystemReadable.value, isTrue);
      expect(applied.single.systemReadable, isTrue);
    });
  });
}

/// Хранилище с управляемой читаемостью файла для системного процесса.
class _ReadabilityStore extends SoundSettingsStore {
  _ReadabilityStore({required this.systemReadable});

  bool systemReadable;
  String? filePath;

  @override
  Future<bool> isEnabled() async => true;

  @override
  Future<String?> soundFilePath() async => filePath;

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> setSoundFile(String? path) async {
    filePath = path;
    // Сброс на встроенный сигнал: читаемость больше не про файл.
    if (path == null) {
      systemReadable = true;
    }
  }

  @override
  Future<bool> isSoundSystemReadable() async => systemReadable;
}

/// Хранилище, копирующее файл (как [ReminderSoundSettingsRepository]).
class _CopyingStore extends SoundSettingsStore {
  String? filePath;

  @override
  Future<bool> isEnabled() async => true;

  @override
  Future<String?> soundFilePath() async => filePath;

  @override
  Future<void> setEnabled(bool value) async {}

  @override
  Future<void> setSoundFile(String? path) async {
    filePath = path == null ? null : '/documents/reminder_sounds/p.mp3';
  }
}
