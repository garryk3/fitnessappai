/// Замер тела на дату. Все величины в см/кг, кроме даты — необязательны.
class BodyMeasurement {
  const BodyMeasurement({
    this.id,
    required this.date,
    this.heightCm,
    this.weightKg,
    this.neckCm,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.bicepsCm,
    this.forearmCm,
    this.thighCm,
    this.calfCm,
  });

  final int? id;
  final DateTime date;
  final double? heightCm;
  final double? weightKg;
  final double? neckCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? bicepsCm;
  final double? forearmCm;
  final double? thighCm;
  final double? calfCm;

  BodyMeasurement copyWith({
    int? id,
    DateTime? date,
    double? heightCm,
    double? weightKg,
    double? neckCm,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bicepsCm,
    double? forearmCm,
    double? thighCm,
    double? calfCm,
    bool clearId = false,
  }) {
    return BodyMeasurement(
      id: clearId ? null : id ?? this.id,
      date: date ?? this.date,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      neckCm: neckCm ?? this.neckCm,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      bicepsCm: bicepsCm ?? this.bicepsCm,
      forearmCm: forearmCm ?? this.forearmCm,
      thighCm: thighCm ?? this.thighCm,
      calfCm: calfCm ?? this.calfCm,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BodyMeasurement &&
            other.id == id &&
            other.date == date &&
            other.heightCm == heightCm &&
            other.weightKg == weightKg &&
            other.neckCm == neckCm &&
            other.chestCm == chestCm &&
            other.waistCm == waistCm &&
            other.hipsCm == hipsCm &&
            other.bicepsCm == bicepsCm &&
            other.forearmCm == forearmCm &&
            other.thighCm == thighCm &&
            other.calfCm == calfCm;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      heightCm,
      weightKg,
      neckCm,
      chestCm,
      waistCm,
      hipsCm,
      bicepsCm,
      forearmCm,
      thighCm,
      calfCm,
    );
  }

  @override
  String toString() =>
      'BodyMeasurement(id: $id, date: $date, weightKg: $weightKg)';
}
