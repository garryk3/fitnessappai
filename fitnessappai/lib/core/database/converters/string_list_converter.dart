import 'dart:convert';

import 'package:drift/drift.dart';

/// Сохраняет [List<String>] в TEXT-колонке как JSON-массив.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final Object? decoded;
    try {
      decoded = jsonDecode(fromDb);
    } on FormatException {
      return const <String>[];
    }
    if (decoded is! List<Object?>) return const <String>[];
    return List<String>.from(decoded);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
