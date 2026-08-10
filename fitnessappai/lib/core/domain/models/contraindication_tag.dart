/// Тег противопоказания из справочника.
class ContraindicationTag {
  const ContraindicationTag({
    this.id,
    required this.key,
    required this.labelRu,
  });

  final int? id;
  final String key;
  final String labelRu;

  ContraindicationTag copyWith({int? id, String? key, String? labelRu}) {
    return ContraindicationTag(
      id: id ?? this.id,
      key: key ?? this.key,
      labelRu: labelRu ?? this.labelRu,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ContraindicationTag &&
            other.id == id &&
            other.key == key &&
            other.labelRu == labelRu;
  }

  @override
  int get hashCode => Object.hash(id, key, labelRu);

  @override
  String toString() =>
      'ContraindicationTag(id: $id, key: $key, labelRu: $labelRu)';
}
