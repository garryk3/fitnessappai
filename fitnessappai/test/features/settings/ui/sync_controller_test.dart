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

  test('импорт файла-не-БД показывает сообщение без краха', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(
        importError: const SyncValidationException(
          'Файл не является базой данных FitnessAppAI',
        ),
      ),
      pickFile: () async => 'random.sqlite',
    );

    final result = await controller.importDatabase();

    expect(result, isFalse);
    expect(controller.hasError.value, isTrue);
    expect(
      controller.statusText.value,
      'Файл не является базой данных FitnessAppAI',
    );
    expect(controller.isBusy.value, isFalse);
  });

  test('импорт некорректной версии схемы показывает сообщение', () async {
    controller = SyncController(
      syncServiceFactory: () => _FakeSyncService(
        importError: const SyncValidationException(
          'Несовместимая версия схемы: 99 (ожидается 6)',
        ),
      ),
      pickFile: () async => 'old.sqlite',
    );

    final result = await controller.importDatabase();

    expect(result, isFalse);
    expect(controller.hasError.value, isTrue);
    expect(
      controller.statusText.value,
      'Несовместимая версия схемы: 99 (ожидается 6)',
    );
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
}
