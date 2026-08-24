import 'package:signals/signals.dart';

import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';

/// Управляет экраном «Моё здоровье»: каталог тегов и выбор пользователя.
class ContraindicationsController {
  ContraindicationsController({required this.repository}) {
    _load();
  }

  final UserProfileRepository repository;

  final Signal<bool> isLoading = Signal(true);
  final Signal<List<ContraindicationTag>> tags = Signal(const []);
  final Signal<Set<String>> selectedKeys = Signal(<String>{});
  final Signal<bool> isSaving = Signal(false);

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final all = await repository.getAllTags();
      final selected = await repository.getContraindicationTags();
      tags.value = all;
      selectedKeys.value = {for (final tag in selected) tag.key};
    } finally {
      isLoading.value = false;
    }
  }

  /// Переключает тег с ключом [key] и автоматически сохраняет.
  Future<void> toggle(String key, bool enabled) async {
    final next = {...selectedKeys.value};
    if (enabled) {
      next.add(key);
    } else {
      next.remove(key);
    }
    selectedKeys.value = next;
    await save();
  }

  /// Сохраняет выбранные теги. Возвращает `true` при успехе.
  Future<bool> save() async {
    if (isSaving.value) {
      return false;
    }
    isSaving.value = true;
    try {
      await repository.setContraindicationTags(selectedKeys.value.toList());
      return true;
    } finally {
      isSaving.value = false;
    }
  }
}
