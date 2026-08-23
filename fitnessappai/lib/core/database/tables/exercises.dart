import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';
import 'package:fitnessappai/core/database/converters/enum_converters.dart';
import 'package:fitnessappai/core/database/converters/string_list_converter.dart';

/// Упражнение пользователя.
@DataClassName('ExerciseRow')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get instructions => text().withDefault(const Constant(''))();
  TextColumn get commonMistakes => text()
      .withDefault(const Constant('[]'))
      .map(const StringListConverter())();
  TextColumn get type => text().map(const ExerciseTypeConverter())();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get animationPath => text().nullable()();
  BlobColumn get thumbnailBlob => blob().nullable()();
  BlobColumn get animationBlob => blob().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get hideOptional => boolean().withDefault(const Constant(false))();
  BoolColumn get fixedWeight => boolean().withDefault(const Constant(false))();
  BoolColumn get perSide => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
}
