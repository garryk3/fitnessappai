import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'package:fitnessappai/core/database/app_database.dart';

/// Хранилище выбранной темы приложения в таблице `app_meta`.
class ThemeSettingsRepository {
  ThemeSettingsRepository(this._db);

  static const String themeModeKey = 'theme_mode';

  final AppDatabase _db;

  /// Возвращает сохранённый режим темы или [ThemeMode.dark] по умолчанию.
  Future<ThemeMode> getThemeMode() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(themeModeKey))).getSingleOrNull();
    return switch (row?.value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  /// Сохраняет режим темы в `app_meta`.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(key: themeModeKey, value: Value(mode.name)),
        );
  }
}
