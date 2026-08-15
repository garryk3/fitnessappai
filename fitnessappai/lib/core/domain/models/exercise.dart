import 'package:fitnessappai/core/domain/models/exercise_type.dart';

/// Упражнение пользователя.
class Exercise {
  const Exercise({
    this.id,
    required this.name,
    this.description = '',
    this.instructions = '',
    this.commonMistakes = const [],
    required this.type,
    this.thumbnailPath,
    this.animationPath,
    this.isCustom = false,
    this.hideOptional = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String description;
  final String instructions;
  final List<String> commonMistakes;
  final ExerciseType type;
  final String? thumbnailPath;
  final String? animationPath;
  final bool isCustom;
  final bool hideOptional;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise copyWith({
    int? id,
    String? name,
    String? description,
    String? instructions,
    List<String>? commonMistakes,
    ExerciseType? type,
    String? thumbnailPath,
    String? animationPath,
    bool? isCustom,
    bool? hideOptional,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearId = false,
  }) {
    return Exercise(
      id: clearId ? null : id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      type: type ?? this.type,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      animationPath: animationPath ?? this.animationPath,
      isCustom: isCustom ?? this.isCustom,
      hideOptional: hideOptional ?? this.hideOptional,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Exercise &&
            other.id == id &&
            other.name == name &&
            other.description == description &&
            other.instructions == instructions &&
            _listEquals(other.commonMistakes, commonMistakes) &&
            other.type == type &&
            other.thumbnailPath == thumbnailPath &&
            other.animationPath == animationPath &&
            other.isCustom == isCustom &&
            other.hideOptional == hideOptional &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      instructions,
      Object.hashAll(commonMistakes),
      type,
      thumbnailPath,
      animationPath,
      isCustom,
      hideOptional,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() =>
      'Exercise(id: $id, name: $name, type: $type, isCustom: $isCustom)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
