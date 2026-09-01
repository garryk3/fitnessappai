import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/workout/data/plan_view_settings_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';

void main() {
  late AppDatabase db;
  late PlanViewSettingsRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = PlanViewSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('по умолчанию возвращает неделю', () async {
    expect(await repo.getViewMode(), PlanViewMode.week);
  });

  test('сохраняет и возвращает выбранный режим', () async {
    await repo.setViewMode(PlanViewMode.month);
    expect(await repo.getViewMode(), PlanViewMode.month);

    await repo.setViewMode(PlanViewMode.week);
    expect(await repo.getViewMode(), PlanViewMode.week);
  });
}
