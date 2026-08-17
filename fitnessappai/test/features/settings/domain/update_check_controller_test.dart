import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/features/settings/domain/update_check_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';

class _FakeUpdateService implements UpdateService {
  _FakeUpdateService({this.release});

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

void main() {
  late _FakeUpdateService service;
  late String? openedUrl;
  const current = '1.0.0';

  UpdateCheckController buildController({String? version, String? latestTag}) {
    service = _FakeUpdateService(
      release: latestTag == null
          ? null
          : ReleaseInfo(
              tagName: latestTag,
              apkUrl: 'https://example.com/app.apk',
            ),
    );
    openedUrl = null;
    return UpdateCheckController(
      service: service,
      loadVersion: () async => version ?? current,
      openRelease: (url) async => openedUrl = url,
    );
  }

  test('загрузка версии заполняет versionText', () async {
    final controller = buildController();
    await controller.loadVersion();
    expect(controller.versionText.value, '1.0.0');
  });

  test('новая версия релиза помечается как обновление', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(service.calls, 1);
    expect(controller.hasUpdate.value, isTrue);
    expect(controller.latestVersion.value, '1.1.0');
    expect(controller.statusText.value, 'Доступна новая версия 1.1.0');
    expect(controller.hasError.value, isFalse);
    expect(controller.isChecking.value, isFalse);
  });

  test('та же версия — обновление не требуется', () async {
    final controller = buildController(latestTag: 'v1.0.0');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasUpdate.value, isFalse);
    expect(controller.statusText.value, 'Установлена актуальная версия');
    expect(controller.hasError.value, isFalse);
  });

  test('старая версия релиза — обновление не требуется', () async {
    final controller = buildController(latestTag: 'v0.9.5');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasUpdate.value, isFalse);
    expect(controller.statusText.value, 'Установлена актуальная версия');
  });

  test('без релизов — ошибка с сообщением', () async {
    final controller = buildController(latestTag: null);
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasUpdate.value, isFalse);
    expect(controller.hasError.value, isTrue);
    expect(controller.statusText.value, 'Релизы ещё не опубликованы');
  });

  test('ошибка сети — статус ошибки', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    service.error = Exception('no internet');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasError.value, isTrue);
    expect(controller.hasUpdate.value, isFalse);
    expect(
      controller.statusText.value,
      'Ошибка проверки обновления: Exception: no internet',
    );
  });

  test('повторный вызов во время проверки игнорируется', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    await controller.loadVersion();

    final first = controller.checkForUpdates();
    final second = controller.checkForUpdates();
    await Future.wait([first, second]);

    expect(service.calls, 1);
  });

  test('нечисловая версия релиза не помечается как обновление', () async {
    final controller = buildController(latestTag: 'beta');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasUpdate.value, isFalse);
  });

  test('openUpdate открывает ссылку на APK', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    await controller.loadVersion();
    await controller.checkForUpdates();

    await controller.openUpdate();

    expect(openedUrl, 'https://example.com/app.apk');
  });

  test('openUpdate без найденного релиза ничего не делает', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    await controller.openUpdate();
    expect(openedUrl, isNull);
  });
}
