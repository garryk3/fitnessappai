import 'package:signals/signals.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Элемент списка истории: сессия с числом упражнений.
class HistoryItem {
  const HistoryItem({required this.session, required this.exercisesCount});

  final WorkoutSession session;

  /// Количество различных упражнений в сессии.
  final int exercisesCount;

  Duration get duration => session.endedAt.difference(session.startedAt);
}

/// Управляет экраном истории тренировок.
class HistoryController {
  HistoryController({
    required this.workoutRepository,
    DataChangeNotifier? changes,
  }) {
    _reloadSubscription = ChangeReloadSubscription(
      changes: changes ?? appDataChanges,
      reload: _load,
    );
    _load();
  }

  final WorkoutRepository workoutRepository;
  late final ChangeReloadSubscription _reloadSubscription;

  final Signal<bool> isLoading = Signal(true);
  final Signal<List<HistoryItem>> items = Signal(const []);
  final Signal<Set<DateTime>> workoutDates = Signal(const {});

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final sessions = await workoutRepository.getAllSessions();
      final result = <HistoryItem>[];
      final dates = <DateTime>{};
      for (final session in sessions) {
        final detail = await workoutRepository.getSession(session.id!);
        final count = detail == null
            ? 0
            : detail.results.map((r) => r.exerciseName).toSet().length;
        result.add(HistoryItem(session: session, exercisesCount: count));
        dates.add(_dateOnly(session.performedDate));
      }
      items.value = result;
      workoutDates.value = dates;
    } finally {
      isLoading.value = false;
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void dispose() {
    _reloadSubscription.dispose();
  }
}
