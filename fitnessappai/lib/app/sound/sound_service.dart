import 'dart:async';
import 'dart:developer';

import 'package:audio_session/audio_session.dart' hide AndroidAudioFocus;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:fitnessappai/app/sound/sound_settings_store.dart';

/// Отдельный экземпляр [SoundService] для звука уведомлений о тренировках
/// (задача 47.5): в контейнере сервисы различаются по типу, поэтому у
/// предпрослушивания сигнала напоминаний своя запись.
typedef ReminderSoundService = AudioplayersSoundService;

/// Играет звуковой сигнал по завершении таймеров (отдых, разминка).
abstract class SoundService {
  /// Играет сигнал, если звук включён. Беззвучно, если выключен.
  Future<void> playCompletion();

  /// Останавливает воспроизведение.
  Future<void> stop();

  /// Воспроизводит текущий звук независимо от настройки вкл/выкл (для
  /// предпрослушивания в настройках).
  Future<void> preview();

  /// Идёт ли сейчас воспроизведение.
  bool get isPlaying;

  /// Стрим изменения состояния воспроизведения.
  Stream<bool> get isPlayingStream;

  /// Освобождает ресурсы аудио-плеера.
  Future<void> dispose();
}

/// Реализация [SoundService] на `audioplayers` + `audio_session`: встроенный
/// ассет или выбранный пользователем файл из настроек.
///
/// Экземпляр работает с любым [SoundSettingsStore], поэтому тем же классом
/// проигрывается предпрослушивание сигнала напоминаний (задача 47.5). Встроенный
/// сигнал задаётся параметром `defaultAssetPath`: у таймеров и у напоминаний он
/// разный, иначе предпрослушивание в настройках звучало бы не тем, что услышит
/// владелец (задача 48.1).
///
/// Аудио-фокус управляется через [AudioSession] с типом `gainTransientMayDuck`
/// (приглушение чужой музыки вместо полной остановки), поэтому `audioplayers`
/// не запрашивает фокус сам (`audioFocus: none`).
class AudioplayersSoundService implements SoundService {
  AudioplayersSoundService(
    this._repository, {
    String defaultAssetPath = timerAssetPath,
    // ignore: prefer_initializing_formals -- имя параметра публичное.
  }) : _defaultAssetPath = defaultAssetPath {
    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      _isPlaying = playing;
      _isPlayingController.add(playing);
    });
    _player.onPlayerComplete.listen((_) {
      _deactivateFocus();
    });
  }

  /// Встроенный сигнал окончания таймеров — дефолт этого класса.
  static const String timerAssetPath = 'sounds/timer.mp3';

  /// Встроенный сигнал напоминаний о тренировках.
  ///
  /// Побайтовая копия `android/app/src/main/res/raw/notification.mp3` — того же
  /// raw-ресурса, которым настроен канал уведомлений. Ассет нужен потому, что
  /// raw-ресурс из Dart недоступен, а предпрослушивание в настройках обязано
  /// звучать так же, как настоящее напоминание (задача 48.1). Менять файл надо
  /// в обоих местах сразу.
  static const String notificationAssetPath = 'sounds/notification.mp3';

  final SoundSettingsStore _repository;

  /// Встроенный сигнал этого экземпляра: таймеры и напоминания звучат по
  /// умолчанию по-разному (48.1).
  final String _defaultAssetPath;
  final AudioPlayer _player = AudioPlayer();
  AudioSession? _session;
  bool _isPlaying = false;
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  /// Аудио-контекст `audioplayers`: фокус не запрашивается (`none`) — им
  /// управляет [AudioSession].
  static AudioContext audioContext() => AudioContext(
    android: const AudioContextAndroid(
      stayAwake: true,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  /// Конфигурация [AudioSession]: короткий сигнал приглушает (duck) чужую
  /// музыку, а не останавливает её.
  static AudioSessionConfiguration sessionConfiguration() =>
      const AudioSessionConfiguration(
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      );

  static Future<void> configureGlobalContext() async {
    await AudioPlayer.global.setAudioContext(audioContext());
    final session = await AudioSession.instance;
    await session.configure(sessionConfiguration());
  }

  /// Лениво получает [AudioSession]; `null`, если плагин недоступен
  /// (например, на десктопе без реализации).
  Future<AudioSession?> _audioSessionOrNull() async {
    if (_session != null) {
      return _session;
    }
    try {
      _session = await AudioSession.instance;
    } catch (e) {
      log('audio_session недоступен', error: e, name: 'SoundService');
    }
    return _session;
  }

  Future<void> _activateFocus() async {
    final session = await _audioSessionOrNull();
    if (session == null) {
      return;
    }
    await session.setActive(
      true,
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    );
  }

  Future<void> _deactivateFocus() async {
    final session = await _audioSessionOrNull();
    if (session == null) {
      return;
    }
    await session.setActive(false);
  }

  @override
  Future<void> playCompletion() async {
    final repository = _repository;
    if (!await repository.isEnabled()) {
      return;
    }
    try {
      await _activateFocus();
      await _player.play(resolveSource(await repository.soundFilePath()));
    } catch (e) {
      log('Не удалось воспроизвести звук таймера', error: e);
    }
  }

  @override
  Future<void> preview() async {
    try {
      await _activateFocus();
      await _player.play(resolveSource(await _repository.soundFilePath()));
    } catch (e) {
      log('Не удалось воспроизвести звук (preview)', error: e);
    }
  }

  /// Источник звука этого экземпляра: файл из настроек, если он выбран, иначе
  /// его встроенный сигнал.
  Source resolveSource(String? filePath) =>
      resolveSourceFor(filePath, _defaultAssetPath);

  /// Выбор источника звука по правилу «файл важнее встроенного сигнала».
  ///
  /// Статический метод, а не метод экземпляра: конструктор создаёт
  /// `AudioPlayer`, а тот на тестовой платформе требует платформенного канала.
  /// Проверять нужно правило выбора, а не воспроизведение.
  @visibleForTesting
  static Source resolveSourceFor(String? filePath, String defaultAssetPath) {
    if (filePath != null && filePath.isNotEmpty) {
      return DeviceFileSource(filePath);
    }
    return AssetSource(defaultAssetPath);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _deactivateFocus();
  }

  @override
  Future<void> dispose() async {
    await _isPlayingController.close();
    await _player.dispose();
  }
}

/// Заглушка для тестов: фиксирует вызовы, но не играет звук.
class StubSoundService implements SoundService {
  int completionCalls = 0;
  int stopCalls = 0;
  int previewCalls = 0;
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get isPlayingStream => const Stream<bool>.empty();

  @override
  Future<void> playCompletion() async {
    completionCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _isPlaying = false;
  }

  @override
  Future<void> preview() async {
    previewCalls++;
    _isPlaying = true;
  }

  @override
  Future<void> dispose() async {}
}
