import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';
import 'package:fitnessappai/core/database/tables/programs.dart';

/// Отметка «не показывать предупреждения» для программы.
@DataClassName('ProgramWarningDismissalRow')
class ProgramWarningDismissals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId =>
      integer().references(Programs, #id, onDelete: KeyAction.cascade)();
  IntColumn get dismissedAt => integer().map(const DateTimeConverter())();
}
