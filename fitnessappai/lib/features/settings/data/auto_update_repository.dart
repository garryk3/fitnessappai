import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';

/// Флаг «автообновление» (64.1) в key/value-таблице `app_meta`.
///
/// Отсутствие строки = флаг выключен (значение по умолчанию).
class AutoUpdateRepository {
  AutoUpdateRepository(this._db);

  static const String key = 'auto_update';

  final AppDatabase _db;

  Future<bool> read() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value == 'true';
  }

  /// Upsert по ключу: обновление строки, при отсутствии — вставка.
  Future<void> write(bool value) async {
    final stored = value ? 'true' : 'false';
    final updated =
        await (_db.update(_db.appMeta)..where((t) => t.key.equals(key))).write(
          AppMetaCompanion(value: Value(stored)),
        );
    if (updated == 0) {
      await _db
          .into(_db.appMeta)
          .insert(AppMetaCompanion.insert(key: key, value: Value(stored)));
    }
  }
}
