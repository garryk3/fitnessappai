import 'dart:async';
import 'dart:developer';

import 'package:audio_session/audio_session.dart' hide AndroidAudioFocus;
import 'package:audioplayers/audioplayers.dart';

import 'package:fitnessappai/app/sound/sound_settings_repository.dart';

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
/// ассет (звук окончания таймера) или выбранный пользователем файл из настроек.
///
/// Аудио-фокус управляется через [AudioSession] с типом `gainTransientMayDuck`
/// (приглушение чужой музыки вместо полной остановки), поэтому `audioplayers`
/// не запрашивает фокус сам (`audioFocus: none`).
class AudioplayersSoundService implements SoundService {
  AudioplayersSoundService(this._repository) {
    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      _isPlaying = playing;
      _isPlayingController.add(playing);
    });
  }

  static const String defaultAssetPath = 'sounds/timer.mp3';

  final SoundSettingsRepository _repository;
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

  @override
  Future<void> playCompletion() async {
    final repository = _repository;
    if (!await repository.isEnabled()) {
      return;
    }
    try {
      await _activateFocus();
      final filePath = await repository.soundFilePath();
      if (filePath != null && filePath.isNotEmpty) {
        await _player.play(DeviceFileSource(filePath));
      } else {
        await _player.play(AssetSource(defaultAssetPath));
      }
    } catch (e) {
      log('Не удалось воспроизвести звук таймера', error: e);
    }
  }

  @override
  Future<void> preview() async {
    try {
      await _activateFocus();
      final filePath = await _repository.soundFilePath();
      if (filePath != null && filePath.isNotEmpty) {
        await _player.play(DeviceFileSource(filePath));
      } else {
        await _player.play(AssetSource(defaultAssetPath));
      }
    } catch (e) {
      log('Не удалось воспроизвести звук (preview)', error: e);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    // Не вызываем setActive(false): при gainTransientMayDuck система
    // автоматически восстанавливает громкость при потере фокуса.
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
