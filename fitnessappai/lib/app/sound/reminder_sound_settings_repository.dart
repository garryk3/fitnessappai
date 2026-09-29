import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:fitnessappai/app/sound/sound_settings_store.dart';
import 'package:fitnessappai/core/database/app_database.dart';

/// Поставщик директории документов приложения (подменяется в тестах).
typedef ReminderSoundDirectoryProvider = Future<Directory> Function();

/// Хранилище настроек звука напоминаний в таблице `app_meta`.
///
/// Отдельные ключи от сигналов таймеров: у них свой файл и свой переключатель.
/// Выбранный файл копируется в `reminder_sounds` внутри директории документов:
/// системный пикер отдаёт путь во временном кэше, который может быть очищен,
/// а настройка должна переживать перезапуск приложения (задача 47.5).
class ReminderSoundSettingsRepository implements SoundSettingsStore {
  ReminderSoundSettingsRepository(
    this._db, {
    ReminderSoundDirectoryProvider directoryProvider =
        _defaultDirectoryProvider,
    // ignore: prefer_initializing_formals -- имя параметра публичное.
  }) : _directoryProvider = directoryProvider;

  static const String enabledKey = 'reminder_sound_enabled';
  static const String fileKey = 'reminder_sound_file';
  static const String subDir = 'reminder_sounds';

  final AppDatabase _db;
  final ReminderSoundDirectoryProvider _directoryProvider;

  @override
  Future<bool> isEnabled() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(enabledKey))).getSingleOrNull();
    return row?.value != 'false';
  }

  @override
  Future<String?> soundFilePath() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(fileKey))).getSingleOrNull();
    return row?.value;
  }

  @override
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

  @override
  Future<void> setSoundFile(String? path) async {
    final previous = await soundFilePath();
    if (path == null) {
      await (_db.delete(_db.appMeta)..where((t) => t.key.equals(fileKey))).go();
      await _deleteCopy(previous);
      return;
    }
    final stored = await _storeCopy(path) ?? path;
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(key: fileKey, value: Value(stored)),
        );
    if (previous != null && previous != stored) {
      await _deleteCopy(previous);
    }
  }

  /// Копирует [path] в постоянное хранилище приложения.
  ///
  /// Возвращает null, если копирование не удалось — тогда сохраняется исходный
  /// путь (как это делает настройка звука таймеров), чтобы выбор не терялся.
  Future<String?> _storeCopy(String path) async {
    final source = File(path);
    if (!await source.exists()) {
      return null;
    }
    try {
      final dir = Directory(p.join((await _directoryProvider()).path, subDir));
      await dir.create(recursive: true);
      final target = File(p.join(dir.path, p.basename(path)));
      await source.copy(target.path);
      return target.path;
    } on FileSystemException {
      return null;
    }
  }

  /// Удаляет ранее скопированный файл (копии лежат только в нашей папке).
  Future<void> _deleteCopy(String? path) async {
    if (path == null) {
      return;
    }
    try {
      final dir = Directory(p.join((await _directoryProvider()).path, subDir));
      if (!p.isWithin(dir.path, path)) {
        return;
      }
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Недоступный кэш или удалённый пользователем файл — не ошибка.
    }
  }

  static Future<Directory> _defaultDirectoryProvider() =>
      getApplicationDocumentsDirectory();
}
