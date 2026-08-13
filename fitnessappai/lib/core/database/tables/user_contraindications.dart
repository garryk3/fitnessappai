import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/tables/contraindication_tags.dart';
import 'package:fitnessappai/core/database/tables/user_profiles.dart';

/// Связь пользователя с тегом противопоказания (M2M).
@DataClassName('UserContraindicationRow')
@TableIndex(
  name: 'user_contraindications_tag_idx',
  columns: {#contraindicationTagId},
)
class UserContraindications extends Table {
  IntColumn get userId =>
      integer().references(UserProfiles, #id, onDelete: KeyAction.cascade)();
  IntColumn get contraindicationTagId => integer().references(
    ContraindicationTags,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @override
  Set<Column> get primaryKey => {userId, contraindicationTagId};
}
