import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';

typedef SyncServiceFactory = SyncService Function();
typedef SyncFilePicker = Future<String?> Function();
typedef SyncFileShare = Future<void> Function(String filePath);

/// Управляет экраном «Синхронизация»: экспорт, импорт и статус операции.
class SyncController {
  SyncController({
    SyncServiceFactory? syncServiceFactory,
    SyncFilePicker? pickFile,
    SyncFileShare? shareFile,
  }) : _service = syncServiceFactory ?? _defaultService,
       _pickFile = pickFile ?? _defaultPick,
       _shareFile = shareFile ?? _defaultShare;

  final SyncServiceFactory _service;
  final SyncFilePicker _pickFile;
  final SyncFileShare _shareFile;

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
    } on Exception catch (error) {
      statusText.value = 'Ошибка экспорта: $error';
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
    final source = await _pickFile();
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
    } on Exception catch (error) {
      statusText.value = 'Ошибка импорта: $error';
      hasError.value = true;
      return false;
    } finally {
      isBusy.value = false;
    }
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
}
