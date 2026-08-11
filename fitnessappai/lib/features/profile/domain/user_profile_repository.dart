import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/user_profile.dart';

/// Репозиторий профиля пользователя.
///
/// В БД профиль хранится одной строкой ([profileId]); [get] создаёт её при
/// первом обращении и впоследствии всегда возвращает один и тот же профиль.
class UserProfileRepository {
  UserProfileRepository(this._db);

  final AppDatabase _db;

  /// Идентификатор единственной строки профиля.
  static const int profileId = 1;

  /// Возвращает профиль, создавая его при первом обращении.
  Future<UserProfile> get() async {
    final existing = await _selectProfile();
    if (existing != null) {
      return _toModel(existing);
    }
    final now = DateTime.now();
    await _db
        .into(_db.userProfiles)
        .insert(
          UserProfilesCompanion.insert(
            id: Value(profileId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return _toModel((await _selectProfile())!);
  }

  /// Заменяет набор тегов противопоказаний пользователя.
  ///
  /// Ключи, отсутствующие в справочнике `contraindication_tags`,
  /// игнорируются. Профиль создаётся при необходимости.
  Future<void> setContraindicationTags(List<String> keys) async {
    await _db.transaction(() async {
      await get();
      final tags = await (_db.select(
        _db.contraindicationTags,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final idsByKey = {for (final t in tags) t.key: t.id};

      await (_db.delete(
        _db.userContraindications,
      )..where((t) => t.userId.equals(profileId))).go();

      final selected = [
        for (final key in keys)
          if (idsByKey[key] != null)
            UserContraindicationsCompanion.insert(
              userId: profileId,
              contraindicationTagId: idsByKey[key]!,
            ),
      ];
      if (selected.isNotEmpty) {
        await _db.batch(
          (batch) => batch.insertAll(_db.userContraindications, selected),
        );
      }
    });
  }

  /// Возвращает весь каталог тегов противопоказаний, отсортированный по id.
  Future<List<ContraindicationTag>> getAllTags() async {
    final rows = await (_db.select(
      _db.contraindicationTags,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return rows.map(_tagFromRow).toList(growable: false);
  }

  /// Возвращает теги противопоказаний пользователя, отсортированные по id.
  Future<List<ContraindicationTag>> getContraindicationTags() async {
    final profile = await _selectProfile();
    if (profile == null) {
      return const [];
    }
    final query =
        _db.select(_db.contraindicationTags).join([
            innerJoin(
              _db.userContraindications,
              _db.userContraindications.contraindicationTagId.equalsExp(
                _db.contraindicationTags.id,
              ),
            ),
          ])
          ..where(_db.userContraindications.userId.equals(profileId))
          ..orderBy([OrderingTerm.asc(_db.contraindicationTags.id)]);
    final rows = await query.get();
    return rows
        .map((r) => _tagFromRow(r.readTable(_db.contraindicationTags)))
        .toList();
  }

  Future<UserProfileRow?> _selectProfile() async {
    return (_db.select(
      _db.userProfiles,
    )..where((t) => t.id.equals(profileId))).getSingleOrNull();
  }

  UserProfile _toModel(UserProfileRow row) => UserProfile(
    id: row.id,
    name: row.name,
    birthDate: row.birthDate,
    heightCm: row.heightCm,
    weightKg: row.weightKg,
    gender: row.gender,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ContraindicationTag _tagFromRow(ContraindicationTagRow row) =>
      ContraindicationTag(id: row.id, key: row.key, labelRu: row.labelRu);
}
