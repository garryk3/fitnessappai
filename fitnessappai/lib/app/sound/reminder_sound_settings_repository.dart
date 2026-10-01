import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:fitnessappai/app/sound/sound_settings_store.dart';
import 'package:fitnessappai/core/database/app_database.dart';

/// Поставщик директории документов приложения (подменяется в тестах).
typedef ReminderSoundDirectoryProvider = Future<Directory> Function();

/// Поставщик внешней директории приложения (подменяется в тестах).
///
/// Возвращает `null`, если внешнего хранилища нет (desktop, тесты) — тогда
/// файл копируется в приватный каталог и системе недоступен.
typedef ReminderSoundExternalDirectoryProvider = Future<Directory?> Function();

/// Хранилище настроек звука напоминаний в таблице `app_meta`.
///
/// Отдельные ключи от сигналов таймеров: у них свой файл и свой переключатель.
/// Выбранный файл копируется в `reminder_sounds` внутри директории документов:
/// системный пикер отдаёт путь во временном кэше, который может быть очищен,
/// а настройка должна переживать перезапуск приложения (задача 47.5).
///
/// Куда именно копируется — важно для звука канала уведомлений: его играет
/// `system_server`, и файл из приватного каталога ему недоступен, поэтому
/// Android играл стандартный сигнал вместо выбранного (задача 48.1). Поэтому
/// сначала пробуем внешнюю директорию приложения
/// (`/storage/emulated/0/Android/data/<package>/files/…`, системе читаема), и
/// только при неудаче — приватные документы. Факт переносимости хранится в
/// [readableKey], чтобы пережить перезапуск приложения.
class ReminderSoundSettingsRepository extends SoundSettingsStore {
  ReminderSoundSettingsRepository(
    this._db, {
    ReminderSoundDirectoryProvider directoryProvider =
        _defaultDirectoryProvider,
    ReminderSoundExternalDirectoryProvider externalDirectoryProvider =
        _defaultExternalDirectoryProvider,
    // ignore: prefer_initializing_formals -- имя параметра публичное.
  }) : _directoryProvider = directoryProvider,
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _externalDirectoryProvider = externalDirectoryProvider;

  static const String enabledKey = 'reminder_sound_enabled';
  static const String fileKey = 'reminder_sound_file';
  static const String readableKey = 'reminder_sound_file_readable';
  static const String subDir = 'reminder_sounds';

