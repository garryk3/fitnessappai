import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/sound/sound_settings_repository.dart';
import 'package:fitnessappai/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late SoundSettingsRepository repository;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repository = SoundSettingsRepository(db);
  });

  tearDown(() => db.close());

  test('по умолчанию звук включён и используется встроенный сигнал', () async {
    expect(await repository.isEnabled(), isTrue);
    expect(await repository.soundFilePath(), isNull);
  });

  test('setEnabled сохраняет переключатель', () async {
    await repository.setEnabled(false);
    expect(await repository.isEnabled(), isFalse);

    await repository.setEnabled(true);
    expect(await repository.isEnabled(), isTrue);
  });

  test('setSoundFile сохраняет и очищает путь', () async {
    await repository.setSoundFile('/sounds/custom.mp3');
    expect(await repository.soundFilePath(), '/sounds/custom.mp3');

    await repository.setSoundFile(null);
    expect(await repository.soundFilePath(), isNull);
  });

  test('переключатель переживает повторное открытие репозитория', () async {
    await repository.setEnabled(false);
    await repository.setSoundFile('/sounds/custom.mp3');

    final fresh = SoundSettingsRepository(db);
    expect(await fresh.isEnabled(), isFalse);
    expect(await fresh.soundFilePath(), '/sounds/custom.mp3');
  });
}
