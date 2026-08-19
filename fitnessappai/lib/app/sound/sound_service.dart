import 'dart:async';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

import 'package:fitnessappai/app/sound/sound_settings_repository.dart';

/// Играет звуковой сигнал по завершении таймеров (отдых, разминка).
abstract class SoundService {
  /// Играет сигнал, если звук включён. Беззвучно, если выключен.
  Future<void> playCompletion();

  /// Останавливает воспроизведение.
  Future<void> stop();

  /// Освобождает ресурсы аудио-плеера.
  Future<void> dispose();
}

/// Реализация [SoundService] на `audioplayers`: встроенный ассет
/// (звук окончания таймера) или выбранный пользователем файл из настроек.
class AudioplayersSoundService implements SoundService {
  AudioplayersSoundService(this._repository);

  static const String defaultAssetPath = 'sounds/timer.mp3';
  static const Duration maxDuration = Duration(seconds: 5);

  final SoundSettingsRepository _repository;
  final AudioPlayer _player = AudioPlayer();
  Timer? _autoStopTimer;

  static Future<void> configureGlobalContext() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          stayAwake: true,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  @override
  Future<void> playCompletion() async {
    final repository = _repository;
    if (!await repository.isEnabled()) {
      return;
    }
    try {
      final filePath = await repository.soundFilePath();
      if (filePath != null && filePath.isNotEmpty) {
        await _player.play(DeviceFileSource(filePath));
      } else {
        await _player.play(AssetSource(defaultAssetPath));
      }
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(maxDuration, stop);
    } catch (e) {
      log('Не удалось воспроизвести звук таймера', error: e);
    }
  }

  @override
  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    _autoStopTimer?.cancel();
    await _player.dispose();
  }
}

/// Заглушка для тестов: фиксирует вызовы, но не играет звук.
class StubSoundService implements SoundService {
  int completionCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> playCompletion() async {
    completionCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {}
}
