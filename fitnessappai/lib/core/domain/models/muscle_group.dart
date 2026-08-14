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
    this.parentKey,
  });

  final int? id;
  final String key;
  final String labelRu;
  final MuscleView view;
  final String regionKey;

  /// Ключ родительской группы (например, дельты → `shoulders`) или `null`,
  /// если группа самостоятельная.
  final String? parentKey;

  MuscleGroup copyWith({
    int? id,
    String? key,
    String? labelRu,
    MuscleView? view,
    String? regionKey,
    String? parentKey,
  }) {
    return MuscleGroup(
      id: id ?? this.id,
      key: key ?? this.key,
      labelRu: labelRu ?? this.labelRu,
      view: view ?? this.view,
      regionKey: regionKey ?? this.regionKey,
      parentKey: parentKey ?? this.parentKey,
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
            other.regionKey == regionKey &&
            other.parentKey == parentKey;
  }

  @override
  int get hashCode => Object.hash(id, key, labelRu, view, regionKey, parentKey);

  @override
  String toString() => 'MuscleGroup(id: $id, key: $key, labelRu: $labelRu)';
}
