import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';

typedef SyncServiceFactory = SyncService Function();
typedef SyncFilePicker = Future<String?> Function();
typedef SyncFileShare = Future<void> Function(String filePath);

/// Возвращает `true`, если файл сохранён пользователем, `false` — при отмене.
typedef SyncFileSave = Future<bool> Function(String filePath);

/// Управляет экраном «Синхронизация»: экспорт, импорт и статус операции.
class SyncController {
  SyncController({
    SyncServiceFactory? syncServiceFactory,
    SyncFilePicker? pickFile,
    SyncFileShare? shareFile,
    SyncFileSave? saveFile,
  }) : _service = syncServiceFactory ?? _defaultService,
       _pickFile = pickFile ?? _defaultPick,
       _shareFile = shareFile ?? _defaultShare,
       _saveFile = saveFile ?? _defaultSave;

  final SyncServiceFactory _service;
  final SyncFilePicker _pickFile;
  final SyncFileShare _shareFile;
  final SyncFileSave _saveFile;

  /// Сервис берётся заново при каждом действии, т.к. после импорта БД
  /// контейнер DI пересоздаётся.
  SyncService get _syncService => _service();

  final Signal<bool> isBusy = Signal(false);
  final Signal<String?> statusText = Signal(null);
  final Signal<bool> hasError = Signal(false);

  /// Экспортирует копию БД и делится файлом.
  Future<bool> exportDatabase() async {
    if (isBusy.value) {
      return false;
    }
    isBusy.value = true;
    try {
      final path = await _syncService.export();
      await _shareFile(path);
      statusText.value = 'Резервная копия создана и отправлена';
      hasError.value = false;
      return true;
    } catch (error) {
      statusText.value = _operationError('Ошибка экспорта', error);
      hasError.value = true;
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Экспортирует копию БД и сохраняет её в файловую систему.
  Future<bool> exportDatabaseToFile() async {
    if (isBusy.value) {
      return false;
    }
    isBusy.value = true;
    try {
      final path = await _syncService.export();
      final saved = await _saveFile(path);
      statusText.value = saved
          ? 'Резервная копия сохранена'
          : 'Сохранение отменено';
      hasError.value = false;
      return saved;
    } catch (error) {
      statusText.value = _operationError('Ошибка экспорта', error);
      hasError.value = true;
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Импортирует БД из выбранного файла. Возвращает `true` при успехе.
  Future<bool> importDatabase() async {
    if (isBusy.value) {
      return false;
    }
    String? source;
    try {
      source = await _pickFile();
    } catch (error) {
      statusText.value = _operationError('Ошибка импорта', error);
      hasError.value = true;
      return false;
    }
    if (source == null) {
      return false;
    }
    isBusy.value = true;
    try {
      await _syncService.import(source);
      statusText.value = 'База данных импортирована';
      hasError.value = false;
      return true;
    } on SyncValidationException catch (error) {
      statusText.value = error.message;
      hasError.value = true;
      return false;
    } catch (error) {
      statusText.value = _operationError('Ошибка импорта', error);
      hasError.value = true;
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Текст ошибки операции: для платформенных «нет поддержки» — человекочитаемое
  /// сообщение, иначе — исходная ошибка.
  static String _operationError(String action, Object error) {
    if (error is UnimplementedError || error is MissingPluginException) {
      return '$action: операция недоступна на этой платформе';
    }
    return '$action: $error';
  }

  static SyncService _defaultService() => locator.get<SyncService>();

  static Future<String?> _defaultPick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db', 'sqlite3'],
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return result.files.single.path;
  }

  static Future<void> _defaultShare(String filePath) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }

  static const _channel = MethodChannel('com.example.fitnessappai/file_saver');

  static Future<bool> _defaultSave(String filePath) async {
    if (!Platform.isAndroid) {
      // На desktop — обычный saveFile через file_picker.
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранение резервной копии',
        fileName: 'fitnessappai_backup.sqlite',
      );
      if (destination == null) {
        return false;
      }
      await File(filePath).copy(destination);
      return true;
    }
    // На Android используем SAF (Intent.ACTION_CREATE_DOCUMENT) через
    // MethodChannel, т.к. FilePicker.saveFile возвращает content:// URI,
    // с которым File.copy() не работает.
    try {
      final result = await _channel.invokeMethod<bool>(
        'saveFile',
        <String, dynamic>{
          'sourcePath': filePath,
          'fileName': 'fitnessappai_backup.sqlite',
        },
      );
      return result == true;
    } on MissingPluginException {
      // Плагин не зарегистрирован (тесты) — fallback на share.
      await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
      return true;
    }
  }
}
