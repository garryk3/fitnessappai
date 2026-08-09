import 'package:drift/drift.dart';

/// Хранилище key/value: версия данных, флаг `seeded`.
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
