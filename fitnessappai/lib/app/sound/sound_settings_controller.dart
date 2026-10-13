import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/sound/sound_settings_store.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

typedef SoundFilePicker = Future<String?> Function();

/// Вызывается после каждого изменения настроек — например, чтобы применить
/// новый звук к каналу уведомлений (задача 47.5).
typedef SoundSettingsChanged =
    Future<void> Function(SoundSettingsSnapshot snapshot);

/// Вид статуса настроек звука (без текста).
///
/// Текст локализуется на стороне секции (`soundStatusMessage`), контроллер
/// не хранит русские строки мимо `app_ru.arb`.
enum SoundStatusKind {
  /// Файл сохранён и доступен системе.
  saved,

  /// Файл сохранён, но системный процесс не сможет его воспроизвести (48.1).
  savedSystemUnreadable,

  /// Выбор сброшен на встроенный сигнал.
  reset,

  /// Ошибка выбора файла (детали — в [SoundStatus.error]).
  pickFailed,
}

/// Структурированный статус настроек звука.
///
/// Для ошибки несёт исходный объект ошибки — человекочитаемая деталь
/// составляется при локализации (`soundStatusMessage`).
class SoundStatus {
  const SoundStatus(this.kind, {this.error});

  final SoundStatusKind kind;

  /// Исходная ошибка (только для `pickFailed`, иначе `null`).
  final Object? error;
}

/// Управляет настройками звуковых сигналов: переключатель, выбор файла
/// и предпрослушивание.
///
/// Один контроллер обслуживает и сигналы таймеров, и сигнал напоминаний:
/// отличаются только хранилище ([SoundSettingsStore]) и обработчик изменений.
class SoundSettingsController {
  SoundSettingsController({
    required this._repository,
    SoundFilePicker? pickFile,
    SoundService? soundService,
    SoundSettingsChanged? onChanged,
  }) : _pickFile = pickFile ?? _defaultPick,
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _soundService = soundService,
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _onChanged = onChanged {
    _subscription = _soundService?.isPlayingStream.listen((playing) {
      isPlaying.value = playing;
    });
  }

  final SoundSettingsStore _repository;
  final SoundSettingsChanged? _onChanged;
  final SoundFilePicker _pickFile;
  final SoundService? _soundService;
  StreamSubscription<bool>? _subscription;

  final Signal<bool> isLoading = Signal(true);
  final Signal<bool> enabled = Signal(true);
  final Signal<String?> soundFilePath = Signal(null);
  final Signal<bool> soundSystemReadable = Signal(true);

  /// Последняя операция (структурированный статус): текст локализуется на
  /// стороне секции (`soundStatusMessage`), контроллер хранит только вид.
  final Signal<SoundStatus?> status = Signal(null);
  final Signal<bool> hasError = Signal(false);
  final Signal<bool> isPlaying = Signal(false);

  /// Загружает сохранённые настройки звука.
  Future<void> load() async {
    try {
      enabled.value = await _repository.isEnabled();
      await _reloadFile();
    } finally {
      isLoading.value = false;
    }
  }

  /// Включает/выключает звук и сохраняет выбор.
  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _repository.setEnabled(value);
    await _notifyChanged();
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
      // Путь мог измениться: репозиторий копирует файл в постоянное хранилище.
      await _reloadFile();
      status.value = _savedStatus();
      await _notifyChanged();
      hasError.value = false;
    } catch (error) {
      status.value = SoundStatus(SoundStatusKind.pickFailed, error: error);
      hasError.value = true;
    }
  }

  /// Сбрасывает выбор на встроенный сигнал.
  Future<void> resetSoundFile() async {
    await _repository.setSoundFile(null);
    // Путь и читаемость перечитываем: после сброса файла нет, а значит и
    // вопроса о его доступности системе тоже (48.1).
    await _reloadFile();
    status.value = const SoundStatus(SoundStatusKind.reset);
    hasError.value = false;
    await _notifyChanged();
  }

  /// Перечитывает путь и читаемость файла из хранилища.
  Future<void> _reloadFile() async {
    soundFilePath.value = await _repository.soundFilePath();
    soundSystemReadable.value = await _repository.isSoundSystemReadable();
  }

  /// Статус после сохранения файла: предупреждаем, если системное уведомление
  /// не сможет использовать выбранный файл (48.1).
  SoundStatus _savedStatus() {
    if (soundFilePath.value == null || soundSystemReadable.value) {
      return const SoundStatus(SoundStatusKind.saved);
    }
    return const SoundStatus(SoundStatusKind.savedSystemUnreadable);
  }

  /// Сообщает подписчику об изменившихся настройках.
  Future<void> _notifyChanged() async {
    await _onChanged?.call(
      SoundSettingsSnapshot(
        enabled: enabled.value,
        filePath: soundFilePath.value,
        systemReadable: soundSystemReadable.value,
      ),
    );
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

/// Локализованное сообщение статуса настроек звука.
///
/// Тексты — в `app_ru.arb` (`soundStatus*`); контроллер хранит только вид
/// статуса и исходный объект ошибки.
String soundStatusMessage(AppLocalizations l10n, SoundStatus status) =>
    switch (status.kind) {
      SoundStatusKind.saved => l10n.soundStatusSaved,
      SoundStatusKind.savedSystemUnreadable => l10n.soundStatusSystemUnreadable,
      SoundStatusKind.reset => l10n.soundDefaultLabel,
      SoundStatusKind.pickFailed =>
        '${l10n.soundStatusPickFailed}: ${status.error}',
    };
