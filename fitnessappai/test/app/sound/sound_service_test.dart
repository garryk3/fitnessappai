import 'dart:io';

import 'package:audio_session/audio_session.dart' hide AndroidAudioFocus;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:fitnessappai/app/sound/sound_service.dart';

void main() {
  test('audio context не запрашивает фокус (им управляет audio_session)', () {
    final context = AudioplayersSoundService.audioContext();

    expect(context.android.audioFocus, AndroidAudioFocus.none);
    expect(context.android.usageType, AndroidUsageType.alarm);
    expect(context.android.stayAwake, isTrue);
  });

  test(
    'audio session конфигурируется с duck (приглушение, а не остановка)',
    () {
      final config = AudioplayersSoundService.sessionConfiguration();

      expect(
        config.androidAudioFocusGainType,
        AndroidAudioFocusGainType.gainTransientMayDuck,
      );
    },
  );

  group('встроенный сигнал (48.1)', () {
    test('по умолчанию — сигнал таймера', () {
      final source = AudioplayersSoundService.resolveSourceFor(
        null,
        AudioplayersSoundService.timerAssetPath,
      );

      expect(source, isA<AssetSource>());
      expect(
        (source as AssetSource).path,
        AudioplayersSoundService.timerAssetPath,
      );
    });

    test('у напоминаний свой встроенный сигнал, а не сигнал таймера', () {
      // Раньше оба экземпляра делили `sounds/timer.mp3`, поэтому
      // предпрослушивание в настройках напоминаний звучало как таймер (48.1).
      final source = AudioplayersSoundService.resolveSourceFor(
        null,
        AudioplayersSoundService.notificationAssetPath,
      );

      expect(source, isA<AssetSource>());
      expect(
        (source as AssetSource).path,
        AudioplayersSoundService.notificationAssetPath,
      );
      expect(
        AudioplayersSoundService.notificationAssetPath,
        isNot(AudioplayersSoundService.timerAssetPath),
      );
    });

    test('выбранный файл важнее встроенного сигнала', () {
      final source = AudioplayersSoundService.resolveSourceFor(
        '/sounds/custom.mp3',
        AudioplayersSoundService.notificationAssetPath,
      );

      expect(source, isA<DeviceFileSource>());
      // Пустая строка — не выбранный файл, а встроенный сигнал.
      expect(
        AudioplayersSoundService.resolveSourceFor(
          '',
          AudioplayersSoundService.notificationAssetPath,
        ),
        isA<AssetSource>(),
      );
    });
  });

  test('ассет сигнала уведомлений совпадает с raw-ресурсом канала', () async {
    // Канал уведомлений играет `android/app/src/main/res/raw/notification.mp3`.
    // Предпрослушивание обязано звучать тем же, иначе владелец слышит в
    // настройках не тот сигнал, который потом придёт в напоминании (48.1).
    //
    // Пути ищутся от `pubspec.yaml`, а не от текущей директории: `flutter test`
    // можно запустить и из корня репозитория, а не из пакета.
    final root = _packageRoot();
    final asset = File(
      p.join(root.path, 'assets', 'sounds', 'notification.mp3'),
    );
    final raw = File(
      p.join(
        root.path,
        'android',
        'app',
        'src',
        'main',
        'res',
        'raw',
        'notification.mp3',
      ),
    );

    expect(await asset.exists(), isTrue, reason: 'ассет не добавлен');
    expect(await raw.exists(), isTrue, reason: 'raw-ресурс канала пропал');
    expect(
      await asset.readAsBytes(),
      await raw.readAsBytes(),
      reason: 'ассет и raw-ресурс разошлись — предпрослушивание соврёт',
    );
  });
}

/// Корень пакета: ближайший каталог с `pubspec.yaml` вверх от текущего.
Directory _packageRoot() {
  var dir = Directory.current.absolute;
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('pubspec.yaml не найден выше ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir;
}
