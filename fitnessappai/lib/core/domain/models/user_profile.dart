/// Профиль пользователя. В БД хранится одна строка (id = 1).
class UserProfile {
  const UserProfile({
    this.id,
    this.name,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? name;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile copyWith({
    int? id,
    String? name,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearId = false,
    bool clearName = false,
    bool clearBirthDate = false,
    bool clearHeightCm = false,
    bool clearWeightKg = false,
    bool clearGender = false,
  }) {
    return UserProfile(
      id: clearId ? null : id ?? this.id,
      name: clearName ? null : name ?? this.name,
      birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
      heightCm: clearHeightCm ? null : heightCm ?? this.heightCm,
      weightKg: clearWeightKg ? null : weightKg ?? this.weightKg,
      gender: clearGender ? null : gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfile &&
            other.id == id &&
            other.name == name &&
            other.birthDate == birthDate &&
            other.heightCm == heightCm &&
            other.weightKg == weightKg &&
            other.gender == gender &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      birthDate,
      heightCm,
      weightKg,
      gender,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() => 'UserProfile(id: $id, name: $name)';
}
