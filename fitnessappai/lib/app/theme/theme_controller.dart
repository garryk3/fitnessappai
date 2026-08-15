import 'package:flutter/material.dart';

import 'package:fitnessappai/app/theme/theme_settings_repository.dart';

/// Управляет выбранной темой приложения и персистит её в [ThemeSettingsRepository].
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._repository, {ThemeMode initial = ThemeMode.dark})
    : super(initial);

  final ThemeSettingsRepository _repository;

  /// Загружает сохранённый режим темы.
  Future<void> load() async {
    value = await _repository.getThemeMode();
  }

  /// Сохраняет и применяет [mode].
  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    await _repository.setThemeMode(mode);
  }
}
