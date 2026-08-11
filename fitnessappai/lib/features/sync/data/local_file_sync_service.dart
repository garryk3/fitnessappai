import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';

/// Локальная синхронизация через файл SQLite.
///
/// Экспорт — `VACUUM INTO` копии активной БД в её каталог. Импорт —
/// копия выбранного файла во временную директорию, проверка целостности
/// и версии схемы, затем закрытие текущей БД, замена файла и перезапуск
/// приложения через [onImported].
class LocalFileSyncService implements SyncService {
  LocalFileSyncService({
    required this.database,
    required this.databaseFilePath,
    required this.temporaryDirectoryPath,
    required this.onImported,
  });

  /// Активная БД приложения (закрывается перед заменой файла).
  final AppDatabase database;

  /// Путь к файлу активной БД.
  final Future<String> Function() databaseFilePath;

  /// Каталог для временного файла при импорте.
  final Future<String> Function() temporaryDirectoryPath;

  /// Вызывается после успешной замены файла: приложение перерегистрирует
  /// сервисы, заливает справочники и восстанавливает напоминания.
  final Future<void> Function() onImported;

  static const String _exportFileName = 'fitnessappai_export.sqlite';
  static const String _importFileName = 'fitnessappai_import.sqlite';

  @override
  Future<String> export() async {
    final path = await databaseFilePath();
    final exportPath = p.join(p.dirname(path), _exportFileName);
    final file = File(exportPath);
    if (await file.exists()) {
      await file.delete();
    }
    final quoted = exportPath.replaceAll("'", "''");
    await database.customStatement("VACUUM INTO '$quoted'");
    return exportPath;
  }

  @override
  Future<void> import(String sourcePath) async {
    final tempDir = await temporaryDirectoryPath();
    final tempPath = p.join(tempDir, _importFileName);
    await File(sourcePath).copy(tempPath);
    _validate(tempPath);

    final path = await databaseFilePath();
    await database.close();
    final current = File(path);
    if (await current.exists()) {
      await current.delete();
    }
    await File(tempPath).copy(path);
    await File(tempPath).delete();
    await onImported();
  }

  /// Проверяет, что файл является неповреждённой БД с поддерживаемой
  /// версией схемы.
  void _validate(String path) {
    final probe = sqlite.sqlite3.open(path);
    try {
      final integrity = probe
          .select('PRAGMA integrity_check')
          .map((row) => row['integrity_check'].toString())
          .toList();
      if (integrity.isEmpty || integrity.first != 'ok') {
        throw const SyncValidationException(
          'Файл повреждён и не может быть импортирован',
        );
      }
      final version =
          probe.select('PRAGMA user_version').single['user_version'] as int;
      if (version != appDatabaseSchemaVersion) {
        throw SyncValidationException(
          'Несовместимая версия схемы: $version (ожидается '
          '$appDatabaseSchemaVersion)',
        );
      }
    } on sqlite.SqliteException catch (error) {
      throw SyncValidationException(
        'Файл не является базой данных FitnessAppAI: ${error.message}',
      );
    } finally {
      probe.close();
    }
  }
}
