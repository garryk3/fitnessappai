import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';

/// Хранилище настроек звуковых сигналов в таблице `app_meta`.
class SoundSettingsRepository {
  SoundSettingsRepository(this._db);

  static const String enabledKey = 'sound_enabled';
  static const String fileKey = 'sound_file';

  final AppDatabase _db;

  /// Возвращает, включён ли звук (по умолчанию — включён).
  Future<bool> isEnabled() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(enabledKey))).getSingleOrNull();
    return row?.value != 'false';
  }

  /// Возвращает путь к выбранному пользователем звуковому файлу
  /// (null — встроенный сигнал).
  Future<String?> soundFilePath() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(fileKey))).getSingleOrNull();
    return row?.value;
  }

  /// Сохраняет переключатель звука.
  Future<void> setEnabled(bool enabled) async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(
            key: enabledKey,
            value: Value(enabled.toString()),
          ),
        );
  }

  /// Сохраняет путь к выбранному звуковому файлу (null — встроенный сигнал).
  Future<void> setSoundFile(String? path) async {
    if (path == null) {
      await (_db.delete(_db.appMeta)..where((t) => t.key.equals(fileKey))).go();
      return;
    }
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(key: fileKey, value: Value(path)),
        );
  }
}
