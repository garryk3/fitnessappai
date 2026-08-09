import 'package:drift/drift.dart';

/// Сохраняет [DateTime] в INTEGER-колонке как миллисекунды с эпохи.
class DateTimeConverter extends TypeConverter<DateTime, int> {
  const DateTimeConverter();

  @override
  DateTime fromSql(int fromDb) => DateTime.fromMillisecondsSinceEpoch(fromDb);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}
