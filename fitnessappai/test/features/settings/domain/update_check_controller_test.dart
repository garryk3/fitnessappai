import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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

/// Поддельная платформа url_launcher: [canLaunchResult] управляет
/// результатом `canLaunchUrl`.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  _FakeUrlLauncherPlatform(this.canLaunchResult);

  final bool canLaunchResult;
  String? launchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    return true;
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

  test('ошибка сети — понятный текст ошибки', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    service.error = SocketException('no internet');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasError.value, isTrue);
    expect(controller.hasUpdate.value, isFalse);
    expect(
      controller.statusText.value,
      'Ошибка проверки версии. Проверьте подключение к интернету.',
    );
  });

  test('HttpException — понятный текст ошибки', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    service.error = HttpException('bad response');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasError.value, isTrue);
    expect(
      controller.statusText.value,
      'Ошибка проверки версии. Проверьте подключение к интернету.',
    );
  });

  test('прочая ошибка — общий текст ошибки', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    service.error = Exception('unknown');
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasError.value, isTrue);
    expect(controller.statusText.value, 'Ошибка проверки версии.');
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

  test('openUpdate при ошибке APK открывает запасную страницу релиза', () async {
    final calls = <String>[];
    final controller = UpdateCheckController(
      service: _FakeUpdateService(
        release: const ReleaseInfo(
          tagName: 'v1.1.0',
          apkUrl: 'https://example.com/app.apk',
          htmlUrl: 'https://example.com/release/1.1.0',
        ),
      ),
      loadVersion: () async => '1.0.0',
      openRelease: (url) async {
        if (url.contains('app.apk')) {
          throw Exception('ACTIVITY_NOT_FOUND');
        }
        calls.add(url);
      },
    );
    await controller.loadVersion();
    await controller.checkForUpdates();

    await controller.openUpdate();

    expect(calls, ['https://example.com/release/1.1.0']);
    expect(controller.hasError.value, isFalse);
    expect(controller.statusText.value, 'Доступна новая версия 1.1.0');
  });

  test('openUpdate при ошибке APK и страницы релиза показывает ошибку', () async {
    final controller = UpdateCheckController(
      service: _FakeUpdateService(
        release: const ReleaseInfo(
          tagName: 'v1.1.0',
          apkUrl: 'https://example.com/app.apk',
          htmlUrl: 'https://example.com/release/1.1.0',
        ),
      ),
      loadVersion: () async => '1.0.0',
      openRelease: (_) async => throw Exception('ACTIVITY_NOT_FOUND'),
    );
    await controller.loadVersion();
    await controller.checkForUpdates();

    await controller.openUpdate();

    expect(controller.hasError.value, isTrue);
    expect(
      controller.statusText.value,
      'Не удалось открыть ссылку на обновление.',
    );
  });

  test('openUpdate без найденного релиза ничего не делает', () async {
    final controller = buildController(latestTag: 'v1.1.0');
    await controller.openUpdate();
    expect(openedUrl, isNull);
  });

  test('beta-суффикс в теге релиза корректно сравнивается', () async {
    final controller = buildController(
      version: '1.0.2-beta',
      latestTag: 'v1.0.3-beta',
    );
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasUpdate.value, isTrue);
    expect(controller.latestVersion.value, '1.0.3');
  });

  test('beta-суффикс в текущей версии корректно сравнивается', () async {
    final controller = buildController(
      version: '1.0.0-beta',
      latestTag: 'v1.1.0',
    );
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasUpdate.value, isTrue);
    expect(controller.latestVersion.value, '1.1.0');
  });

  test('одинаковые версии с beta — обновление не требуется', () async {
    final controller = buildController(
      version: '1.0.3-beta',
      latestTag: 'v1.0.3-beta',
    );
    await controller.loadVersion();

    await controller.checkForUpdates();

    expect(controller.hasUpdate.value, isFalse);
  });

  test('можно открыть — реальный launchUrl вызывается с https-ссылкой', () async {
    const url = 'https://example.com/app.apk';
    final controller = UpdateCheckController(
      service: _FakeUpdateService(
        release: const ReleaseInfo(tagName: 'v1.1.0', apkUrl: url),
      ),
      loadVersion: () async => '1.0.0',
    );
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _FakeUrlLauncherPlatform(true);
    addTearDown(() => UrlLauncherPlatform.instance = previous);
    await controller.loadVersion();
    await controller.checkForUpdates();

    await controller.openUpdate();

    final fake = UrlLauncherPlatform.instance as _FakeUrlLauncherPlatform;
    expect(fake.launchedUrl, url);
    expect(controller.hasError.value, isFalse);
  });

  test('нечем открыть (canLaunch=false) — статус ошибки, а не тишина', () async {
    final controller = UpdateCheckController(
      service: _FakeUpdateService(
        release: const ReleaseInfo(
          tagName: 'v1.1.0',
          apkUrl: 'https://example.com/app.apk',
        ),
      ),
      loadVersion: () async => '1.0.0',
    );
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _FakeUrlLauncherPlatform(false);
    addTearDown(() => UrlLauncherPlatform.instance = previous);
    await controller.loadVersion();
    await controller.checkForUpdates();

    await controller.openUpdate();

    final fake = UrlLauncherPlatform.instance as _FakeUrlLauncherPlatform;
    expect(fake.launchedUrl, isNull);
    expect(controller.hasError.value, isTrue);
    expect(
      controller.statusText.value,
      'Не удалось открыть ссылку на обновление.',
    );
  });
}
