import 'package:audioplayers/audioplayers.dart';

import 'package:fitnessappai/app/sound/sound_settings_repository.dart';

/// Играет звуковой сигнал по завершении таймеров (отдых, разминка).
abstract class SoundService {
  /// Играет сигнал, если звук включён. Беззвучно, если выключен.
  Future<void> playCompletion();

  /// Освобождает ресурсы аудио-плеера.
  Future<void> dispose();
}

/// Реализация [SoundService] на `audioplayers`: встроенный beep-ассет
/// или выбранный пользователем файл из настроек.
class AudioplayersSoundService implements SoundService {
  AudioplayersSoundService(this._repository);

  static const String defaultAssetPath = 'assets/sounds/beep.wav';

  final SoundSettingsRepository _repository;
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playCompletion() async {
    final repository = _repository;
    if (!await repository.isEnabled()) {
      return;
    }
    final filePath = await repository.soundFilePath();
    if (filePath != null && filePath.isNotEmpty) {
      await _player.play(DeviceFileSource(filePath));
      return;
    }
    await _player.play(AssetSource(defaultAssetPath));
  }

  @override
  Future<void> dispose() => _player.dispose();
}

/// Заглушка для тестов: фиксирует вызовы, но не играет звук.
class StubSoundService implements SoundService {
  int completionCalls = 0;

  @override
  Future<void> playCompletion() async {
    completionCalls++;
  }

  @override
  Future<void> dispose() async {}
}
