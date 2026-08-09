import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/enum_converters.dart';

/// Справочник мышечных групп (~15) для диаграммы мускулатуры.
@DataClassName('MuscleGroupRow')
class MuscleGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get labelRu => text()();
  TextColumn get view => text().map(const MuscleViewConverter())();
  TextColumn get regionKey => text()();
}
