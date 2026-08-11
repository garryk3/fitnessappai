/// Ошибка валидации импортируемого файла БД.
///
/// Бросается, когда файл повреждён, не является SQLite-базой или имеет
/// несовместимую версию схемы. [message] предназначен для показа пользователю.
class SyncValidationException implements Exception {
  const SyncValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
