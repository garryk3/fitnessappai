import 'dart:io';

import 'package:drift/drift.dart' show Value;
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

  group('копирование в хранилище, доступное системе (48.1)', () {
    late Directory external;

    setUp(() async {
      external = await Directory.systemTemp.createTemp('reminder_sound_ext');
      repository = ReminderSoundSettingsRepository(
        db,
        directoryProvider: () async => documents,
        externalDirectoryProvider: () async => external,
      );
    });

    tearDown(() async {
      if (await external.exists()) {
        await external.delete(recursive: true);
      }
    });

    test('файл копируется во внешнюю директорию, а не в документы', () async {
      final source = await pickedFile();

      await repository.setSoundFile(source.path);

      final stored = await repository.soundFilePath();
      expect(stored, p.join(external.path, 'reminder_sounds', 'beep.mp3'));
      // Копия действительно читаема системой — иначе канал уведомлений играл бы
      // стандартный сигнал вместо выбранного (48.1).
      expect(await repository.isSoundSystemReadable(), isTrue);
      expect(await File(stored!).readAsBytes(), [1, 2, 3]);
      // В приватных документах копии нет.
      expect(
        await Directory(p.join(documents.path, 'reminder_sounds')).exists(),
        isFalse,
      );
    });

    test('без файла читаемость не важна', () async {
      expect(await repository.isSoundSystemReadable(), isTrue);
    });

    test(
      'без внешнего хранилища файл уходит в документы и помечается',
      () async {
        // Внешнего каталога нет (desktop, тесты) — копируем в документы, но
        // честно помечаем, что системе такой файл недоступен.
        repository = ReminderSoundSettingsRepository(
          db,
          directoryProvider: () async => documents,
          externalDirectoryProvider: () async => null,
        );
        final source = await pickedFile();

        await repository.setSoundFile(source.path);

        expect(
          await repository.soundFilePath(),
          p.join(documents.path, 'reminder_sounds', 'beep.mp3'),
        );
        expect(await repository.isSoundSystemReadable(), isFalse);
      },
    );

    test('ошибка внешнего хранилища не лишает выбора файла', () async {
      repository = ReminderSoundSettingsRepository(
        db,
        directoryProvider: () async => documents,
        externalDirectoryProvider: () async =>
            throw const FileSystemException('нет внешнего хранилища'),
      );
      final source = await pickedFile();

      await repository.setSoundFile(source.path);

      expect(
        await repository.soundFilePath(),
        p.join(documents.path, 'reminder_sounds', 'beep.mp3'),
      );
      expect(await repository.isSoundSystemReadable(), isFalse);
    });

    test(
      'несуществующий файл сохраняется как есть и не считается доступным',
      () async {
        await repository.setSoundFile('/sounds/missing.mp3');

        expect(await repository.soundFilePath(), '/sounds/missing.mp3');
        expect(await repository.isSoundSystemReadable(), isFalse);
      },
    );

    test(
      'ensureSoundFileReady переносит файл из документов во внешний',
      () async {
        // Сценарий обновления: файл выбран до 48.1 и лежит в приватных
        // документах — переносим сам, чтобы владельцу не пришлось выбирать заново.
        final private = ReminderSoundSettingsRepository(
          db,
          directoryProvider: () async => documents,
          externalDirectoryProvider: () async => null,
        );
        final source = await pickedFile();
        await private.setSoundFile(source.path);
        final inDocuments = await private.soundFilePath();
        expect(await private.isSoundSystemReadable(), isFalse);

        await repository.ensureSoundFileReady();

        final stored = await repository.soundFilePath();
        expect(stored, p.join(external.path, 'reminder_sounds', 'beep.mp3'));
        expect(await repository.isSoundSystemReadable(), isTrue);
        // Старая копия убрана — две копии одного звука не остаются.
        expect(await File(inDocuments!).exists(), isFalse);
      },
    );

    test('перенос без внешнего хранилища не уничтожает файл', () async {
      // Регрессия: копирование файла в него же обнуляет его, а метод зовётся
      // на каждом старте приложения. Без внешнего хранилища (desktop) файл
      // обязан остаться целым и с прежним флагом.
      final private = ReminderSoundSettingsRepository(
        db,
        directoryProvider: () async => documents,
        externalDirectoryProvider: () async => null,
      );
      final source = await pickedFile();
      await private.setSoundFile(source.path);
      final inDocuments = await private.soundFilePath();

      await private.ensureSoundFileReady();
      // И повторно — на каждом старте.
      await private.ensureSoundFileReady();

      final file = File(inDocuments!);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), [1, 2, 3], reason: 'файл обнулён');
      expect(await private.isSoundSystemReadable(), isFalse);
    });

    test('перенос повторно не трогает уже перенесённый файл', () async {
      final source = await pickedFile();
      await repository.setSoundFile(source.path);
      final stored = await repository.soundFilePath();

      await repository.ensureSoundFileReady();
      await repository.ensureSoundFileReady();

      expect(await repository.soundFilePath(), stored);
      expect(await File(stored!).readAsBytes(), [1, 2, 3]);
      expect(await repository.isSoundSystemReadable(), isTrue);
    });

    test('файл во внешнем хранилище с неверным флагом не удаляется', () async {
      // Рассинхрон БД: файл уже во внешнем хранилище (системе читаем), но ключ
      // читаемости остался `false`. Перенос не должен ни перезаписать файл, ни
      // удалить его как «старую копию» — потеря файла обнулила бы выбор
      // владельца (48.1).
      final source = await pickedFile();
      await repository.setSoundFile(source.path);
      final stored = await repository.soundFilePath();
      await db
          .into(db.appMeta)
          .insertOnConflictUpdate(
            AppMetaCompanion.insert(
              key: ReminderSoundSettingsRepository.readableKey,
              value: const Value('false'),
            ),
          );

      await repository.ensureSoundFileReady();

      expect(await repository.soundFilePath(), stored);
      expect(await File(stored!).readAsBytes(), [1, 2, 3]);
      expect(
        await repository.isSoundSystemReadable(),
        isFalse,
        reason: 'флаг не выдумывается: файл не переносился, только проверен',
      );
    });

    test('перенос переживает перезапуск приложения', () async {
      final source = await pickedFile();
      await repository.setSoundFile(source.path);
      final stored = await repository.soundFilePath();

      final fresh = ReminderSoundSettingsRepository(
        db,
        directoryProvider: () async => documents,
        externalDirectoryProvider: () async => external,
      );
      await fresh.ensureSoundFileReady();

      expect(await fresh.soundFilePath(), stored);
      expect(await fresh.isSoundSystemReadable(), isTrue);
    });

    test('сброс удаляет копию и оба ключа', () async {
      final source = await pickedFile();
      await repository.setSoundFile(source.path);
      final stored = await repository.soundFilePath();

      await repository.setSoundFile(null);

      expect(await repository.soundFilePath(), isNull);
      expect(await repository.isSoundSystemReadable(), isTrue);
      expect(await File(stored!).exists(), isFalse);
    });
  });
}
