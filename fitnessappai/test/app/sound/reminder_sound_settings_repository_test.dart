import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:fitnessappai/app/sound/reminder_sound_settings_repository.dart';
import 'package:fitnessappai/app/sound/sound_settings_repository.dart';
import 'package:fitnessappai/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late Directory documents;
  late ReminderSoundSettingsRepository repository;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    documents = await Directory.systemTemp.createTemp('reminder_sounds_test');
    repository = ReminderSoundSettingsRepository(
      db,
      directoryProvider: () async => documents,
    );
  });

  tearDown(() async {
    await db.close();
    if (await documents.exists()) {
      await documents.delete(recursive: true);
    }
  });

  /// Готовит «файл из системного пикера» во временной папке.
  Future<File> pickedFile([String name = 'beep.mp3']) async {
    final dir = await Directory.systemTemp.createTemp('picked_sound');
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes([1, 2, 3]);
    return file;
  }

  test('по умолчанию звук включён и используется встроенный сигнал', () async {
    expect(await repository.isEnabled(), isTrue);
    expect(await repository.soundFilePath(), isNull);
  });

  test('setEnabled сохраняет переключатель', () async {
    await repository.setEnabled(false);
    expect(await repository.isEnabled(), isFalse);
  });

  test('ключи не пересекаются с настройками звука таймеров (47.5)', () async {
    final timerSound = SoundSettingsRepository(db);
    final source = await pickedFile('reminder.mp3');
    await timerSound.setEnabled(false);
    await timerSound.setSoundFile('/sounds/timer.mp3');
    await repository.setEnabled(true);
    await repository.setSoundFile(source.path);

    expect(await timerSound.isEnabled(), isFalse);
    expect(await timerSound.soundFilePath(), '/sounds/timer.mp3');
    expect(await repository.isEnabled(), isTrue);
    expect(await repository.soundFilePath(), contains('reminder_sounds'));
  });

  test('выбранный файл копируется в постоянное хранилище (47.5)', () async {
    final source = await pickedFile();

    await repository.setSoundFile(source.path);

    final stored = await repository.soundFilePath();
    expect(stored, isNotNull);
    expect(stored, isNot(source.path));
    expect(stored, p.join(documents.path, 'reminder_sounds', 'beep.mp3'));
    // Копия существует и содержимое совпадает — предпрослушивание работает.
    final copy = File(stored!);
    expect(await copy.exists(), isTrue);
    expect(await copy.readAsBytes(), [1, 2, 3]);
  });

  test('несуществующий файл сохраняется как есть, без падения', () async {
    await repository.setSoundFile('/sounds/missing.mp3');

    expect(await repository.soundFilePath(), '/sounds/missing.mp3');
  });

  test('смена файла удаляет предыдущую копию (47.5)', () async {
    final first = await pickedFile('first.mp3');
    final second = await pickedFile('second.mp3');

    await repository.setSoundFile(first.path);
    final firstCopy = await repository.soundFilePath();

    await repository.setSoundFile(second.path);

    expect(await File(firstCopy!).exists(), isFalse);
    expect(await repository.soundFilePath(), endsWith('second.mp3'));
  });

  test('сброс удаляет копию и ключ', () async {
    final source = await pickedFile();
    await repository.setSoundFile(source.path);
    final stored = await repository.soundFilePath();

    await repository.setSoundFile(null);

    expect(await repository.soundFilePath(), isNull);
    expect(await File(stored!).exists(), isFalse);
  });

  test('настройки переживают повторное открытие репозитория', () async {
    final source = await pickedFile();
    await repository.setEnabled(false);
    await repository.setSoundFile(source.path);
    final stored = await repository.soundFilePath();

    final fresh = ReminderSoundSettingsRepository(
      db,
      directoryProvider: () async => documents,
    );

    expect(await fresh.isEnabled(), isFalse);
    expect(await fresh.soundFilePath(), stored);
    // Файл на месте после «перезапуска» — путь не указывает на кэш.
    expect(await File(stored!).exists(), isTrue);
  });
}
