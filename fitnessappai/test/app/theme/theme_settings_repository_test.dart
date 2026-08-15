import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/app/theme/theme_settings_repository.dart';
import 'package:fitnessappai/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late ThemeSettingsRepository repository;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repository = ThemeSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ThemeSettingsRepository', () {
    test('по умолчанию возвращает тёмную тему', () async {
      expect(await repository.getThemeMode(), ThemeMode.dark);
    });

    test('сохраняет и возвращает режим темы', () async {
      await repository.setThemeMode(ThemeMode.light);
      expect(await repository.getThemeMode(), ThemeMode.light);

      await repository.setThemeMode(ThemeMode.dark);
      expect(await repository.getThemeMode(), ThemeMode.dark);
    });

    test('повторное сохранение не плодит записи', () async {
      await repository.setThemeMode(ThemeMode.light);
      await repository.setThemeMode(ThemeMode.light);

      final rows = await db
          .select(db.appMeta)
          .get()
          .then((r) => r.where((m) => m.key == 'theme_mode'));
      expect(rows, hasLength(1));
    });
  });

  group('ThemeController', () {
    test('load подхватывает сохранённую тему', () async {
      await repository.setThemeMode(ThemeMode.light);
      final controller = ThemeController(repository);

      expect(controller.value, ThemeMode.dark);
      await controller.load();
      expect(controller.value, ThemeMode.light);
    });

    test('setMode меняет значение и персистит', () async {
      final controller = ThemeController(repository);

      await controller.setMode(ThemeMode.light);

      expect(controller.value, ThemeMode.light);
      expect(await repository.getThemeMode(), ThemeMode.light);
    });

    test('уведомляет слушателей при смене темы', () async {
      final controller = ThemeController(repository);
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.setMode(ThemeMode.light);

      expect(notified, greaterThan(0));
    });
  });
}
