import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

typedef SyncServiceFactory = SyncService Function();
typedef SyncFilePicker = Future<String?> Function();
typedef SyncFileShare = Future<void> Function(String filePath);

/// Возвращает `true`, если файл сохранён пользователем, `false` — при отмене.
///
/// [dialogTitle] — локализованный заголовок системного диалога сохранения.
typedef SyncFileSave =
    Future<bool> Function(String filePath, {String? dialogTitle});

/// Вид статуса операции синхронизации (без текста).
///
/// Текст локализуется на стороне экрана (`syncStatusMessage`), контроллер
/// не хранит русские строки мимо `app_ru.arb`.
enum SyncStatusKind {
  /// Экспорт: копия создана и передана в шаринг.
  exportShared,

  /// Экспорт в файл: пользователь сохранил файл.
  exportSaved,

  /// Экспорт в файл: пользователь отменил сохранение.
  saveCancelled,

  /// Импорт завершён успешно.
  importDone,

  /// Ошибка экспорта (детали — в [SyncStatus.error]).
  exportFailed,

  /// Ошибка импорта (детали — в [SyncStatus.error]).
  importFailed,
}

/// Структурированный статус операции синхронизации.
///
/// Для ошибок несёт исходный объект ошибки — человекочитаемая деталь
/// составляется при локализации (`syncStatusMessage`).
class SyncStatus {
  const SyncStatus(this.kind, {this.error});

  final SyncStatusKind kind;

  /// Исходная ошибка (только для `*Failed`, иначе `null`).
  final Object? error;
}

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

  /// Последняя операция (структурированный статус): текст локализуется на
  /// стороне экрана (`syncStatusMessage`), контроллер хранит только вид.
  final Signal<SyncStatus?> status = Signal(null);
  final Signal<bool> hasError = Signal(false);

  /// Последняя ошибка валидации импорта (причина без текста): сообщение
  /// локализуется на стороне экрана (`syncValidationMessage`), контроллер
  /// не хранит русские строки мимо `app_ru.arb`.
  final Signal<SyncValidationException?> importValidationError = Signal(null);

  /// Единая точка обновления статуса: [next] — для невалидационных операций,
  /// [validationError] — для ошибок импорта (тогда статус не показывается).
  void _setStatus(
    SyncStatus? next, {
    required bool error,
    SyncValidationException? validationError,
  }) {
    status.value = next;
    hasError.value = error;
    importValidationError.value = validationError;
  }

  /// Экспортирует копию БД и делится файлом.
  Future<bool> exportDatabase() async {
    if (isBusy.value) {
      return false;
    }
    isBusy.value = true;
    try {
      final path = await _syncService.export();
      await _shareFile(path);
      _setStatus(const SyncStatus(SyncStatusKind.exportShared), error: false);
      return true;
    } catch (error) {
      _setStatus(
        SyncStatus(SyncStatusKind.exportFailed, error: error),
        error: true,
      );
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Экспортирует копию БД и сохраняет её в файловую систему.
  ///
  /// [dialogTitle] — заголовок системного диалога сохранения (локализуется
  /// на стороне экрана).
  Future<bool> exportDatabaseToFile({String? dialogTitle}) async {
    if (isBusy.value) {
      return false;
    }
    isBusy.value = true;
    try {
      final path = await _syncService.export();
      final saved = await _saveFile(path, dialogTitle: dialogTitle);
      _setStatus(
        SyncStatus(
          saved ? SyncStatusKind.exportSaved : SyncStatusKind.saveCancelled,
        ),
        error: false,
      );
      return saved;
    } catch (error) {
      _setStatus(
        SyncStatus(SyncStatusKind.exportFailed, error: error),
        error: true,
      );
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
      _setStatus(
        SyncStatus(SyncStatusKind.importFailed, error: error),
        error: true,
      );
      return false;
    }
    if (source == null) {
      return false;
    }
    isBusy.value = true;
    try {
      await _syncService.import(source);
      _setStatus(const SyncStatus(SyncStatusKind.importDone), error: false);
      return true;
    } on SyncValidationException catch (error) {
      _setStatus(null, error: true, validationError: error);
      return false;
    } catch (error) {
      _setStatus(
        SyncStatus(SyncStatusKind.importFailed, error: error),
        error: true,
      );
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  static SyncService _defaultService() => locator.get<SyncService>();

  static Future<String?> _defaultPick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['sqlite', 'db', 'sqlite3'],
      );
      if (result == null || result.files.isEmpty) {
        return null;
      }
      return result.files.single.path;
    } on PlatformException {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) {
        return null;
      }
      return result.files.single.path;
    }
  }

  static Future<void> _defaultShare(String filePath) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }

  static const _channel = MethodChannel('com.example.fitnessappai/file_saver');

  static Future<bool> _defaultSave(
    String filePath, {
    String? dialogTitle,
  }) async {
    if (!Platform.isAndroid) {
      // На desktop — обычный saveFile через file_picker.
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
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

/// Локализованное сообщение статуса операции синхронизации.
///
/// Тексты — в `app_ru.arb` (`syncStatus*`, `syncError*`); контроллер хранит
/// только вид статуса и исходный объект ошибки.
String syncStatusMessage(AppLocalizations l10n, SyncStatus status) =>
    switch (status.kind) {
      SyncStatusKind.exportShared => l10n.syncStatusExportShared,
      SyncStatusKind.exportSaved => l10n.syncStatusExportSaved,
      SyncStatusKind.saveCancelled => l10n.syncStatusSaveCancelled,
      SyncStatusKind.importDone => l10n.syncImportSuccess,
      SyncStatusKind.exportFailed =>
        '${l10n.syncErrorExport}: ${_syncErrorDetail(l10n, status.error)}',
      SyncStatusKind.importFailed =>
        '${l10n.syncErrorImport}: ${_syncErrorDetail(l10n, status.error)}',
    };

/// Деталь ошибки операции: для платформенных «нет поддержки» — человекочитаемое
/// сообщение, иначе — исходная ошибка.
String _syncErrorDetail(AppLocalizations l10n, Object? error) {
  if (error is UnimplementedError || error is MissingPluginException) {
    return l10n.syncErrorUnavailableOnPlatform;
  }
  if (error is PlatformException) {
    return l10n.syncErrorFilePickerUnavailable;
  }
  return '$error';
}

/// Локализованное сообщение об ошибке валидации импорта.
///
/// Тексты — в `app_ru.arb` (`syncError*`); доменный слой хранит только причину.
String syncValidationMessage(
  AppLocalizations l10n,
  SyncValidationException error,
) => switch (error.reason) {
  SyncValidationError.notADatabase => l10n.syncErrorNotDatabase,
  SyncValidationError.corrupted => l10n.syncErrorCorrupted,
  SyncValidationError.schemaNewer => l10n.syncErrorSchemaNewer(
    error.installedVersion ?? 0,
    error.schemaVersion ?? 0,
  ),
};
