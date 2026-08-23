import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/sound/sound_settings_repository.dart';

typedef SoundFilePicker = Future<String?> Function();

/// Управляет настройками звуковых сигналов: переключатель, выбор файла
/// и предпрослушивание.
class SoundSettingsController {
  SoundSettingsController({
    required this._repository,
    SoundFilePicker? pickFile,
    SoundService? soundService,
  }) : _pickFile = pickFile ?? _defaultPick,
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _soundService = soundService {
    _subscription = _soundService?.isPlayingStream.listen((playing) {
      isPlaying.value = playing;
    });
  }

  final SoundSettingsRepository _repository;
  final SoundFilePicker _pickFile;
  final SoundService? _soundService;
  StreamSubscription<bool>? _subscription;

  final Signal<bool> isLoading = Signal(true);
  final Signal<bool> enabled = Signal(true);
  final Signal<String?> soundFilePath = Signal(null);
  final Signal<String?> statusText = Signal(null);
  final Signal<bool> hasError = Signal(false);
  final Signal<bool> isPlaying = Signal(false);

  /// Загружает сохранённые настройки звука.
  Future<void> load() async {
    try {
      enabled.value = await _repository.isEnabled();
      soundFilePath.value = await _repository.soundFilePath();
    } finally {
      isLoading.value = false;
    }
  }

  /// Включает/выключает звук и сохраняет выбор.
  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _repository.setEnabled(value);
  }

  /// Переключает предпрослушивание: play если не играет, stop если играет.
  Future<void> togglePreview() async {
    if (isPlaying.value) {
      await _soundService?.stop();
    } else {
      await _soundService?.preview();
    }
  }

  /// Выбирает звуковой файл с устройства и сохраняет путь.
  Future<void> pickSoundFile() async {
    try {
      final path = await _pickFile();
      if (path == null) {
        return;
      }
      soundFilePath.value = path;
      await _repository.setSoundFile(path);
      statusText.value = 'Звук сохранён';
      hasError.value = false;
    } catch (error) {
      statusText.value = 'Ошибка выбора звука: $error';
      hasError.value = true;
    }
  }

  /// Сбрасывает выбор на встроенный сигнал.
  Future<void> resetSoundFile() async {
    soundFilePath.value = null;
    await _repository.setSoundFile(null);
    statusText.value = 'Стандартный сигнал';
    hasError.value = false;
  }

  /// Освобождает ресурсы (подписку на состояние воспроизведения).
  void dispose() {
    _subscription?.cancel();
  }

  static Future<String?> _defaultPick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'ogg', 'm4a', 'aac', 'flac'],
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final path = result.files.single.path;
    if (path == null || !File(path).existsSync()) {
      return null;
    }
    return path;
  }
}