  final AppDatabase _db;
  final ReminderSoundDirectoryProvider _directoryProvider;
  final ReminderSoundExternalDirectoryProvider _externalDirectoryProvider;

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
  Future<bool> isSoundSystemReadable() async {
    final path = await soundFilePath();
    if (path == null) {
      return true;
    }
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(readableKey))).getSingleOrNull();
    return row?.value == 'true';
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
      await _deleteKeys();
      await _deleteCopy(previous);
      return;
    }
    final stored = await _storeCopy(path);
    await _writeKeys(
      path: stored?.path ?? path,
      systemReadable: stored?.systemReadable ?? false,
    );
    if (previous != null && previous != stored?.path) {
      await _deleteCopy(previous);
    }
  }

  @override
  Future<void> ensureSoundFileReady() async {
    // Файл, сохранённый до 48.1, лежит в приватных документах и системе
    // недоступен. Переносим его во внешнюю директорию, чтобы выбранный звук
    // заработал без повторного выбора файла владельцем.
    final stored = await soundFilePath();
    if (stored == null || await isSoundSystemReadable()) {
      return;
    }
    final moved = await _storeCopy(stored);
    // Внешнего хранилища нет (desktop) или копирование не вышло: файл остаётся
    // на месте со своим флагом, а канал уведомлений возьмёт встроенный сигнал.
    if (moved == null || !moved.systemReadable || moved.path == stored) {
      return;
    }
    await _writeKeys(path: moved.path, systemReadable: true);
    await _deleteCopy(stored);
  }

  /// Пишет ключи файла и его читаемости системным процессом.
  ///
  /// Обе записи — в одной транзакции: падение между ними оставило бы файл
  /// прописанным, но помеченным недоступным, и канал уведомлений молча ушёл бы
  /// на встроенный сигнал при наличии системо-доступного файла (48.1).
  Future<void> _writeKeys({
    required String path,
    required bool systemReadable,
  }) async {
    await _db.transaction(() async {
      await _db
          .into(_db.appMeta)
          .insertOnConflictUpdate(
            AppMetaCompanion.insert(key: fileKey, value: Value(path)),
          );
      await _db
          .into(_db.appMeta)
          .insertOnConflictUpdate(
            AppMetaCompanion.insert(
              key: readableKey,
              value: Value(systemReadable.toString()),
            ),
          );
    });
  }

  /// Удаляет ключи файла и его читаемости.
  Future<void> _deleteKeys() async {
    await (_db.delete(
      _db.appMeta,
    )..where((t) => t.key.isIn([fileKey, readableKey]))).go();
  }

  /// Копирует [path] в постоянное хранилище приложения.
  ///
  /// Сначала — во внешнюю директорию, системе читаемую (только там звук
  /// канала уведомлений реально звучит выбранным файлом, задача 48.1), при её
  /// недоступности — в приватные документы.
  ///
  /// Возвращает `null`, если копирование не удалось — тогда сохраняется исходный
  /// путь (как это делает настройка звука таймеров), чтобы выбор не терялся.
  Future<_StoredSound?> _storeCopy(String path) async {
    final source = File(path);
    if (!await source.exists()) {
      return null;
    }
    final external = await _copyInto(source, await _externalDirOrNull());
    if (external != null) {
      return _StoredSound(external, systemReadable: true);
    }
    final documents = await _copyInto(source, await _documentsDirOrNull());
    if (documents != null) {
      return _StoredSound(documents, systemReadable: false);
    }
    return null;
  }

  /// Копирует [source] в [dir]/`subDir`; null, если каталог недоступен или
  /// копирование не удалось.
  ///
  /// Если файл уже лежит по нужному пути, копирование пропускается: `copy` в
  /// тот же файл его **обнуляет** (открывает на запись и читает сам из себя).
  /// Случай не экзотический — `ensureSoundFileReady` вызывается при каждом
  /// старте, и без внешнего хранилища путь совпадает с текущим.
  Future<String?> _copyInto(File source, Directory? dir) async {
    if (dir == null) {
      return null;
    }
    try {
      final target = Directory(p.join(dir.path, subDir));
      await target.create(recursive: true);
      final file = File(p.join(target.path, p.basename(source.path)));
      if (p.equals(file.path, source.path)) {
        return file.path;
      }
      await source.copy(file.path);
      return file.path;
    } on FileSystemException {
      return null;
    }
  }

  /// Удаляет ранее скопированный файл (копии лежат только в наших папках).
  Future<void> _deleteCopy(String? path) async {
    if (path == null) {
      return;
    }
    for (final dir in [
      await _externalDirOrNull(),
      await _documentsDirOrNull(),
    ]) {
      if (dir == null || !p.isWithin(p.join(dir.path, subDir), path)) {
        continue;
      }
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // Недоступный кэш или удалённый пользователем файл — не ошибка.
      }
      return;
    }
  }

  Future<Directory?> _externalDirOrNull() async {
    try {
      return await _externalDirectoryProvider();
    } on FileSystemException {
      return null;
    } on UnsupportedError {
      // Внешнего хранилища нет (desktop) — копируем в документы.
      return null;
    } on MissingPluginException {
      // Платформенный канал не зарегистрирован (тесты) — копируем в документы.
      return null;
    } on PlatformException {
      // Платформенный канал ответил ошибкой: метод зовётся на каждом старте
      // приложения, и исключение ушло бы в инициализацию.
      return null;
    }
  }

  Future<Directory?> _documentsDirOrNull() async {
    try {
      return await _directoryProvider();
    } on FileSystemException {
      return null;
    }
  }

  static Future<Directory> _defaultDirectoryProvider() =>
      getApplicationDocumentsDirectory();

  static Future<Directory?> _defaultExternalDirectoryProvider() async {
    // Внешней директории нет ни на desktop, ни без плагина — вызывать её там
    // незачем, поэтому ограничиваемся Android явно.
    if (!Platform.isAndroid) {
      return null;
    }
    final dirs = await getExternalStorageDirectories();
    return (dirs == null || dirs.isEmpty) ? null : dirs.first;
  }
}

/// Скопированный файл и ответ на вопрос, прочитает ли его системный процесс.
class _StoredSound {
  const _StoredSound(this.path, {required this.systemReadable});

  final String path;
  final bool systemReadable;
}
