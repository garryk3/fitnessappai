// ignore_for_file: prefer_initializing_formals
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
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
  ProgramListController(
    this._repository, {
    DataChangeNotifier? changes,
    ReminderService? reminderService,
  }) : _reminderService = reminderService {
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final ProgramRepository _repository;
  final ReminderService? _reminderService;
  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<List<ProgramListItem>> items = Signal(<ProgramListItem>[]);
  final Signal<bool> isLoading = Signal(false);

  Future<void> refresh() => _load();

  Future<void> deleteProgram(int programId) async {
    if (_reminderService != null) {
      final days = await _repository.getDays(programId);
      for (final day in days) {
        await _reminderService.cancel(day.id!);
      }
    }
    await _repository.delete(programId);
  }

  /// Делает программу активной и перепланирует напоминания её дней (47.8).
  Future<void> setActive(int programId) async {
    await _repository.setActive(programId);
    await _syncReminders(programId, activate: true);
  }

  /// Деактивирует программу и отменяет напоминания её дней (47.8).
  ///
  /// Настройки напоминаний в БД сохраняются, поэтому повторная активация
  /// снова их запланирует.
  Future<void> deactivate(int programId) async {
    await _repository.deactivate(programId);
    await _syncReminders(programId, activate: false);
  }

  Future<void> _syncReminders(int programId, {required bool activate}) async {
    final service = _reminderService;
    if (service == null) {
      return;
    }
    final days = await _repository.getDays(programId);
    final dayIds = [
      for (final day in days)
        if (day.id != null) day.id!,
    ];
    if (activate) {
      await service.rescheduleDays(dayIds);
    } else {
      await service.cancelDays(dayIds);
    }
  }

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
