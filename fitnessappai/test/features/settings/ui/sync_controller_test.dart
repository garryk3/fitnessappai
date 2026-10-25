// ignore_for_file: type=lint
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:fitnessappai/app/bootstrap.dart';
import 'package:fitnessappai/features/settings/ui/sync_controller.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';

class _FakeSyncService implements SyncService {
  _FakeSyncService({this.importError});

  final SyncValidationException? importError;

  @override
  Future<String> export() async => 'backup.sqlite';

  @override
  Future<void> import(String sourcePath) async {
    final error = importError;
    if (error != null) {
      throw error;
    }
  }
}

void main() {
  late SyncController controller;

  test('импорт файла-не-БД показывает причину без краха', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(
        importError: const SyncValidationException(
          SyncValidationError.notADatabase,
        ),
      ),
      pickFile: () async => 'random.sqlite',
    );

    final result = await controller.importDatabase();

    expect(result, isFalse);
    expect(controller.hasError.value, isTrue);
    // Статус локализуется на стороне экрана — контроллер несёт только вид.
    expect(controller.status.value, isNull);
    expect(
      controller.importValidationError.value?.reason,
      SyncValidationError.notADatabase,
    );
    expect(controller.isBusy.value, isFalse);
  });

  test('импорт некорректной версии схемы фиксирует причину и версии', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(
        importError: const SyncValidationException(
          SyncValidationError.schemaNewer,
          schemaVersion: 99,
          installedVersion: 6,
        ),
      ),
      pickFile: () async => 'old.sqlite',
    );

    final result = await controller.importDatabase();

    expect(result, isFalse);
    expect(controller.hasError.value, isTrue);
    expect(controller.status.value, isNull);
    final error = controller.importValidationError.value;
    expect(error?.reason, SyncValidationError.schemaNewer);
    expect(error?.schemaVersion, 99);
    expect(error?.installedVersion, 6);
  });

  test('успешный импорт не показывает ошибку', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      pickFile: () async => 'good.sqlite',
    );

    final result = await controller.importDatabase();

    expect(result, isTrue);
    expect(controller.hasError.value, isFalse);
    expect(controller.status.value?.kind, SyncStatusKind.importDone);
    expect(controller.importValidationError.value, isNull);
  });

  test('отмена выбора файла ничего не делает', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      pickFile: () async => null,
    );

    final result = await controller.importDatabase();

    expect(result, isFalse);
    expect(controller.hasError.value, isFalse);
    expect(controller.status.value, isNull);
  });

  test(
    'дефолтный клирер при успехе сбрасывает restoredCheckpoint и файл (57.2)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final tempDir = await Directory.systemTemp.createTemp('ckpt_clear');
      final original = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
      addTearDown(() {
        PathProviderPlatform.instance = original;
        return tempDir.delete(recursive: true);
      });

      final checkpoint = _dummyCheckpoint();
      await checkpoint.save();
      restoredCheckpoint = checkpoint;

      controller = SyncController(
        syncServiceFactory: () => _FakeSyncService(),
        pickFile: () async => 'good.sqlite',
      );

      final result = await controller.importDatabase();

      expect(result, isTrue);
      expect(restoredCheckpoint, isNull);
      final remaining = Directory(tempDir.path).listSync().whereType<File>();
      expect(
        remaining.any((f) => f.path.endsWith('workout_checkpoint.json')),
        isFalse,
      );
    },
  );

  test('экспорт сохраняет файл в файловую систему', () async {
    String? savedTo;
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      saveFile: (path, {dialogTitle}) async {
        savedTo = path;
        return true;
      },
    );

    final result = await controller.exportDatabaseToFile();

    expect(result, isTrue);
    expect(savedTo, 'backup.sqlite');
    expect(controller.hasError.value, isFalse);
    expect(controller.status.value?.kind, SyncStatusKind.exportSaved);
  });

  test('отмена сохранения файла не считается ошибкой', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      saveFile: (_, {dialogTitle}) async => false,
    );

    final result = await controller.exportDatabaseToFile();

    expect(result, isFalse);
    expect(controller.hasError.value, isFalse);
    expect(controller.status.value?.kind, SyncStatusKind.saveCancelled);
  });

  test('экспорт в файлы перехватывает ошибку сохранения', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      saveFile: (_, {dialogTitle}) async => throw UnimplementedError('saving'),
    );

    final result = await controller.exportDatabaseToFile();

    expect(result, isFalse);
    expect(controller.hasError.value, isTrue);
    expect(controller.status.value?.kind, SyncStatusKind.exportFailed);
    expect(controller.status.value?.error, isA<UnimplementedError>());
  });

  test('успешный экспорт фиксирует статус отправки', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      shareFile: (_) async {},
    );

    final result = await controller.exportDatabase();

    expect(result, isTrue);
    expect(controller.status.value?.kind, SyncStatusKind.exportShared);
    expect(controller.hasError.value, isFalse);
  });
}

WorkoutCheckpoint _dummyCheckpoint() => WorkoutCheckpoint(
  programDayId: 1,
  exerciseIndex: 0,
  currentSet: 1,
  completedSets: 0,
  resultsJson: '[]',
  startedAt: DateTime.now(),
  programName: 'Силовая',
  dayIndex: 0,
);

/// Подставник path_provider: documents → temp-каталог теста.
class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}
