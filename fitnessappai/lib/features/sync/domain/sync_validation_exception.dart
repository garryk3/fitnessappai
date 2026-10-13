/// Причина отказа валидации импортируемого файла БД.
///
/// Тексты сообщений живут в `app_ru.arb` (`syncError*`) и локализуются
/// на стороне UI: доменный слой не хардкодит русские строки.
enum SyncValidationError {
  /// Файл не является SQLite-базой (не тот magic bytes / не тот формат).
  notADatabase,

  /// База повреждена (PRAGMA integrity_check не прошёл).
  corrupted,

  /// Версия схемы файла новее установленной в приложении.
  schemaNewer,
}

/// Ошибка валидации импортируемого файла БД.
///
/// Бросается, когда файл повреждён, не является SQLite-базой или имеет
/// несовместимую версию схемы. Для показа пользователю причина переводится
/// в локализованный текст через `syncValidationMessage` (settings/ui).
class SyncValidationException implements Exception {
  const SyncValidationException(
    this.reason, {
    this.schemaVersion,
    this.installedVersion,
  });

  final SyncValidationError reason;

  /// Версия схемы файла; заполняется только для [SyncValidationError.schemaNewer].
  final int? schemaVersion;

  /// Версия схемы, установленная в приложении; для [SyncValidationError.schemaNewer].
  final int? installedVersion;

  @override
  String toString() =>
      'SyncValidationException(${reason.name}'
      '${schemaVersion != null ? ', schemaVersion: $schemaVersion' : ''}'
      '${installedVersion != null ? ', installedVersion: $installedVersion' : ''})';
}
