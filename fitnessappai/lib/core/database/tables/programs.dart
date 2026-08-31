import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';

/// Программа тренировок.
@DataClassName('ProgramRow')
class Programs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get daysCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  /// Момент последней активации программы (null — никогда не активировалась).
  IntColumn get activatedAt =>
      integer().nullable().map(const DateTimeConverter())();

  /// Момент последней деактивации (null — активна сейчас или деактиваций не было).
  IntColumn get deactivatedAt =>
      integer().nullable().map(const DateTimeConverter())();

  /// Пауза в секундах между упражнениями (null — не задана).
  IntColumn get exerciseRestSeconds => integer().nullable()();
}
