import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';

void main() {
  late AppDatabase db;
  late UserProfileRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = UserProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserProfileRepository.get', () {
    test('создаёт профиль с id = 1 при первом обращении', () async {
      final profile = await repo.get();

      expect(profile.id, 1);
      expect(profile.createdAt, isNotNull);
      expect(profile.updatedAt, isNotNull);

      final count = await db.select(db.userProfiles).get();
      expect(count, hasLength(1));
    });

    test('не создаёт дубликаты при повторных вызовах', () async {
      final first = await repo.get();
      final second = await repo.get();

      expect(second.id, first.id);
      final count = await db.select(db.userProfiles).get();
      expect(count, hasLength(1));
    });
  });

  group('UserProfileRepository.setContraindicationTags', () {
    test('сохраняет теги и возвращает их в порядке каталога', () async {
      await repo.setContraindicationTags(['knees', 'back', 'neck']);

      final tags = await repo.getContraindicationTags();
      expect(tags.map((t) => t.key), ['knees', 'back', 'neck']);
    });

    test('профиль создаётся даже если set вызван первым', () async {
      await repo.setContraindicationTags(['heart']);

      final profile = await repo.get();
      expect(profile.id, 1);
      expect(await repo.getContraindicationTags(), hasLength(1));
    });

    test('пустой список очищает теги', () async {
      await repo.setContraindicationTags(['knees', 'back']);
      await repo.setContraindicationTags([]);

      expect(await repo.getContraindicationTags(), isEmpty);
    });

    test('замена тегов не оставляет старые', () async {
      await repo.setContraindicationTags(['knees', 'back']);
      await repo.setContraindicationTags(['shoulders']);

      final tags = await repo.getContraindicationTags();
      expect(tags.single.key, 'shoulders');
    });

    test('неизвестные ключи игнорируются', () async {
      await repo.setContraindicationTags(['knees', 'unknown', 'heart']);

      expect((await repo.getContraindicationTags()).map((t) => t.key), [
        'knees',
        'heart',
      ]);
    });
  });

  test('getContraindicationTags пуст до сохранения тегов', () async {
    expect(await repo.getContraindicationTags(), isEmpty);
  });

  group('UserProfileRepository.getAllTags', () {
    test('возвращает каталог тегов по id', () async {
      final tags = await repo.getAllTags();

      expect(tags.map((t) => t.key), [
        'knees',
        'back',
        'neck',
        'shoulders',
        'elbows',
        'wrists',
        'heart',
        'pregnancy',
      ]);
      expect(tags.first.labelRu, 'Колени');
    });
  });
}
