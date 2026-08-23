import 'dart:typed_data';

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
    this.thumbnailBlob,
    this.animationBlob,
    this.isCustom = false,
    this.hideOptional = false,
    this.fixedWeight = false,
    this.perSide = false,
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
  final Uint8List? thumbnailBlob;
  final Uint8List? animationBlob;
  final bool isCustom;
  final bool hideOptional;
  final bool fixedWeight;
  final bool perSide;
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
    Uint8List? thumbnailBlob,
    Uint8List? animationBlob,
    bool? isCustom,
    bool? hideOptional,
    bool? fixedWeight,
    bool? perSide,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearId = false,
    bool clearThumbnailBlob = false,
    bool clearAnimationBlob = false,
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
      thumbnailBlob: clearThumbnailBlob
          ? null
          : (thumbnailBlob ?? this.thumbnailBlob),
      animationBlob: clearAnimationBlob
          ? null
          : (animationBlob ?? this.animationBlob),
      isCustom: isCustom ?? this.isCustom,
      hideOptional: hideOptional ?? this.hideOptional,
      fixedWeight: fixedWeight ?? this.fixedWeight,
      perSide: perSide ?? this.perSide,
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
            _bytesEquals(other.thumbnailBlob, thumbnailBlob) &&
            _bytesEquals(other.animationBlob, animationBlob) &&
            other.isCustom == isCustom &&
            other.hideOptional == hideOptional &&
            other.fixedWeight == fixedWeight &&
            other.perSide == perSide &&
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
      Object.hashAll([
        thumbnailBlob?.lengthInBytes,
        animationBlob?.lengthInBytes,
      ]),
      isCustom,
      hideOptional,
      fixedWeight,
      perSide,
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

  static bool _bytesEquals(List<int>? a, List<int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
