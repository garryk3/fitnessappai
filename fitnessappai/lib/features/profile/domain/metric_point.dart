/// Точка графика метрики тела: дата и значение.
class MetricPoint {
  const MetricPoint({required this.date, required this.value});

  final DateTime date;
  final double value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MetricPoint && other.date == date && other.value == value;
  }

  @override
  int get hashCode => Object.hash(date, value);

  @override
  String toString() =>
      'MetricPoint(date: ${date.toIso8601String()}, value: $value)';
}
