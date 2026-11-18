// ignore_for_file: type=lint
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/settings/data/auto_update_repository.dart';

void main() {
  late AppDatabase db;
  late AutoUpdateRepository repository;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repository = AutoUpdateRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('без строки флаг выключен (значение по умолчанию)', () async {
    expect(await repository.read(), isFalse);
  });

  test('write/read — флаг включается и выключается (upsert)', () async {
    await repository.write(true);
    expect(await repository.read(), isTrue);

    await repository.write(false);
    expect(await repository.read(), isFalse);
  });

  test('повторная запись не создаёт дубликаты ключей', () async {
    await repository.write(true);
    await repository.write(true);
    final rows = await (db.select(
      db.appMeta,
    )..where((t) => t.key.equals(AutoUpdateRepository.key))).get();
    expect(rows, hasLength(1));
  });
}
