/// Ошибка разбора JSON-ответа генерации контента.
///
/// Возникает, когда ответ не является JSON-объектом или нарушает контракт
/// `docs/llm_contract.md`: поле отсутствует, имеет неверный тип или
/// не проходит правила валидности.
class MalformedSuggestionException implements Exception {
  const MalformedSuggestionException(this.message);

  final String message;

  @override
  String toString() => 'MalformedSuggestionException: $message';
}
