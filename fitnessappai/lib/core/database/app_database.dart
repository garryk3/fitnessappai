import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:fitnessappai/core/database/tables/app_meta.dart';

part 'app_database.g.dart';

/// Точка входа в локальную БД SQLite.
///
/// В проде используется файл `fitnessappai.sqlite` в documents-каталоге,
/// в тестах — [QueryExecutor] с [NativeDatabase.memory] или in-memory.
@DriftDatabase(tables: [AppMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
      : super(executor ?? driftDatabase(name: 'fitnessappai'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
