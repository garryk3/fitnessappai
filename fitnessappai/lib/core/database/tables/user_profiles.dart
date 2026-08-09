import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';

/// Профиль пользователя. В БД хранится одна строка (id = 1).
@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  IntColumn get birthDate =>
      integer().nullable().map(const DateTimeConverter())();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get gender => text().nullable()();
  IntColumn get createdAt =>
      integer().nullable().map(const DateTimeConverter())();
  IntColumn get updatedAt =>
      integer().nullable().map(const DateTimeConverter())();
}
