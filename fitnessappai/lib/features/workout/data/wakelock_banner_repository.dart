import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';

/// Персистентный флаг «баннер wakelock.dismiss был нажат».
/// Хранится в `app_meta`, чтобы не показываться повторно.
class WakelockBannerRepository {
  WakelockBannerRepository(this._db);

  static const String _key = 'wakelock_banner_dismissed';

  final AppDatabase _db;

  /// Возвращает `true`, если пользователь уже нажал «ОК».
  Future<bool> isDismissed() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_key))).getSingleOrNull();
    return row?.value == 'true';
  }

  /// Сохраняет факт нажатия «ОК».
  Future<void> setDismissed() async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(key: _key, value: const Value('true')),
        );
  }
}
