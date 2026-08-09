/// Сторона тела для диаграммы мускулатуры.
enum MuscleView { front, back }

/// Мышечная группа справочника.
class MuscleGroup {
  const MuscleGroup({
    this.id,
    required this.key,
    required this.labelRu,
    required this.view,
    required this.regionKey,
  });

  final int? id;
  final String key;
  final String labelRu;
  final MuscleView view;
  final String regionKey;

  MuscleGroup copyWith({
    int? id,
    String? key,
    String? labelRu,
    MuscleView? view,
    String? regionKey,
  }) {
    return MuscleGroup(
      id: id ?? this.id,
      key: key ?? this.key,
      labelRu: labelRu ?? this.labelRu,
      view: view ?? this.view,
      regionKey: regionKey ?? this.regionKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MuscleGroup &&
            other.id == id &&
            other.key == key &&
            other.labelRu == labelRu &&
            other.view == view &&
            other.regionKey == regionKey;
  }

  @override
  int get hashCode => Object.hash(id, key, labelRu, view, regionKey);

  @override
  String toString() => 'MuscleGroup(id: $id, key: $key, labelRu: $labelRu)';
}
