import 'dart:async';

import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_list_item.dart';
import 'package:fitnessappai/features/profile/domain/contraindication_service.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';

/// Управляет списком упражнений: поиск с дебаунсом, фильтр по типу,
/// загрузка данных для карточек.
class ExerciseListController {
  ExerciseListController(
    this._repository, {
    required this.profileRepository,
    this.service = const ContraindicationService(),
    DataChangeNotifier? changes,
  }) {
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  static const Duration searchDebounce = Duration(milliseconds: 300);

  final ExerciseRepository _repository;
  final UserProfileRepository profileRepository;
  final ContraindicationService service;

  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<List<ExerciseListItem>> items = Signal(<ExerciseListItem>[]);
  final Signal<bool> isLoading = Signal(false);
  final Signal<String> query = Signal('');
  final Signal<ExerciseType?> typeFilter = Signal(null);
  final Signal<bool> onlyCustom = Signal(false);

  Timer? _debounce;

  void setQuery(String value) {
    query.value = value;
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, _load);
  }

  void setTypeFilter(ExerciseType? type) {
    typeFilter.value = type;
    _load();
  }

  void setOnlyCustom(bool value) {
    onlyCustom.value = value;
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final q = query.value.trim();
      final exercises = q.isEmpty
          ? await _repository.getAll()
          : await _repository.search(q);
      final type = typeFilter.value;
      final filtered = type == null
          ? exercises
          : exercises.where((e) => e.type == type).toList();
      final customFiltered = onlyCustom.value
          ? filtered.where((e) => e.isCustom).toList()
          : filtered;

      final musclesByExercise = await _repository.muscleGroupsByExercise();
      final tagsByExercise = await _repository.contraindicationsByExercise();
      final userKeys = {
        for (final tag in await profileRepository.getContraindicationTags())
          tag.key,
      };

      items.value = [
        for (final exercise in customFiltered)
          ExerciseListItem(
            exercise: exercise,
            muscles: musclesByExercise[exercise.id] ?? const [],
            hasContraindications: service.hasContraindications(
              tagsByExercise[exercise.id] ?? const [],
              userKeys,
            ),
          ),
      ];
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    _debounce?.cancel();
    _reloadSubscription.dispose();
  }
}
