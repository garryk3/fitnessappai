// ignore_for_file: type=lint
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/splash_gate.dart';
import 'package:fitnessappai/features/settings/data/apk_downloader.dart';
import 'package:fitnessappai/features/settings/data/apk_installer.dart';
import 'package:fitnessappai/features/settings/data/auto_update_repository.dart';
import 'package:fitnessappai/features/settings/domain/auto_update_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';

void main() {
  testWidgets('показывает заставку во время инициализации', (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      SplashGate(
        bootstrap: () => completer.future,
        homeBuilder: () =>
            const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
        splashBody: const ColoredBox(
          color: Colors.black,
          child: Center(child: Text('Заставка')),
        ),
      ),
    );

    expect(find.text('Заставка'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);

    completer.complete();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Главный экран'), findsOneWidget);
    expect(find.text('Заставка'), findsNothing);
  });

  testWidgets('заставка исчезает после завершения инициализации', (
    tester,
  ) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      SplashGate(
        bootstrap: () => completer.future,
        homeBuilder: () =>
            const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
        splashBody: const ColoredBox(
          color: Colors.black,
          child: Center(child: Text('Заставка')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Заставка'), findsOneWidget);

    completer.complete();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Заставка'), findsNothing);
    expect(find.text('Главный экран'), findsOneWidget);
  });

  testWidgets('сплэш держится минимум 2 секунды до исчезновения', (
    tester,
  ) async {
    await tester.pumpWidget(
      SplashGate(
        bootstrap: () async {},
        homeBuilder: () =>
            const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
        splashBody: const ColoredBox(
          color: Colors.black,
          child: Center(child: Text('Заставка')),
        ),
      ),
    );

    // Быстрая инициализация уже завершилась; через 1 секунду заставка ещё
    // должна быть видна.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Заставка'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);

    // После полных 2 секунд начинается плавный переход к главному экрану.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Главный экран'), findsOneWidget);
    expect(find.text('Заставка'), findsNothing);
    expect(find.text('Главный экран'), findsOneWidget);
    expect(find.text('Заставка'), findsNothing);
  });

  testWidgets('флаг включён и есть новая версия — модалка на заставке '
      '(64.1)', (tester) async {
    final repository = _StubAutoUpdateRepository();
    final autoUpdate = AutoUpdateController(
      repository: repository,
      service: _FakeUpdateService(
        release: ReleaseInfo(
          tagName: 'v1.1.0',
          htmlUrl:
              'https://github.com/garryk3/fitnessappai/releases/tag/v1.1.0',
          apkUrl:
              'https://github.com/garryk3/fitnessappai/releases/download/v1.1.0/app.apk',
        ),
      ),
      loadVersion: () async => '1.0.0',
    );
    await autoUpdate.setEnabled(true);
    final downloader = _RecordingDownloader();
    final installer = _RecordingInstaller();

    await pumpSplash(
      tester,
      autoUpdate: autoUpdate,
      downloader: downloader,
      installer: installer,
    );

    // Модалка вместо перехода в приложение.
    expect(find.text('Доступна новая версия'), findsOneWidget);
    expect(find.text('Версия 1.1.0 доступна для скачивания.'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);

    await tester.tap(find.text('Обновить'));
    // Спиннер диалога «Загрузка обновления» анимируется постоянно —
    // pumpAndSettle никогда не завершился бы; продвигаем фазы явно.
    // Спиннер диалога «Загрузка обновления» анимируется постоянно —
    // pumpAndSettle никогда не завершился бы; продвигаем фазы явно:
    // закрытие модалки → диалог загрузки → завершение операции →
    // сброс флага → fade заставки.
    await tester.pump(); // закрытие модалки + диалог загрузки
    await tester.pump(const Duration(milliseconds: 100)); // загрузка+установка
    await tester.pump(const Duration(milliseconds: 300)); // закрытие диалога
    await tester.pump(const Duration(seconds: 2)); // consume + fade
    // Скачивание + установка запущены; флаг сброшен — проверка
    // не повторится на следующих запусках.
    expect(downloader.downloadedUrls, hasLength(1));
    expect(installer.installedPaths, ['/tmp/update.apk']);
    expect(repository.value, isFalse);
    // Приложение открылось после установки.
    expect(find.text('Главный экран'), findsOneWidget);
  });

  testWidgets('обновления нет — переход в приложение без модалки (64.1)', (
    tester,
  ) async {
    final repository = _StubAutoUpdateRepository();
    final autoUpdate = AutoUpdateController(
      repository: repository,
      service: _FakeUpdateService(release: ReleaseInfo(tagName: 'v1.0.0')),
      loadVersion: () async => '1.0.0',
    );
    await autoUpdate.setEnabled(true);

    await pumpSplash(tester, autoUpdate: autoUpdate);

    expect(find.text('Доступна новая версия'), findsNothing);
    expect(find.text('Главный экран'), findsOneWidget);
    // Флаг не сбрасывается: проверка прошла, но повода сбрасывать нет.
    expect(repository.value, isTrue);
  });

  testWidgets('флаг выключен — обычный переход в приложение (64.1)', (
    tester,
  ) async {
    final autoUpdate = AutoUpdateController(
      repository: _StubAutoUpdateRepository(),
      service: _FakeUpdateService(
        release: ReleaseInfo(
          tagName: 'v1.1.0',
          htmlUrl:
              'https://github.com/garryk3/fitnessappai/releases/tag/v1.1.0',
          apkUrl:
              'https://github.com/garryk3/fitnessappai/releases/download/v1.1.0/app.apk',
        ),
      ),
      loadVersion: () async => '1.0.0',
    );

    await pumpSplash(tester, autoUpdate: autoUpdate);

    expect(find.text('Доступна новая версия'), findsNothing);
    expect(find.text('Главный экран'), findsOneWidget);
  });

  testWidgets('ошибка сети — молча: без диалога отказа, приложение открыто '
      '(64.1, решение владельца)', (tester) async {
    final repository = _StubAutoUpdateRepository();
    final autoUpdate = AutoUpdateController(
      repository: repository,
      service: _FakeUpdateService(
        release: ReleaseInfo(
          tagName: 'v1.1.0',
          htmlUrl: 'https://example.com/release',
          apkUrl: 'https://example.com/app.apk',
        ),
      ),
      loadVersion: () async => '1.0.0',
    );
    await autoUpdate.setEnabled(true);

    await pumpSplash(
      tester,
      autoUpdate: autoUpdate,
      downloader: _ThrowingDownloader(),
      installer: _RecordingInstaller(),
    );

    await tester.tap(find.text('Обновить'));
    await tester.pump(); // закрытие модалки + диалог загрузки
    await tester.pump(const Duration(milliseconds: 100)); // ошибка скачивания
    await tester.pump(const Duration(milliseconds: 300)); // закрытие диалога
    await tester.pump(const Duration(seconds: 2)); // consume + fade
    await tester.pumpAndSettle();

    // Диалога отказа установщика нет; приложение открылось; флаг сброшен.
    expect(find.text('Не удалось запустить установку'), findsNothing);
    expect(find.text('Главный экран'), findsOneWidget);
    expect(repository.value, isFalse);
  });

  testWidgets('отказ установщика — диалог «Не удалось запустить установку» '
      '(64.1)', (tester) async {
    final repository = _StubAutoUpdateRepository();
    final autoUpdate = AutoUpdateController(
      repository: repository,
      service: _FakeUpdateService(
        release: ReleaseInfo(
          tagName: 'v1.1.0',
          htmlUrl: 'https://example.com/release',
          apkUrl: 'https://example.com/app.apk',
        ),
      ),
      loadVersion: () async => '1.0.0',
    );
    await autoUpdate.setEnabled(true);

    await pumpSplash(
      tester,
      autoUpdate: autoUpdate,
      downloader: _RecordingDownloader(),
      installer: _RefusingInstaller(),
    );

    await tester.tap(find.text('Обновить'));
    await tester.pump(); // закрытие модалки + диалог загрузки
    await tester.pump(const Duration(milliseconds: 100)); // установка отказала
    await tester.pumpAndSettle();

    // Блокирующий диалог вместо снекбара (сплэш исчезает — снекбар
    // был бы нечитаем).
    expect(find.text('Не удалось запустить установку'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);

    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(find.text('Главный экран'), findsOneWidget);
    // Флаг сброшен после закрытия диалога (диалог модалки был показан).
    expect(repository.value, isFalse);
  });
}

// --- Поддельные зависимости тестов автообновления (64.1) ---

class _FakeUpdateService implements UpdateService {
  _FakeUpdateService({this.release});

  ReleaseInfo? release;

  @override
  Future<ReleaseInfo?> fetchLatestRelease() async => release;
}

class _StubAutoUpdateRepository implements AutoUpdateRepository {
  bool value = false;

  @override
  Future<bool> read() async => value;

  @override
  Future<void> write(bool value) async {
    this.value = value;
  }
}

class _RecordingDownloader implements ApkDownloader {
  @override
  Future<String> download(Uri url) async {
    downloadedUrls.add(url);
    return '/tmp/update.apk';
  }

  final downloadedUrls = <Uri>[];
}

class _ThrowingDownloader implements ApkDownloader {
  @override
  Future<String> download(Uri url) async {
    throw Exception('network down');
  }
}

class _RefusingInstaller implements ApkInstaller {
  @override
  Future<bool> install(String apkPath) async => false;
}

class _RecordingInstaller implements ApkInstaller {
  @override
  Future<bool> install(String apkPath) async {
    installedPaths.add(apkPath);
    return true;
  }

  final installedPaths = <String>[];
}

Future<void> pumpSplash(
  WidgetTester tester, {
  required AutoUpdateController autoUpdate,
  ApkDownloader? downloader,
  ApkInstaller? installer,
}) async {
  await tester.pumpWidget(
    SplashGate(
      bootstrap: () async {},
      homeBuilder: () =>
          const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
      splashBody: const ColoredBox(
        color: Colors.black,
        child: Center(child: Text('Заставка')),
      ),
      autoUpdateController: autoUpdate,
      apkDownloader: downloader,
      apkInstaller: installer,
    ),
  );
  // Минимальные 2 секунды заставки: продвигаем фейковые часы явно —
  // pumpAndSettle их не двигает.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}
