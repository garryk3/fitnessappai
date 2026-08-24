import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';

/// Элемент карточки программы: модель, дни и количество упражнений.
class ProgramListItem {
  const ProgramListItem({
    required this.program,
    required this.days,
    required this.exercisesCount,
  });

  final Program program;

  /// Дни программы в порядке индексов.
  final List<ProgramDay> days;
  final int exercisesCount;
}

/// Управляет списком программ: загрузка, обновление, удаление.
class ProgramListController {
  ProgramListController(this._repository, {DataChangeNotifier? changes}) {
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final ProgramRepository _repository;
  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<List<ProgramListItem>> items = Signal(<ProgramListItem>[]);
  final Signal<bool> isLoading = Signal(false);

  Future<void> refresh() => _load();

  Future<void> deleteProgram(int programId) => _repository.delete(programId);

  Future<void> setActive(int programId) => _repository.setActive(programId);

  Future<void> deactivate(int programId) => _repository.deactivate(programId);

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final summaries = await _repository.getPrograms();
      final list = <ProgramListItem>[];
      for (final summary in summaries) {
        list.add(
          ProgramListItem(
            program: summary.program,
            days: await _repository.getDays(summary.program.id!),
            exercisesCount: summary.exercisesCount,
          ),
        );
      }
      items.value = list;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    _reloadSubscription.dispose();
  }
}
