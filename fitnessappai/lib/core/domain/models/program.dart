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
  });

  final int? id;
  final String name;
  final String description;
  final int daysCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Является ли программа активной (для домашнего экрана).
  final bool isActive;

  Program copyWith({
    int? id,
    String? name,
    String? description,
    int? daysCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool clearId = false,
  }) {
    return Program(
      id: clearId ? null : id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      daysCount: daysCount ?? this.daysCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
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
            other.isActive == isActive;
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
  );

  @override
  String toString() => 'Program(id: $id, name: $name, daysCount: $daysCount)';
}
