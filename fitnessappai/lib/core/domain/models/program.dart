/// Программа тренировок.
class Program {
  const Program({
    this.id,
    required this.name,
    this.description = '',
    required this.daysCount,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = false,
    this.activatedAt,
    this.deactivatedAt,
    this.exerciseRestSeconds,
  });

  final int? id;
  final String name;
  final String description;
  final int daysCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Пауза в секундах между упражнениями (null — не задана).
  final int? exerciseRestSeconds;

  /// Является ли программа активной (для домашнего экрана).
  final bool isActive;

  /// Момент последней активации программы, `null` — никогда не активировалась.
  final DateTime? activatedAt;

  /// Момент последней деактивации, `null` — активна сейчас.
  final DateTime? deactivatedAt;

  Program copyWith({
    int? id,
    String? name,
    String? description,
    int? daysCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? activatedAt,
    bool clearActivatedAt = false,
    DateTime? deactivatedAt,
    bool clearDeactivatedAt = false,
    bool clearId = false,
    int? exerciseRestSeconds,
  }) {
    return Program(
      id: clearId ? null : id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      daysCount: daysCount ?? this.daysCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      activatedAt: clearActivatedAt ? null : activatedAt ?? this.activatedAt,
      deactivatedAt: clearDeactivatedAt
          ? null
          : deactivatedAt ?? this.deactivatedAt,
      exerciseRestSeconds: exerciseRestSeconds ?? this.exerciseRestSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Program &&
            other.id == id &&
            other.name == name &&
            other.description == description &&
            other.daysCount == daysCount &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt &&
            other.isActive == isActive &&
            other.activatedAt == activatedAt &&
            other.deactivatedAt == deactivatedAt &&
            other.exerciseRestSeconds == exerciseRestSeconds;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    daysCount,
    createdAt,
    updatedAt,
    isActive,
    activatedAt,
    deactivatedAt,
    exerciseRestSeconds,
  );

  @override
  String toString() => 'Program(id: $id, name: $name, daysCount: $daysCount)';
}
