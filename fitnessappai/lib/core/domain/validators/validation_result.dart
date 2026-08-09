/// Результат валидации: список ошибок, пустой — всё корректно.
class ValidationResult {
  const ValidationResult([this.errors = const []]);

  const ValidationResult.valid() : errors = const [];

  final List<String> errors;

  bool get isValid => errors.isEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ValidationResult && _listEquals(other.errors, errors);
  }

  @override
  int get hashCode => Object.hashAll(errors);

  @override
  String toString() => 'ValidationResult($errors)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
