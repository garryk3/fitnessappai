// ignore_for_file: type=lint
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/features/settings/data/auto_update_repository.dart';
import 'package:fitnessappai/features/settings/domain/auto_update_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_check_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';

class _FakeUpdateService implements UpdateService {
  _FakeUpdateService({this.release, this.error});

  ReleaseInfo? release;
  Object? error;
  int calls = 0;

  @override
  Future<ReleaseInfo?> fetchLatestRelease() async {
    calls++;
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return release;
  }
}

class _StubRepository implements AutoUpdateRepository {
  bool value = false;

  @override
  Future<bool> read() async => value;

  @override
  Future<void> write(bool value) async {
    this.value = value;
  }
}

AutoUpdateController buildController(
  _FakeUpdateService service, {
  AutoUpdateRepository? repository,
}) => AutoUpdateController(
  repository: repository ?? _StubRepository(),
  service: service,
  loadVersion: () async => '1.0.0',
);

void main() {
  test('флаг выключен — проверка не выполняется', () async {
    final service = _FakeUpdateService(release: ReleaseInfo(tagName: 'v1.1.0'));
    final controller = buildController(service);

    expect(await controller.runCheck(), isNull);
    expect(service.calls, 0);
  });

  test('флаг включён и релиз новее — проверка возвращает версию', () async {
    final service = _FakeUpdateService(release: ReleaseInfo(tagName: 'v1.1.0'));
    final controller = buildController(service);
    await controller.setEnabled(true);

    final check = await controller.runCheck();

    expect(check, isNotNull);
    expect(check!.version, '1.1.0');
    expect(service.calls, 1);
  });

  test('релиз не новее установленной версии — null', () async {
    final service = _FakeUpdateService(release: ReleaseInfo(tagName: 'v1.0.0'));
    final controller = buildController(service);
    await controller.setEnabled(true);

    expect(await controller.runCheck(), isNull);
  });

  test('релизов нет — null', () async {
    final service = _FakeUpdateService(release: null);
    final controller = buildController(service);
    await controller.setEnabled(true);

    expect(await controller.runCheck(), isNull);
  });

  test(
    'ошибка сети — null без исключения (молчаливый пропуск, 64.1)',
    () async {
      final service = _FakeUpdateService(
        release: ReleaseInfo(tagName: 'v1.1.0'),
        error: Exception('network down'),
      );
      final controller = buildController(service);
      await controller.setEnabled(true);

      expect(await controller.runCheck(), isNull);
    },
  );

  test('consume сбрасывает флаг — повторная проверка не выполняется', () async {
    final service = _FakeUpdateService(release: ReleaseInfo(tagName: 'v1.1.0'));
    final repository = _StubRepository();
    final controller = buildController(service, repository: repository);
    await controller.setEnabled(true);

    await controller.consume();

    expect(repository.value, isFalse);
    expect(controller.autoUpdateEnabled.value, isFalse);
    expect(await controller.runCheck(), isNull);
    expect(service.calls, 0);
  });

  test('isNewer сравнивает семантические версии (фасад 64.1)', () {
    expect(UpdateCheckController.isNewer('v1.1.0', '1.0.9'), isTrue);
    expect(UpdateCheckController.isNewer('v1.0.0', '1.0.0'), isFalse);
    expect(UpdateCheckController.isNewer('v2.0.0', '1.9.9'), isTrue);
  });
}
