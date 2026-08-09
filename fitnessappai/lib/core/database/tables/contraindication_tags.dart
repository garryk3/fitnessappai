import 'package:drift/drift.dart';

/// Справочник тегов противопоказаний.
@DataClassName('ContraindicationTagRow')
class ContraindicationTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get labelRu => text()();
}
