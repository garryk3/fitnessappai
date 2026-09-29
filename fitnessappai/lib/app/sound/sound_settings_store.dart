/// Хранилище настроек звука: переключатель и путь к файлу.
///
/// Общий интерфейс для сигналов таймеров ([SoundSettingsRepository]) и
/// напоминаний о тренировках ([ReminderSoundSettingsRepository]) — оба
/// используют один и тот же контроллер и плеер (задача 47.5).
abstract class SoundSettingsStore {
  /// Включён ли звук (по умолчанию — включён).
  Future<bool> isEnabled();

  /// Путь к выбранному пользователем файлу (null — встроенный сигнал).
  Future<String?> soundFilePath();

  /// Сохраняет переключатель звука.
  Future<void> setEnabled(bool enabled);

  /// Сохраняет путь к выбранному файлу (null — встроенный сигнал).
  Future<void> setSoundFile(String? path);
}

/// Снимок настроек звука — то, что контроллер сообщает наружу после
/// изменения, чтобы применить настройки там, где это нужно (например,
/// пересоздать канал уведомлений).
class SoundSettingsSnapshot {
  const SoundSettingsSnapshot({required this.enabled, required this.filePath});

  /// Включён ли звук.
  final bool enabled;

  /// Путь к выбранному файлу (null — встроенный сигнал).
  final String? filePath;
}
