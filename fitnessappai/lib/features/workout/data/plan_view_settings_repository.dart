import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';

/// Хранилище выбранного режима плана (неделя/месяц) в таблице `app_meta`.
class PlanViewSettingsRepository {
  PlanViewSettingsRepository(this._db);

  static const String viewModeKey = 'plan_view_mode';

  final AppDatabase _db;

  /// Возвращает сохранённый режим плана или [PlanViewMode.week] по умолчанию.
  Future<PlanViewMode> getViewMode() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(viewModeKey))).getSingleOrNull();
    return row?.value == PlanViewMode.month.name
        ? PlanViewMode.month
        : PlanViewMode.week;
  }

  /// Сохраняет режим плана в `app_meta`.
  Future<void> setViewMode(PlanViewMode mode) async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(key: viewModeKey, value: Value(mode.name)),
        );
  }
}
