import 'package:audio_session/audio_session.dart' hide AndroidAudioFocus;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
