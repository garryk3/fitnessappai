// ignore_for_file: type=lint
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/features/settings/ui/sync_controller.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';

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
    // Текст локализуется на стороне экрана — контроллер несёт только причину.
    expect(controller.statusText.value, isNull);
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
    expect(controller.statusText.value, isNull);
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
    expect(controller.statusText.value, 'База данных импортирована');
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
    expect(controller.statusText.value, isNull);
  });

  test('экспорт сохраняет файл в файловую систему', () async {
    String? savedTo;
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      saveFile: (path) async {
        savedTo = path;
        return true;
      },
    );

    final result = await controller.exportDatabaseToFile();

    expect(result, isTrue);
    expect(savedTo, 'backup.sqlite');
    expect(controller.hasError.value, isFalse);
    expect(controller.statusText.value, 'Резервная копия сохранена');
  });

  test('отмена сохранения файла не считается ошибкой', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      saveFile: (_) async => false,
    );

    final result = await controller.exportDatabaseToFile();

    expect(result, isFalse);
    expect(controller.hasError.value, isFalse);
    expect(controller.statusText.value, 'Сохранение отменено');
  });

  test('экспорт в файлы перехватывает ошибку сохранения', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(),
      saveFile: (_) async => throw UnimplementedError('saving'),
    );

    final result = await controller.exportDatabaseToFile();

    expect(result, isFalse);
    expect(controller.hasError.value, isTrue);
    expect(
      controller.statusText.value,
      contains('операция недоступна на этой платформе'),
    );
  });
}
