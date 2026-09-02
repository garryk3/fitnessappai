// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String? value;
  const AppMetaData({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  AppMetaData copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => AppMetaData(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MuscleGroupsTable extends MuscleGroups
    with TableInfo<$MuscleGroupsTable, MuscleGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MuscleGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _labelRuMeta = const VerificationMeta(
    'labelRu',
  );
  @override
  late final GeneratedColumn<String> labelRu = GeneratedColumn<String>(
    'label_ru',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MuscleView, String> view =
      GeneratedColumn<String>(
        'view',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MuscleView>($MuscleGroupsTable.$converterview);
  static const VerificationMeta _regionKeyMeta = const VerificationMeta(
    'regionKey',
  );
  @override
  late final GeneratedColumn<String> regionKey = GeneratedColumn<String>(
    'region_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentKeyMeta = const VerificationMeta(
    'parentKey',
  );
  @override
  late final GeneratedColumn<String> parentKey = GeneratedColumn<String>(
    'parent_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    key,
    labelRu,
    view,
    regionKey,
    parentKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'muscle_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<MuscleGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('label_ru')) {
      context.handle(
        _labelRuMeta,
        labelRu.isAcceptableOrUnknown(data['label_ru']!, _labelRuMeta),
      );
    } else if (isInserting) {
      context.missing(_labelRuMeta);
    }
    if (data.containsKey('region_key')) {
      context.handle(
        _regionKeyMeta,
        regionKey.isAcceptableOrUnknown(data['region_key']!, _regionKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_regionKeyMeta);
    }
    if (data.containsKey('parent_key')) {
      context.handle(
        _parentKeyMeta,
        parentKey.isAcceptableOrUnknown(data['parent_key']!, _parentKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MuscleGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MuscleGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      labelRu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_ru'],
      )!,
      view: $MuscleGroupsTable.$converterview.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}view'],
        )!,
      ),
      regionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_key'],
      )!,
      parentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_key'],
      ),
    );
  }

  @override
  $MuscleGroupsTable createAlias(String alias) {
    return $MuscleGroupsTable(attachedDatabase, alias);
  }

  static TypeConverter<MuscleView, String> $converterview =
      const MuscleViewConverter();
}

class MuscleGroupRow extends DataClass implements Insertable<MuscleGroupRow> {
  final int id;
  final String key;
  final String labelRu;
  final MuscleView view;
  final String regionKey;

  /// Ключ родительской группы (например, дельты → `shoulders`) или `null`.
  final String? parentKey;
  const MuscleGroupRow({
    required this.id,
    required this.key,
    required this.labelRu,
    required this.view,
    required this.regionKey,
    this.parentKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['label_ru'] = Variable<String>(labelRu);
    {
      map['view'] = Variable<String>(
        $MuscleGroupsTable.$converterview.toSql(view),
      );
    }
    map['region_key'] = Variable<String>(regionKey);
    if (!nullToAbsent || parentKey != null) {
      map['parent_key'] = Variable<String>(parentKey);
    }
    return map;
  }

  MuscleGroupsCompanion toCompanion(bool nullToAbsent) {
    return MuscleGroupsCompanion(
      id: Value(id),
      key: Value(key),
      labelRu: Value(labelRu),
      view: Value(view),
      regionKey: Value(regionKey),
      parentKey: parentKey == null && nullToAbsent
          ? const Value.absent()
          : Value(parentKey),
    );
  }

  factory MuscleGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MuscleGroupRow(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      labelRu: serializer.fromJson<String>(json['labelRu']),
      view: serializer.fromJson<MuscleView>(json['view']),
      regionKey: serializer.fromJson<String>(json['regionKey']),
      parentKey: serializer.fromJson<String?>(json['parentKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'labelRu': serializer.toJson<String>(labelRu),
      'view': serializer.toJson<MuscleView>(view),
      'regionKey': serializer.toJson<String>(regionKey),
      'parentKey': serializer.toJson<String?>(parentKey),
    };
  }

  MuscleGroupRow copyWith({
    int? id,
    String? key,
    String? labelRu,
    MuscleView? view,
    String? regionKey,
    Value<String?> parentKey = const Value.absent(),
  }) => MuscleGroupRow(
    id: id ?? this.id,
    key: key ?? this.key,
    labelRu: labelRu ?? this.labelRu,
    view: view ?? this.view,
    regionKey: regionKey ?? this.regionKey,
    parentKey: parentKey.present ? parentKey.value : this.parentKey,
  );
  MuscleGroupRow copyWithCompanion(MuscleGroupsCompanion data) {
    return MuscleGroupRow(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      labelRu: data.labelRu.present ? data.labelRu.value : this.labelRu,
      view: data.view.present ? data.view.value : this.view,
      regionKey: data.regionKey.present ? data.regionKey.value : this.regionKey,
      parentKey: data.parentKey.present ? data.parentKey.value : this.parentKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MuscleGroupRow(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('labelRu: $labelRu, ')
          ..write('view: $view, ')
          ..write('regionKey: $regionKey, ')
          ..write('parentKey: $parentKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, labelRu, view, regionKey, parentKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MuscleGroupRow &&
          other.id == this.id &&
          other.key == this.key &&
          other.labelRu == this.labelRu &&
          other.view == this.view &&
          other.regionKey == this.regionKey &&
          other.parentKey == this.parentKey);
}

class MuscleGroupsCompanion extends UpdateCompanion<MuscleGroupRow> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> labelRu;
  final Value<MuscleView> view;
  final Value<String> regionKey;
  final Value<String?> parentKey;
  const MuscleGroupsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.labelRu = const Value.absent(),
    this.view = const Value.absent(),
    this.regionKey = const Value.absent(),
    this.parentKey = const Value.absent(),
  });
  MuscleGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String labelRu,
    required MuscleView view,
    required String regionKey,
    this.parentKey = const Value.absent(),
  }) : key = Value(key),
       labelRu = Value(labelRu),
       view = Value(view),
       regionKey = Value(regionKey);
  static Insertable<MuscleGroupRow> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? labelRu,
    Expression<String>? view,
    Expression<String>? regionKey,
    Expression<String>? parentKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (labelRu != null) 'label_ru': labelRu,
      if (view != null) 'view': view,
      if (regionKey != null) 'region_key': regionKey,
      if (parentKey != null) 'parent_key': parentKey,
    });
  }

  MuscleGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? labelRu,
    Value<MuscleView>? view,
    Value<String>? regionKey,
    Value<String?>? parentKey,
  }) {
    return MuscleGroupsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      labelRu: labelRu ?? this.labelRu,
      view: view ?? this.view,
      regionKey: regionKey ?? this.regionKey,
      parentKey: parentKey ?? this.parentKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (labelRu.present) {
      map['label_ru'] = Variable<String>(labelRu.value);
    }
    if (view.present) {
      map['view'] = Variable<String>(
        $MuscleGroupsTable.$converterview.toSql(view.value),
      );
    }
    if (regionKey.present) {
      map['region_key'] = Variable<String>(regionKey.value);
    }
    if (parentKey.present) {
      map['parent_key'] = Variable<String>(parentKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MuscleGroupsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('labelRu: $labelRu, ')
          ..write('view: $view, ')
          ..write('regionKey: $regionKey, ')
          ..write('parentKey: $parentKey')
          ..write(')'))
        .toString();
  }
}

class $ContraindicationTagsTable extends ContraindicationTags
    with TableInfo<$ContraindicationTagsTable, ContraindicationTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContraindicationTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _labelRuMeta = const VerificationMeta(
    'labelRu',
  );
  @override
  late final GeneratedColumn<String> labelRu = GeneratedColumn<String>(
    'label_ru',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, labelRu];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contraindication_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContraindicationTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('label_ru')) {
      context.handle(
        _labelRuMeta,
        labelRu.isAcceptableOrUnknown(data['label_ru']!, _labelRuMeta),
      );
    } else if (isInserting) {
      context.missing(_labelRuMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContraindicationTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContraindicationTagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      labelRu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_ru'],
      )!,
    );
  }

  @override
  $ContraindicationTagsTable createAlias(String alias) {
    return $ContraindicationTagsTable(attachedDatabase, alias);
  }
}

class ContraindicationTagRow extends DataClass
    implements Insertable<ContraindicationTagRow> {
  final int id;
  final String key;
  final String labelRu;
  const ContraindicationTagRow({
    required this.id,
    required this.key,
    required this.labelRu,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['label_ru'] = Variable<String>(labelRu);
    return map;
  }

  ContraindicationTagsCompanion toCompanion(bool nullToAbsent) {
    return ContraindicationTagsCompanion(
      id: Value(id),
      key: Value(key),
      labelRu: Value(labelRu),
    );
  }

  factory ContraindicationTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContraindicationTagRow(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      labelRu: serializer.fromJson<String>(json['labelRu']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'labelRu': serializer.toJson<String>(labelRu),
    };
  }

  ContraindicationTagRow copyWith({int? id, String? key, String? labelRu}) =>
      ContraindicationTagRow(
        id: id ?? this.id,
        key: key ?? this.key,
        labelRu: labelRu ?? this.labelRu,
      );
  ContraindicationTagRow copyWithCompanion(ContraindicationTagsCompanion data) {
    return ContraindicationTagRow(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      labelRu: data.labelRu.present ? data.labelRu.value : this.labelRu,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContraindicationTagRow(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('labelRu: $labelRu')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, labelRu);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContraindicationTagRow &&
          other.id == this.id &&
          other.key == this.key &&
          other.labelRu == this.labelRu);
}

class ContraindicationTagsCompanion
    extends UpdateCompanion<ContraindicationTagRow> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> labelRu;
  const ContraindicationTagsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.labelRu = const Value.absent(),
  });
  ContraindicationTagsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String labelRu,
  }) : key = Value(key),
       labelRu = Value(labelRu);
  static Insertable<ContraindicationTagRow> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? labelRu,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (labelRu != null) 'label_ru': labelRu,
    });
  }

  ContraindicationTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? labelRu,
  }) {
    return ContraindicationTagsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      labelRu: labelRu ?? this.labelRu,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (labelRu.present) {
      map['label_ru'] = Variable<String>(labelRu.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContraindicationTagsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('labelRu: $labelRu')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, ExerciseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  commonMistakes = GeneratedColumn<String>(
    'common_mistakes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($ExercisesTable.$convertercommonMistakes);
  @override
  late final GeneratedColumnWithTypeConverter<ExerciseType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExerciseType>($ExercisesTable.$convertertype);
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _animationPathMeta = const VerificationMeta(
    'animationPath',
  );
  @override
  late final GeneratedColumn<String> animationPath = GeneratedColumn<String>(
    'animation_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailBlobMeta = const VerificationMeta(
    'thumbnailBlob',
  );
  @override
  late final GeneratedColumn<Uint8List> thumbnailBlob =
      GeneratedColumn<Uint8List>(
        'thumbnail_blob',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _animationBlobMeta = const VerificationMeta(
    'animationBlob',
  );
  @override
  late final GeneratedColumn<Uint8List> animationBlob =
      GeneratedColumn<Uint8List>(
        'animation_blob',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hideOptionalMeta = const VerificationMeta(
    'hideOptional',
  );
  @override
  late final GeneratedColumn<bool> hideOptional = GeneratedColumn<bool>(
    'hide_optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hide_optional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fixedWeightMeta = const VerificationMeta(
    'fixedWeight',
  );
  @override
  late final GeneratedColumn<bool> fixedWeight = GeneratedColumn<bool>(
    'fixed_weight',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fixed_weight" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _perSideMeta = const VerificationMeta(
    'perSide',
  );
  @override
  late final GeneratedColumn<bool> perSide = GeneratedColumn<bool>(
    'per_side',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("per_side" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ExercisesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ExercisesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    instructions,
    commonMistakes,
    type,
    thumbnailPath,
    animationPath,
    thumbnailBlob,
    animationBlob,
    isCustom,
    hideOptional,
    fixedWeight,
    perSide,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('animation_path')) {
      context.handle(
        _animationPathMeta,
        animationPath.isAcceptableOrUnknown(
          data['animation_path']!,
          _animationPathMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_blob')) {
      context.handle(
        _thumbnailBlobMeta,
        thumbnailBlob.isAcceptableOrUnknown(
          data['thumbnail_blob']!,
          _thumbnailBlobMeta,
        ),
      );
    }
    if (data.containsKey('animation_blob')) {
      context.handle(
        _animationBlobMeta,
        animationBlob.isAcceptableOrUnknown(
          data['animation_blob']!,
          _animationBlobMeta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('hide_optional')) {
      context.handle(
        _hideOptionalMeta,
        hideOptional.isAcceptableOrUnknown(
          data['hide_optional']!,
          _hideOptionalMeta,
        ),
      );
    }
    if (data.containsKey('fixed_weight')) {
      context.handle(
        _fixedWeightMeta,
        fixedWeight.isAcceptableOrUnknown(
          data['fixed_weight']!,
          _fixedWeightMeta,
        ),
      );
    }
    if (data.containsKey('per_side')) {
      context.handle(
        _perSideMeta,
        perSide.isAcceptableOrUnknown(data['per_side']!, _perSideMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      )!,
      commonMistakes: $ExercisesTable.$convertercommonMistakes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}common_mistakes'],
        )!,
      ),
      type: $ExercisesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      animationPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}animation_path'],
      ),
      thumbnailBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}thumbnail_blob'],
      ),
      animationBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}animation_blob'],
      ),
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      hideOptional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_optional'],
      )!,
      fixedWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fixed_weight'],
      )!,
      perSide: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}per_side'],
      )!,
      createdAt: $ExercisesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ExercisesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertercommonMistakes =
      const StringListConverter();
  static TypeConverter<ExerciseType, String> $convertertype =
      const ExerciseTypeConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
}

class ExerciseRow extends DataClass implements Insertable<ExerciseRow> {
  final int id;
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
  const ExerciseRow({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.commonMistakes,
    required this.type,
    this.thumbnailPath,
    this.animationPath,
    this.thumbnailBlob,
    this.animationBlob,
    required this.isCustom,
    required this.hideOptional,
    required this.fixedWeight,
    required this.perSide,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['instructions'] = Variable<String>(instructions);
    {
      map['common_mistakes'] = Variable<String>(
        $ExercisesTable.$convertercommonMistakes.toSql(commonMistakes),
      );
    }
    {
      map['type'] = Variable<String>(
        $ExercisesTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || animationPath != null) {
      map['animation_path'] = Variable<String>(animationPath);
    }
    if (!nullToAbsent || thumbnailBlob != null) {
      map['thumbnail_blob'] = Variable<Uint8List>(thumbnailBlob);
    }
    if (!nullToAbsent || animationBlob != null) {
      map['animation_blob'] = Variable<Uint8List>(animationBlob);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['hide_optional'] = Variable<bool>(hideOptional);
    map['fixed_weight'] = Variable<bool>(fixedWeight);
    map['per_side'] = Variable<bool>(perSide);
    {
      map['created_at'] = Variable<int>(
        $ExercisesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $ExercisesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      instructions: Value(instructions),
      commonMistakes: Value(commonMistakes),
      type: Value(type),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      animationPath: animationPath == null && nullToAbsent
          ? const Value.absent()
          : Value(animationPath),
      thumbnailBlob: thumbnailBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailBlob),
      animationBlob: animationBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(animationBlob),
      isCustom: Value(isCustom),
      hideOptional: Value(hideOptional),
      fixedWeight: Value(fixedWeight),
      perSide: Value(perSide),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExerciseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      instructions: serializer.fromJson<String>(json['instructions']),
      commonMistakes: serializer.fromJson<List<String>>(json['commonMistakes']),
      type: serializer.fromJson<ExerciseType>(json['type']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      animationPath: serializer.fromJson<String?>(json['animationPath']),
      thumbnailBlob: serializer.fromJson<Uint8List?>(json['thumbnailBlob']),
      animationBlob: serializer.fromJson<Uint8List?>(json['animationBlob']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      hideOptional: serializer.fromJson<bool>(json['hideOptional']),
      fixedWeight: serializer.fromJson<bool>(json['fixedWeight']),
      perSide: serializer.fromJson<bool>(json['perSide']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'instructions': serializer.toJson<String>(instructions),
      'commonMistakes': serializer.toJson<List<String>>(commonMistakes),
      'type': serializer.toJson<ExerciseType>(type),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'animationPath': serializer.toJson<String?>(animationPath),
      'thumbnailBlob': serializer.toJson<Uint8List?>(thumbnailBlob),
      'animationBlob': serializer.toJson<Uint8List?>(animationBlob),
      'isCustom': serializer.toJson<bool>(isCustom),
      'hideOptional': serializer.toJson<bool>(hideOptional),
      'fixedWeight': serializer.toJson<bool>(fixedWeight),
      'perSide': serializer.toJson<bool>(perSide),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExerciseRow copyWith({
    int? id,
    String? name,
    String? description,
    String? instructions,
    List<String>? commonMistakes,
    ExerciseType? type,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<String?> animationPath = const Value.absent(),
    Value<Uint8List?> thumbnailBlob = const Value.absent(),
    Value<Uint8List?> animationBlob = const Value.absent(),
    bool? isCustom,
    bool? hideOptional,
    bool? fixedWeight,
    bool? perSide,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExerciseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    instructions: instructions ?? this.instructions,
    commonMistakes: commonMistakes ?? this.commonMistakes,
    type: type ?? this.type,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    animationPath: animationPath.present
        ? animationPath.value
        : this.animationPath,
    thumbnailBlob: thumbnailBlob.present
        ? thumbnailBlob.value
        : this.thumbnailBlob,
    animationBlob: animationBlob.present
        ? animationBlob.value
        : this.animationBlob,
    isCustom: isCustom ?? this.isCustom,
    hideOptional: hideOptional ?? this.hideOptional,
    fixedWeight: fixedWeight ?? this.fixedWeight,
    perSide: perSide ?? this.perSide,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExerciseRow copyWithCompanion(ExercisesCompanion data) {
    return ExerciseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      commonMistakes: data.commonMistakes.present
          ? data.commonMistakes.value
          : this.commonMistakes,
      type: data.type.present ? data.type.value : this.type,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      animationPath: data.animationPath.present
          ? data.animationPath.value
          : this.animationPath,
      thumbnailBlob: data.thumbnailBlob.present
          ? data.thumbnailBlob.value
          : this.thumbnailBlob,
      animationBlob: data.animationBlob.present
          ? data.animationBlob.value
          : this.animationBlob,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      hideOptional: data.hideOptional.present
          ? data.hideOptional.value
          : this.hideOptional,
      fixedWeight: data.fixedWeight.present
          ? data.fixedWeight.value
          : this.fixedWeight,
      perSide: data.perSide.present ? data.perSide.value : this.perSide,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('instructions: $instructions, ')
          ..write('commonMistakes: $commonMistakes, ')
          ..write('type: $type, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('animationPath: $animationPath, ')
          ..write('thumbnailBlob: $thumbnailBlob, ')
          ..write('animationBlob: $animationBlob, ')
          ..write('isCustom: $isCustom, ')
          ..write('hideOptional: $hideOptional, ')
          ..write('fixedWeight: $fixedWeight, ')
          ..write('perSide: $perSide, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    instructions,
    commonMistakes,
    type,
    thumbnailPath,
    animationPath,
    $driftBlobEquality.hash(thumbnailBlob),
    $driftBlobEquality.hash(animationBlob),
    isCustom,
    hideOptional,
    fixedWeight,
    perSide,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.instructions == this.instructions &&
          other.commonMistakes == this.commonMistakes &&
          other.type == this.type &&
          other.thumbnailPath == this.thumbnailPath &&
          other.animationPath == this.animationPath &&
          $driftBlobEquality.equals(other.thumbnailBlob, this.thumbnailBlob) &&
          $driftBlobEquality.equals(other.animationBlob, this.animationBlob) &&
          other.isCustom == this.isCustom &&
          other.hideOptional == this.hideOptional &&
          other.fixedWeight == this.fixedWeight &&
          other.perSide == this.perSide &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExercisesCompanion extends UpdateCompanion<ExerciseRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> instructions;
  final Value<List<String>> commonMistakes;
  final Value<ExerciseType> type;
  final Value<String?> thumbnailPath;
  final Value<String?> animationPath;
  final Value<Uint8List?> thumbnailBlob;
  final Value<Uint8List?> animationBlob;
  final Value<bool> isCustom;
  final Value<bool> hideOptional;
  final Value<bool> fixedWeight;
  final Value<bool> perSide;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.instructions = const Value.absent(),
    this.commonMistakes = const Value.absent(),
    this.type = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.animationPath = const Value.absent(),
    this.thumbnailBlob = const Value.absent(),
    this.animationBlob = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.hideOptional = const Value.absent(),
    this.fixedWeight = const Value.absent(),
    this.perSide = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.instructions = const Value.absent(),
    this.commonMistakes = const Value.absent(),
    required ExerciseType type,
    this.thumbnailPath = const Value.absent(),
    this.animationPath = const Value.absent(),
    this.thumbnailBlob = const Value.absent(),
    this.animationBlob = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.hideOptional = const Value.absent(),
    this.fixedWeight = const Value.absent(),
    this.perSide = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExerciseRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? instructions,
    Expression<String>? commonMistakes,
    Expression<String>? type,
    Expression<String>? thumbnailPath,
    Expression<String>? animationPath,
    Expression<Uint8List>? thumbnailBlob,
    Expression<Uint8List>? animationBlob,
    Expression<bool>? isCustom,
    Expression<bool>? hideOptional,
    Expression<bool>? fixedWeight,
    Expression<bool>? perSide,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (commonMistakes != null) 'common_mistakes': commonMistakes,
      if (type != null) 'type': type,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (animationPath != null) 'animation_path': animationPath,
      if (thumbnailBlob != null) 'thumbnail_blob': thumbnailBlob,
      if (animationBlob != null) 'animation_blob': animationBlob,
      if (isCustom != null) 'is_custom': isCustom,
      if (hideOptional != null) 'hide_optional': hideOptional,
      if (fixedWeight != null) 'fixed_weight': fixedWeight,
      if (perSide != null) 'per_side': perSide,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? instructions,
    Value<List<String>>? commonMistakes,
    Value<ExerciseType>? type,
    Value<String?>? thumbnailPath,
    Value<String?>? animationPath,
    Value<Uint8List?>? thumbnailBlob,
    Value<Uint8List?>? animationBlob,
    Value<bool>? isCustom,
    Value<bool>? hideOptional,
    Value<bool>? fixedWeight,
    Value<bool>? perSide,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      type: type ?? this.type,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      animationPath: animationPath ?? this.animationPath,
      thumbnailBlob: thumbnailBlob ?? this.thumbnailBlob,
      animationBlob: animationBlob ?? this.animationBlob,
      isCustom: isCustom ?? this.isCustom,
      hideOptional: hideOptional ?? this.hideOptional,
      fixedWeight: fixedWeight ?? this.fixedWeight,
      perSide: perSide ?? this.perSide,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (commonMistakes.present) {
      map['common_mistakes'] = Variable<String>(
        $ExercisesTable.$convertercommonMistakes.toSql(commonMistakes.value),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ExercisesTable.$convertertype.toSql(type.value),
      );
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (animationPath.present) {
      map['animation_path'] = Variable<String>(animationPath.value);
    }
    if (thumbnailBlob.present) {
      map['thumbnail_blob'] = Variable<Uint8List>(thumbnailBlob.value);
    }
    if (animationBlob.present) {
      map['animation_blob'] = Variable<Uint8List>(animationBlob.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (hideOptional.present) {
      map['hide_optional'] = Variable<bool>(hideOptional.value);
    }
    if (fixedWeight.present) {
      map['fixed_weight'] = Variable<bool>(fixedWeight.value);
    }
    if (perSide.present) {
      map['per_side'] = Variable<bool>(perSide.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ExercisesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ExercisesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('instructions: $instructions, ')
          ..write('commonMistakes: $commonMistakes, ')
          ..write('type: $type, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('animationPath: $animationPath, ')
          ..write('thumbnailBlob: $thumbnailBlob, ')
          ..write('animationBlob: $animationBlob, ')
          ..write('isCustom: $isCustom, ')
          ..write('hideOptional: $hideOptional, ')
          ..write('fixedWeight: $fixedWeight, ')
          ..write('perSide: $perSide, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> birthDate =
      GeneratedColumn<int>(
        'birth_date',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserProfilesTable.$converterbirthDaten);
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserProfilesTable.$convertercreatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserProfilesTable.$converterupdatedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    birthDate,
    heightCm,
    weightKg,
    gender,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      birthDate: $UserProfilesTable.$converterbirthDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}birth_date'],
        ),
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      createdAt: $UserProfilesTable.$convertercreatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        ),
      ),
      updatedAt: $UserProfilesTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        ),
      ),
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterbirthDate =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterbirthDaten =
      NullAwareTypeConverter.wrap($converterbirthDate);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $convertercreatedAtn =
      NullAwareTypeConverter.wrap($convertercreatedAt);
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterupdatedAtn =
      NullAwareTypeConverter.wrap($converterupdatedAt);
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final String? name;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const UserProfileRow({
    required this.id,
    this.name,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<int>(
        $UserProfilesTable.$converterbirthDaten.toSql(birthDate),
      );
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(
        $UserProfilesTable.$convertercreatedAtn.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(
        $UserProfilesTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      gender: serializer.fromJson<String?>(json['gender']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'gender': serializer.toJson<String?>(gender),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  UserProfileRow copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    Value<DateTime?> birthDate = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => UserProfileRow(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    gender: gender.present ? gender.value : this.gender,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  UserProfileRow copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      gender: data.gender.present ? data.gender.value : this.gender,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('gender: $gender, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    birthDate,
    heightCm,
    weightKg,
    gender,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.gender == this.gender &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<String?> name;
  final Value<DateTime?> birthDate;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<String?> gender;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.gender = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.gender = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? birthDate,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? gender,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (birthDate != null) 'birth_date': birthDate,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (gender != null) 'gender': gender,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<DateTime?>? birthDate,
    Value<double?>? heightCm,
    Value<double?>? weightKg,
    Value<String?>? gender,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<int>(
        $UserProfilesTable.$converterbirthDaten.toSql(birthDate.value),
      );
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $UserProfilesTable.$convertercreatedAtn.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $UserProfilesTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('gender: $gender, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseMusclesTable extends ExerciseMuscles
    with TableInfo<$ExerciseMusclesTable, ExerciseMuscleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseMusclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _muscleGroupIdMeta = const VerificationMeta(
    'muscleGroupId',
  );
  @override
  late final GeneratedColumn<int> muscleGroupId = GeneratedColumn<int>(
    'muscle_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES muscle_groups (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MuscleIntensity, String>
  intensity = GeneratedColumn<String>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MuscleIntensity>($ExerciseMusclesTable.$converterintensity);
  @override
  List<GeneratedColumn> get $columns => [exerciseId, muscleGroupId, intensity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_muscles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseMuscleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('muscle_group_id')) {
      context.handle(
        _muscleGroupIdMeta,
        muscleGroupId.isAcceptableOrUnknown(
          data['muscle_group_id']!,
          _muscleGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_muscleGroupIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId, muscleGroupId};
  @override
  ExerciseMuscleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseMuscleRow(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      muscleGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}muscle_group_id'],
      )!,
      intensity: $ExerciseMusclesTable.$converterintensity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}intensity'],
        )!,
      ),
    );
  }

  @override
  $ExerciseMusclesTable createAlias(String alias) {
    return $ExerciseMusclesTable(attachedDatabase, alias);
  }

  static TypeConverter<MuscleIntensity, String> $converterintensity =
      const MuscleIntensityConverter();
}

class ExerciseMuscleRow extends DataClass
    implements Insertable<ExerciseMuscleRow> {
  final int exerciseId;
  final int muscleGroupId;
  final MuscleIntensity intensity;
  const ExerciseMuscleRow({
    required this.exerciseId,
    required this.muscleGroupId,
    required this.intensity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<int>(exerciseId);
    map['muscle_group_id'] = Variable<int>(muscleGroupId);
    {
      map['intensity'] = Variable<String>(
        $ExerciseMusclesTable.$converterintensity.toSql(intensity),
      );
    }
    return map;
  }

  ExerciseMusclesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseMusclesCompanion(
      exerciseId: Value(exerciseId),
      muscleGroupId: Value(muscleGroupId),
      intensity: Value(intensity),
    );
  }

  factory ExerciseMuscleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseMuscleRow(
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      muscleGroupId: serializer.fromJson<int>(json['muscleGroupId']),
      intensity: serializer.fromJson<MuscleIntensity>(json['intensity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<int>(exerciseId),
      'muscleGroupId': serializer.toJson<int>(muscleGroupId),
      'intensity': serializer.toJson<MuscleIntensity>(intensity),
    };
  }

  ExerciseMuscleRow copyWith({
    int? exerciseId,
    int? muscleGroupId,
    MuscleIntensity? intensity,
  }) => ExerciseMuscleRow(
    exerciseId: exerciseId ?? this.exerciseId,
    muscleGroupId: muscleGroupId ?? this.muscleGroupId,
    intensity: intensity ?? this.intensity,
  );
  ExerciseMuscleRow copyWithCompanion(ExerciseMusclesCompanion data) {
    return ExerciseMuscleRow(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      muscleGroupId: data.muscleGroupId.present
          ? data.muscleGroupId.value
          : this.muscleGroupId,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseMuscleRow(')
          ..write('exerciseId: $exerciseId, ')
          ..write('muscleGroupId: $muscleGroupId, ')
          ..write('intensity: $intensity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, muscleGroupId, intensity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseMuscleRow &&
          other.exerciseId == this.exerciseId &&
          other.muscleGroupId == this.muscleGroupId &&
          other.intensity == this.intensity);
}

class ExerciseMusclesCompanion extends UpdateCompanion<ExerciseMuscleRow> {
  final Value<int> exerciseId;
  final Value<int> muscleGroupId;
  final Value<MuscleIntensity> intensity;
  final Value<int> rowid;
  const ExerciseMusclesCompanion({
    this.exerciseId = const Value.absent(),
    this.muscleGroupId = const Value.absent(),
    this.intensity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseMusclesCompanion.insert({
    required int exerciseId,
    required int muscleGroupId,
    required MuscleIntensity intensity,
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       muscleGroupId = Value(muscleGroupId),
       intensity = Value(intensity);
  static Insertable<ExerciseMuscleRow> custom({
    Expression<int>? exerciseId,
    Expression<int>? muscleGroupId,
    Expression<String>? intensity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (muscleGroupId != null) 'muscle_group_id': muscleGroupId,
      if (intensity != null) 'intensity': intensity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseMusclesCompanion copyWith({
    Value<int>? exerciseId,
    Value<int>? muscleGroupId,
    Value<MuscleIntensity>? intensity,
    Value<int>? rowid,
  }) {
    return ExerciseMusclesCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      muscleGroupId: muscleGroupId ?? this.muscleGroupId,
      intensity: intensity ?? this.intensity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (muscleGroupId.present) {
      map['muscle_group_id'] = Variable<int>(muscleGroupId.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<String>(
        $ExerciseMusclesTable.$converterintensity.toSql(intensity.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseMusclesCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('muscleGroupId: $muscleGroupId, ')
          ..write('intensity: $intensity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseContraindicationsTable extends ExerciseContraindications
    with
        TableInfo<
          $ExerciseContraindicationsTable,
          ExerciseContraindicationRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseContraindicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contraindicationTagIdMeta =
      const VerificationMeta('contraindicationTagId');
  @override
  late final GeneratedColumn<int> contraindicationTagId = GeneratedColumn<int>(
    'contraindication_tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contraindication_tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [exerciseId, contraindicationTagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_contraindications';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseContraindicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('contraindication_tag_id')) {
      context.handle(
        _contraindicationTagIdMeta,
        contraindicationTagId.isAcceptableOrUnknown(
          data['contraindication_tag_id']!,
          _contraindicationTagIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contraindicationTagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId, contraindicationTagId};
  @override
  ExerciseContraindicationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseContraindicationRow(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      contraindicationTagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contraindication_tag_id'],
      )!,
    );
  }

  @override
  $ExerciseContraindicationsTable createAlias(String alias) {
    return $ExerciseContraindicationsTable(attachedDatabase, alias);
  }
}

class ExerciseContraindicationRow extends DataClass
    implements Insertable<ExerciseContraindicationRow> {
  final int exerciseId;
  final int contraindicationTagId;
  const ExerciseContraindicationRow({
    required this.exerciseId,
    required this.contraindicationTagId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<int>(exerciseId);
    map['contraindication_tag_id'] = Variable<int>(contraindicationTagId);
    return map;
  }

  ExerciseContraindicationsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseContraindicationsCompanion(
      exerciseId: Value(exerciseId),
      contraindicationTagId: Value(contraindicationTagId),
    );
  }

  factory ExerciseContraindicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseContraindicationRow(
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      contraindicationTagId: serializer.fromJson<int>(
        json['contraindicationTagId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<int>(exerciseId),
      'contraindicationTagId': serializer.toJson<int>(contraindicationTagId),
    };
  }

  ExerciseContraindicationRow copyWith({
    int? exerciseId,
    int? contraindicationTagId,
  }) => ExerciseContraindicationRow(
    exerciseId: exerciseId ?? this.exerciseId,
    contraindicationTagId: contraindicationTagId ?? this.contraindicationTagId,
  );
  ExerciseContraindicationRow copyWithCompanion(
    ExerciseContraindicationsCompanion data,
  ) {
    return ExerciseContraindicationRow(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      contraindicationTagId: data.contraindicationTagId.present
          ? data.contraindicationTagId.value
          : this.contraindicationTagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseContraindicationRow(')
          ..write('exerciseId: $exerciseId, ')
          ..write('contraindicationTagId: $contraindicationTagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, contraindicationTagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseContraindicationRow &&
          other.exerciseId == this.exerciseId &&
          other.contraindicationTagId == this.contraindicationTagId);
}

class ExerciseContraindicationsCompanion
    extends UpdateCompanion<ExerciseContraindicationRow> {
  final Value<int> exerciseId;
  final Value<int> contraindicationTagId;
  final Value<int> rowid;
  const ExerciseContraindicationsCompanion({
    this.exerciseId = const Value.absent(),
    this.contraindicationTagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseContraindicationsCompanion.insert({
    required int exerciseId,
    required int contraindicationTagId,
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       contraindicationTagId = Value(contraindicationTagId);
  static Insertable<ExerciseContraindicationRow> custom({
    Expression<int>? exerciseId,
    Expression<int>? contraindicationTagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (contraindicationTagId != null)
        'contraindication_tag_id': contraindicationTagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseContraindicationsCompanion copyWith({
    Value<int>? exerciseId,
    Value<int>? contraindicationTagId,
    Value<int>? rowid,
  }) {
    return ExerciseContraindicationsCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      contraindicationTagId:
          contraindicationTagId ?? this.contraindicationTagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (contraindicationTagId.present) {
      map['contraindication_tag_id'] = Variable<int>(
        contraindicationTagId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseContraindicationsCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('contraindicationTagId: $contraindicationTagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserContraindicationsTable extends UserContraindications
    with TableInfo<$UserContraindicationsTable, UserContraindicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserContraindicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contraindicationTagIdMeta =
      const VerificationMeta('contraindicationTagId');
  @override
  late final GeneratedColumn<int> contraindicationTagId = GeneratedColumn<int>(
    'contraindication_tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contraindication_tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [userId, contraindicationTagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_contraindications';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserContraindicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('contraindication_tag_id')) {
      context.handle(
        _contraindicationTagIdMeta,
        contraindicationTagId.isAcceptableOrUnknown(
          data['contraindication_tag_id']!,
          _contraindicationTagIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contraindicationTagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, contraindicationTagId};
  @override
  UserContraindicationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserContraindicationRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      contraindicationTagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contraindication_tag_id'],
      )!,
    );
  }

  @override
  $UserContraindicationsTable createAlias(String alias) {
    return $UserContraindicationsTable(attachedDatabase, alias);
  }
}

class UserContraindicationRow extends DataClass
    implements Insertable<UserContraindicationRow> {
  final int userId;
  final int contraindicationTagId;
  const UserContraindicationRow({
    required this.userId,
    required this.contraindicationTagId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['contraindication_tag_id'] = Variable<int>(contraindicationTagId);
    return map;
  }

  UserContraindicationsCompanion toCompanion(bool nullToAbsent) {
    return UserContraindicationsCompanion(
      userId: Value(userId),
      contraindicationTagId: Value(contraindicationTagId),
    );
  }

  factory UserContraindicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserContraindicationRow(
      userId: serializer.fromJson<int>(json['userId']),
      contraindicationTagId: serializer.fromJson<int>(
        json['contraindicationTagId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'contraindicationTagId': serializer.toJson<int>(contraindicationTagId),
    };
  }

  UserContraindicationRow copyWith({int? userId, int? contraindicationTagId}) =>
      UserContraindicationRow(
        userId: userId ?? this.userId,
        contraindicationTagId:
            contraindicationTagId ?? this.contraindicationTagId,
      );
  UserContraindicationRow copyWithCompanion(
    UserContraindicationsCompanion data,
  ) {
    return UserContraindicationRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      contraindicationTagId: data.contraindicationTagId.present
          ? data.contraindicationTagId.value
          : this.contraindicationTagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserContraindicationRow(')
          ..write('userId: $userId, ')
          ..write('contraindicationTagId: $contraindicationTagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, contraindicationTagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserContraindicationRow &&
          other.userId == this.userId &&
          other.contraindicationTagId == this.contraindicationTagId);
}

class UserContraindicationsCompanion
    extends UpdateCompanion<UserContraindicationRow> {
  final Value<int> userId;
  final Value<int> contraindicationTagId;
  final Value<int> rowid;
  const UserContraindicationsCompanion({
    this.userId = const Value.absent(),
    this.contraindicationTagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserContraindicationsCompanion.insert({
    required int userId,
    required int contraindicationTagId,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       contraindicationTagId = Value(contraindicationTagId);
  static Insertable<UserContraindicationRow> custom({
    Expression<int>? userId,
    Expression<int>? contraindicationTagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (contraindicationTagId != null)
        'contraindication_tag_id': contraindicationTagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserContraindicationsCompanion copyWith({
    Value<int>? userId,
    Value<int>? contraindicationTagId,
    Value<int>? rowid,
  }) {
    return UserContraindicationsCompanion(
      userId: userId ?? this.userId,
      contraindicationTagId:
          contraindicationTagId ?? this.contraindicationTagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (contraindicationTagId.present) {
      map['contraindication_tag_id'] = Variable<int>(
        contraindicationTagId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserContraindicationsCompanion(')
          ..write('userId: $userId, ')
          ..write('contraindicationTagId: $contraindicationTagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgramsTable extends Programs
    with TableInfo<$ProgramsTable, ProgramRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _daysCountMeta = const VerificationMeta(
    'daysCount',
  );
  @override
  late final GeneratedColumn<int> daysCount = GeneratedColumn<int>(
    'days_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ProgramsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ProgramsTable.$converterupdatedAt);
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> activatedAt =
      GeneratedColumn<int>(
        'activated_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ProgramsTable.$converteractivatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deactivatedAt =
      GeneratedColumn<int>(
        'deactivated_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ProgramsTable.$converterdeactivatedAtn);
  static const VerificationMeta _exerciseRestSecondsMeta =
      const VerificationMeta('exerciseRestSeconds');
  @override
  late final GeneratedColumn<int> exerciseRestSeconds = GeneratedColumn<int>(
    'exercise_rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('days_count')) {
      context.handle(
        _daysCountMeta,
        daysCount.isAcceptableOrUnknown(data['days_count']!, _daysCountMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('exercise_rest_seconds')) {
      context.handle(
        _exerciseRestSecondsMeta,
        exerciseRestSeconds.isAcceptableOrUnknown(
          data['exercise_rest_seconds']!,
          _exerciseRestSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      daysCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_count'],
      )!,
      createdAt: $ProgramsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ProgramsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      activatedAt: $ProgramsTable.$converteractivatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}activated_at'],
        ),
      ),
      deactivatedAt: $ProgramsTable.$converterdeactivatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deactivated_at'],
        ),
      ),
      exerciseRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_rest_seconds'],
      ),
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converteractivatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converteractivatedAtn =
      NullAwareTypeConverter.wrap($converteractivatedAt);
  static TypeConverter<DateTime, int> $converterdeactivatedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeactivatedAtn =
      NullAwareTypeConverter.wrap($converterdeactivatedAt);
}

class ProgramRow extends DataClass implements Insertable<ProgramRow> {
  final int id;
  final String name;
  final String description;
  final int daysCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  /// Момент последней активации программы (null — никогда не активировалась).
  final DateTime? activatedAt;

  /// Момент последней деактивации (null — активна сейчас или деактиваций не было).
  final DateTime? deactivatedAt;

  /// Пауза в секундах между упражнениями (null — не задана).
  final int? exerciseRestSeconds;
  const ProgramRow({
    required this.id,
    required this.name,
    required this.description,
    required this.daysCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.activatedAt,
    this.deactivatedAt,
    this.exerciseRestSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['days_count'] = Variable<int>(daysCount);
    {
      map['created_at'] = Variable<int>(
        $ProgramsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $ProgramsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || activatedAt != null) {
      map['activated_at'] = Variable<int>(
        $ProgramsTable.$converteractivatedAtn.toSql(activatedAt),
      );
    }
    if (!nullToAbsent || deactivatedAt != null) {
      map['deactivated_at'] = Variable<int>(
        $ProgramsTable.$converterdeactivatedAtn.toSql(deactivatedAt),
      );
    }
    if (!nullToAbsent || exerciseRestSeconds != null) {
      map['exercise_rest_seconds'] = Variable<int>(exerciseRestSeconds);
    }
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      daysCount: Value(daysCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isActive: Value(isActive),
      activatedAt: activatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(activatedAt),
      deactivatedAt: deactivatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deactivatedAt),
      exerciseRestSeconds: exerciseRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseRestSeconds),
    );
  }

  factory ProgramRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      daysCount: serializer.fromJson<int>(json['daysCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      activatedAt: serializer.fromJson<DateTime?>(json['activatedAt']),
      deactivatedAt: serializer.fromJson<DateTime?>(json['deactivatedAt']),
      exerciseRestSeconds: serializer.fromJson<int?>(
        json['exerciseRestSeconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'daysCount': serializer.toJson<int>(daysCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isActive': serializer.toJson<bool>(isActive),
      'activatedAt': serializer.toJson<DateTime?>(activatedAt),
      'deactivatedAt': serializer.toJson<DateTime?>(deactivatedAt),
      'exerciseRestSeconds': serializer.toJson<int?>(exerciseRestSeconds),
    };
  }

  ProgramRow copyWith({
    int? id,
    String? name,
    String? description,
    int? daysCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Value<DateTime?> activatedAt = const Value.absent(),
    Value<DateTime?> deactivatedAt = const Value.absent(),
    Value<int?> exerciseRestSeconds = const Value.absent(),
  }) => ProgramRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    daysCount: daysCount ?? this.daysCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isActive: isActive ?? this.isActive,
    activatedAt: activatedAt.present ? activatedAt.value : this.activatedAt,
    deactivatedAt: deactivatedAt.present
        ? deactivatedAt.value
        : this.deactivatedAt,
    exerciseRestSeconds: exerciseRestSeconds.present
        ? exerciseRestSeconds.value
        : this.exerciseRestSeconds,
  );
  ProgramRow copyWithCompanion(ProgramsCompanion data) {
    return ProgramRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      daysCount: data.daysCount.present ? data.daysCount.value : this.daysCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      activatedAt: data.activatedAt.present
          ? data.activatedAt.value
          : this.activatedAt,
      deactivatedAt: data.deactivatedAt.present
          ? data.deactivatedAt.value
          : this.deactivatedAt,
      exerciseRestSeconds: data.exerciseRestSeconds.present
          ? data.exerciseRestSeconds.value
          : this.exerciseRestSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('daysCount: $daysCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('exerciseRestSeconds: $exerciseRestSeconds')
          ..write(')'))
        .toString();
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.daysCount == this.daysCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isActive == this.isActive &&
          other.activatedAt == this.activatedAt &&
          other.deactivatedAt == this.deactivatedAt &&
          other.exerciseRestSeconds == this.exerciseRestSeconds);
}

class ProgramsCompanion extends UpdateCompanion<ProgramRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<int> daysCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isActive;
  final Value<DateTime?> activatedAt;
  final Value<DateTime?> deactivatedAt;
  final Value<int?> exerciseRestSeconds;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.daysCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.exerciseRestSeconds = const Value.absent(),
  });
  ProgramsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.daysCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isActive = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.exerciseRestSeconds = const Value.absent(),
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProgramRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? daysCount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isActive,
    Expression<int>? activatedAt,
    Expression<int>? deactivatedAt,
    Expression<int>? exerciseRestSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (daysCount != null) 'days_count': daysCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isActive != null) 'is_active': isActive,
      if (activatedAt != null) 'activated_at': activatedAt,
      if (deactivatedAt != null) 'deactivated_at': deactivatedAt,
      if (exerciseRestSeconds != null)
        'exercise_rest_seconds': exerciseRestSeconds,
    });
  }

  ProgramsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? description,
    Value<int>? daysCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isActive,
    Value<DateTime?>? activatedAt,
    Value<DateTime?>? deactivatedAt,
    Value<int?>? exerciseRestSeconds,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      daysCount: daysCount ?? this.daysCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      activatedAt: activatedAt ?? this.activatedAt,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      exerciseRestSeconds: exerciseRestSeconds ?? this.exerciseRestSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (daysCount.present) {
      map['days_count'] = Variable<int>(daysCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ProgramsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ProgramsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (activatedAt.present) {
      map['activated_at'] = Variable<int>(
        $ProgramsTable.$converteractivatedAtn.toSql(activatedAt.value),
      );
    }
    if (deactivatedAt.present) {
      map['deactivated_at'] = Variable<int>(
        $ProgramsTable.$converterdeactivatedAtn.toSql(deactivatedAt.value),
      );
    }
    if (exerciseRestSeconds.present) {
      map['exercise_rest_seconds'] = Variable<int>(exerciseRestSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('daysCount: $daysCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('exerciseRestSeconds: $exerciseRestSeconds')
          ..write(')'))
        .toString();
  }
}

class $ProgramDaysTable extends ProgramDays
    with TableInfo<$ProgramDaysTable, ProgramDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<int> programId = GeneratedColumn<int>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES programs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayIndexMeta = const VerificationMeta(
    'dayIndex',
  );
  @override
  late final GeneratedColumn<int> dayIndex = GeneratedColumn<int>(
    'day_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'CHECK (day_index BETWEEN 0 AND 6)',
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (day_of_week BETWEEN 1 AND 7)',
  );
  static const VerificationMeta _warmupMinutesMeta = const VerificationMeta(
    'warmupMinutes',
  );
  @override
  late final GeneratedColumn<int> warmupMinutes = GeneratedColumn<int>(
    'warmup_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programId,
    dayIndex,
    dayOfWeek,
    warmupMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'program_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('day_index')) {
      context.handle(
        _dayIndexMeta,
        dayIndex.isAcceptableOrUnknown(data['day_index']!, _dayIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIndexMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    }
    if (data.containsKey('warmup_minutes')) {
      context.handle(
        _warmupMinutesMeta,
        warmupMinutes.isAcceptableOrUnknown(
          data['warmup_minutes']!,
          _warmupMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramDayRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_id'],
      )!,
      dayIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_index'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      ),
      warmupMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warmup_minutes'],
      ),
    );
  }

  @override
  $ProgramDaysTable createAlias(String alias) {
    return $ProgramDaysTable(attachedDatabase, alias);
  }
}

class ProgramDayRow extends DataClass implements Insertable<ProgramDayRow> {
  final int id;
  final int programId;
  final int dayIndex;
  final int? dayOfWeek;
  final int? warmupMinutes;
  const ProgramDayRow({
    required this.id,
    required this.programId,
    required this.dayIndex,
    this.dayOfWeek,
    this.warmupMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<int>(programId);
    map['day_index'] = Variable<int>(dayIndex);
    if (!nullToAbsent || dayOfWeek != null) {
      map['day_of_week'] = Variable<int>(dayOfWeek);
    }
    if (!nullToAbsent || warmupMinutes != null) {
      map['warmup_minutes'] = Variable<int>(warmupMinutes);
    }
    return map;
  }

  ProgramDaysCompanion toCompanion(bool nullToAbsent) {
    return ProgramDaysCompanion(
      id: Value(id),
      programId: Value(programId),
      dayIndex: Value(dayIndex),
      dayOfWeek: dayOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfWeek),
      warmupMinutes: warmupMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(warmupMinutes),
    );
  }

  factory ProgramDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramDayRow(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<int>(json['programId']),
      dayIndex: serializer.fromJson<int>(json['dayIndex']),
      dayOfWeek: serializer.fromJson<int?>(json['dayOfWeek']),
      warmupMinutes: serializer.fromJson<int?>(json['warmupMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<int>(programId),
      'dayIndex': serializer.toJson<int>(dayIndex),
      'dayOfWeek': serializer.toJson<int?>(dayOfWeek),
      'warmupMinutes': serializer.toJson<int?>(warmupMinutes),
    };
  }

  ProgramDayRow copyWith({
    int? id,
    int? programId,
    int? dayIndex,
    Value<int?> dayOfWeek = const Value.absent(),
    Value<int?> warmupMinutes = const Value.absent(),
  }) => ProgramDayRow(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    dayIndex: dayIndex ?? this.dayIndex,
    dayOfWeek: dayOfWeek.present ? dayOfWeek.value : this.dayOfWeek,
    warmupMinutes: warmupMinutes.present
        ? warmupMinutes.value
        : this.warmupMinutes,
  );
  ProgramDayRow copyWithCompanion(ProgramDaysCompanion data) {
    return ProgramDayRow(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      dayIndex: data.dayIndex.present ? data.dayIndex.value : this.dayIndex,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      warmupMinutes: data.warmupMinutes.present
          ? data.warmupMinutes.value
          : this.warmupMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramDayRow(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('warmupMinutes: $warmupMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, programId, dayIndex, dayOfWeek, warmupMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramDayRow &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.dayIndex == this.dayIndex &&
          other.dayOfWeek == this.dayOfWeek &&
          other.warmupMinutes == this.warmupMinutes);
}

class ProgramDaysCompanion extends UpdateCompanion<ProgramDayRow> {
  final Value<int> id;
  final Value<int> programId;
  final Value<int> dayIndex;
  final Value<int?> dayOfWeek;
  final Value<int?> warmupMinutes;
  const ProgramDaysCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.dayIndex = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.warmupMinutes = const Value.absent(),
  });
  ProgramDaysCompanion.insert({
    this.id = const Value.absent(),
    required int programId,
    required int dayIndex,
    this.dayOfWeek = const Value.absent(),
    this.warmupMinutes = const Value.absent(),
  }) : programId = Value(programId),
       dayIndex = Value(dayIndex);
  static Insertable<ProgramDayRow> custom({
    Expression<int>? id,
    Expression<int>? programId,
    Expression<int>? dayIndex,
    Expression<int>? dayOfWeek,
    Expression<int>? warmupMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (dayIndex != null) 'day_index': dayIndex,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (warmupMinutes != null) 'warmup_minutes': warmupMinutes,
    });
  }

  ProgramDaysCompanion copyWith({
    Value<int>? id,
    Value<int>? programId,
    Value<int>? dayIndex,
    Value<int?>? dayOfWeek,
    Value<int?>? warmupMinutes,
  }) {
    return ProgramDaysCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      dayIndex: dayIndex ?? this.dayIndex,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      warmupMinutes: warmupMinutes ?? this.warmupMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<int>(programId.value);
    }
    if (dayIndex.present) {
      map['day_index'] = Variable<int>(dayIndex.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (warmupMinutes.present) {
      map['warmup_minutes'] = Variable<int>(warmupMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramDaysCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('warmupMinutes: $warmupMinutes')
          ..write(')'))
        .toString();
  }
}

class $ProgramDayExercisesTable extends ProgramDayExercises
    with TableInfo<$ProgramDayExercisesTable, ProgramDayExerciseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramDayExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES program_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<int> sets = GeneratedColumn<int>(
    'sets',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAlternativeMeta = const VerificationMeta(
    'isAlternative',
  );
  @override
  late final GeneratedColumn<bool> isAlternative = GeneratedColumn<bool>(
    'is_alternative',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alternative" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayId,
    exerciseId,
    orderIndex,
    sets,
    reps,
    durationSeconds,
    weightKg,
    distanceMeters,
    restSeconds,
    isAlternative,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'program_day_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramDayExerciseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('sets')) {
      context.handle(
        _setsMeta,
        sets.isAcceptableOrUnknown(data['sets']!, _setsMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_alternative')) {
      context.handle(
        _isAlternativeMeta,
        isAlternative.isAcceptableOrUnknown(
          data['is_alternative']!,
          _isAlternativeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramDayExerciseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramDayExerciseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      sets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sets'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      ),
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      ),
      isAlternative: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alternative'],
      )!,
    );
  }

  @override
  $ProgramDayExercisesTable createAlias(String alias) {
    return $ProgramDayExercisesTable(attachedDatabase, alias);
  }
}

class ProgramDayExerciseRow extends DataClass
    implements Insertable<ProgramDayExerciseRow> {
  final int id;
  final int dayId;
  final int? exerciseId;
  final int orderIndex;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;
  final double? distanceMeters;
  final int? restSeconds;
  final bool isAlternative;
  const ProgramDayExerciseRow({
    required this.id,
    required this.dayId,
    this.exerciseId,
    required this.orderIndex,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.weightKg,
    this.distanceMeters,
    this.restSeconds,
    required this.isAlternative,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_id'] = Variable<int>(dayId);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<int>(exerciseId);
    }
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || sets != null) {
      map['sets'] = Variable<int>(sets);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_meters'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    map['is_alternative'] = Variable<bool>(isAlternative);
    return map;
  }

  ProgramDayExercisesCompanion toCompanion(bool nullToAbsent) {
    return ProgramDayExercisesCompanion(
      id: Value(id),
      dayId: Value(dayId),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      orderIndex: Value(orderIndex),
      sets: sets == null && nullToAbsent ? const Value.absent() : Value(sets),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      isAlternative: Value(isAlternative),
    );
  }

  factory ProgramDayExerciseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramDayExerciseRow(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int>(json['dayId']),
      exerciseId: serializer.fromJson<int?>(json['exerciseId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      sets: serializer.fromJson<int?>(json['sets']),
      reps: serializer.fromJson<int?>(json['reps']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      isAlternative: serializer.fromJson<bool>(json['isAlternative']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int>(dayId),
      'exerciseId': serializer.toJson<int?>(exerciseId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'sets': serializer.toJson<int?>(sets),
      'reps': serializer.toJson<int?>(reps),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'weightKg': serializer.toJson<double?>(weightKg),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'isAlternative': serializer.toJson<bool>(isAlternative),
    };
  }

  ProgramDayExerciseRow copyWith({
    int? id,
    int? dayId,
    Value<int?> exerciseId = const Value.absent(),
    int? orderIndex,
    Value<int?> sets = const Value.absent(),
    Value<int?> reps = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> distanceMeters = const Value.absent(),
    Value<int?> restSeconds = const Value.absent(),
    bool? isAlternative,
  }) => ProgramDayExerciseRow(
    id: id ?? this.id,
    dayId: dayId ?? this.dayId,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    orderIndex: orderIndex ?? this.orderIndex,
    sets: sets.present ? sets.value : this.sets,
    reps: reps.present ? reps.value : this.reps,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
    restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
    isAlternative: isAlternative ?? this.isAlternative,
  );
  ProgramDayExerciseRow copyWithCompanion(ProgramDayExercisesCompanion data) {
    return ProgramDayExerciseRow(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      sets: data.sets.present ? data.sets.value : this.sets,
      reps: data.reps.present ? data.reps.value : this.reps,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      isAlternative: data.isAlternative.present
          ? data.isAlternative.value
          : this.isAlternative,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramDayExerciseRow(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('weightKg: $weightKg, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isAlternative: $isAlternative')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayId,
    exerciseId,
    orderIndex,
    sets,
    reps,
    durationSeconds,
    weightKg,
    distanceMeters,
    restSeconds,
    isAlternative,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramDayExerciseRow &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.exerciseId == this.exerciseId &&
          other.orderIndex == this.orderIndex &&
          other.sets == this.sets &&
          other.reps == this.reps &&
          other.durationSeconds == this.durationSeconds &&
          other.weightKg == this.weightKg &&
          other.distanceMeters == this.distanceMeters &&
          other.restSeconds == this.restSeconds &&
          other.isAlternative == this.isAlternative);
}

class ProgramDayExercisesCompanion
    extends UpdateCompanion<ProgramDayExerciseRow> {
  final Value<int> id;
  final Value<int> dayId;
  final Value<int?> exerciseId;
  final Value<int> orderIndex;
  final Value<int?> sets;
  final Value<int?> reps;
  final Value<int?> durationSeconds;
  final Value<double?> weightKg;
  final Value<double?> distanceMeters;
  final Value<int?> restSeconds;
  final Value<bool> isAlternative;
  const ProgramDayExercisesCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.sets = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.isAlternative = const Value.absent(),
  });
  ProgramDayExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int dayId,
    this.exerciseId = const Value.absent(),
    required int orderIndex,
    this.sets = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.isAlternative = const Value.absent(),
  }) : dayId = Value(dayId),
       orderIndex = Value(orderIndex);
  static Insertable<ProgramDayExerciseRow> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<int>? exerciseId,
    Expression<int>? orderIndex,
    Expression<int>? sets,
    Expression<int>? reps,
    Expression<int>? durationSeconds,
    Expression<double>? weightKg,
    Expression<double>? distanceMeters,
    Expression<int>? restSeconds,
    Expression<bool>? isAlternative,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (weightKg != null) 'weight_kg': weightKg,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (isAlternative != null) 'is_alternative': isAlternative,
    });
  }

  ProgramDayExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? dayId,
    Value<int?>? exerciseId,
    Value<int>? orderIndex,
    Value<int?>? sets,
    Value<int?>? reps,
    Value<int?>? durationSeconds,
    Value<double?>? weightKg,
    Value<double?>? distanceMeters,
    Value<int?>? restSeconds,
    Value<bool>? isAlternative,
  }) {
    return ProgramDayExercisesCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weightKg: weightKg ?? this.weightKg,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      restSeconds: restSeconds ?? this.restSeconds,
      isAlternative: isAlternative ?? this.isAlternative,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (sets.present) {
      map['sets'] = Variable<int>(sets.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (isAlternative.present) {
      map['is_alternative'] = Variable<bool>(isAlternative.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramDayExercisesCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('weightKg: $weightKg, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isAlternative: $isAlternative')
          ..write(')'))
        .toString();
  }
}

class $WorkoutRemindersTable extends WorkoutReminders
    with TableInfo<$WorkoutRemindersTable, WorkoutReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programDayIdMeta = const VerificationMeta(
    'programDayId',
  );
  @override
  late final GeneratedColumn<int> programDayId = GeneratedColumn<int>(
    'program_day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES program_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programDayId,
    hour,
    minute,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_day_id')) {
      context.handle(
        _programDayIdMeta,
        programDayId.isAcceptableOrUnknown(
          data['program_day_id']!,
          _programDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_programDayIdMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_day_id'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $WorkoutRemindersTable createAlias(String alias) {
    return $WorkoutRemindersTable(attachedDatabase, alias);
  }
}

class WorkoutReminderRow extends DataClass
    implements Insertable<WorkoutReminderRow> {
  final int id;
  final int programDayId;
  final int hour;
  final int minute;
  final bool enabled;
  const WorkoutReminderRow({
    required this.id,
    required this.programDayId,
    required this.hour,
    required this.minute,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_day_id'] = Variable<int>(programDayId);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  WorkoutRemindersCompanion toCompanion(bool nullToAbsent) {
    return WorkoutRemindersCompanion(
      id: Value(id),
      programDayId: Value(programDayId),
      hour: Value(hour),
      minute: Value(minute),
      enabled: Value(enabled),
    );
  }

  factory WorkoutReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutReminderRow(
      id: serializer.fromJson<int>(json['id']),
      programDayId: serializer.fromJson<int>(json['programDayId']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programDayId': serializer.toJson<int>(programDayId),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  WorkoutReminderRow copyWith({
    int? id,
    int? programDayId,
    int? hour,
    int? minute,
    bool? enabled,
  }) => WorkoutReminderRow(
    id: id ?? this.id,
    programDayId: programDayId ?? this.programDayId,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    enabled: enabled ?? this.enabled,
  );
  WorkoutReminderRow copyWithCompanion(WorkoutRemindersCompanion data) {
    return WorkoutReminderRow(
      id: data.id.present ? data.id.value : this.id,
      programDayId: data.programDayId.present
          ? data.programDayId.value
          : this.programDayId,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutReminderRow(')
          ..write('id: $id, ')
          ..write('programDayId: $programDayId, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, programDayId, hour, minute, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutReminderRow &&
          other.id == this.id &&
          other.programDayId == this.programDayId &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.enabled == this.enabled);
}

class WorkoutRemindersCompanion extends UpdateCompanion<WorkoutReminderRow> {
  final Value<int> id;
  final Value<int> programDayId;
  final Value<int> hour;
  final Value<int> minute;
  final Value<bool> enabled;
  const WorkoutRemindersCompanion({
    this.id = const Value.absent(),
    this.programDayId = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  WorkoutRemindersCompanion.insert({
    this.id = const Value.absent(),
    required int programDayId,
    required int hour,
    required int minute,
    this.enabled = const Value.absent(),
  }) : programDayId = Value(programDayId),
       hour = Value(hour),
       minute = Value(minute);
  static Insertable<WorkoutReminderRow> custom({
    Expression<int>? id,
    Expression<int>? programDayId,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programDayId != null) 'program_day_id': programDayId,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (enabled != null) 'enabled': enabled,
    });
  }

  WorkoutRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? programDayId,
    Value<int>? hour,
    Value<int>? minute,
    Value<bool>? enabled,
  }) {
    return WorkoutRemindersCompanion(
      id: id ?? this.id,
      programDayId: programDayId ?? this.programDayId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programDayId.present) {
      map['program_day_id'] = Variable<int>(programDayId.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutRemindersCompanion(')
          ..write('id: $id, ')
          ..write('programDayId: $programDayId, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<int> programId = GeneratedColumn<int>(
    'program_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES programs (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _programNameMeta = const VerificationMeta(
    'programName',
  );
  @override
  late final GeneratedColumn<String> programName = GeneratedColumn<String>(
    'program_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _programDayIdMeta = const VerificationMeta(
    'programDayId',
  );
  @override
  late final GeneratedColumn<int> programDayId = GeneratedColumn<int>(
    'program_day_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES program_days (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _dayIndexMeta = const VerificationMeta(
    'dayIndex',
  );
  @override
  late final GeneratedColumn<int> dayIndex = GeneratedColumn<int>(
    'day_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WorkoutVariant, String> variant =
      GeneratedColumn<String>(
        'variant',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WorkoutVariant>($WorkoutSessionsTable.$convertervariant);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> performedDate =
      GeneratedColumn<int>(
        'performed_date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($WorkoutSessionsTable.$converterperformedDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($WorkoutSessionsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> endedAt =
      GeneratedColumn<int>(
        'ended_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($WorkoutSessionsTable.$converterendedAt);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programId,
    programName,
    programDayId,
    dayIndex,
    variant,
    performedDate,
    startedAt,
    endedAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    }
    if (data.containsKey('program_name')) {
      context.handle(
        _programNameMeta,
        programName.isAcceptableOrUnknown(
          data['program_name']!,
          _programNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_programNameMeta);
    }
    if (data.containsKey('program_day_id')) {
      context.handle(
        _programDayIdMeta,
        programDayId.isAcceptableOrUnknown(
          data['program_day_id']!,
          _programDayIdMeta,
        ),
      );
    }
    if (data.containsKey('day_index')) {
      context.handle(
        _dayIndexMeta,
        dayIndex.isAcceptableOrUnknown(data['day_index']!, _dayIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIndexMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_id'],
      ),
      programName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_name'],
      )!,
      programDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_day_id'],
      ),
      dayIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_index'],
      )!,
      variant: $WorkoutSessionsTable.$convertervariant.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}variant'],
        )!,
      ),
      performedDate: $WorkoutSessionsTable.$converterperformedDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}performed_date'],
        )!,
      ),
      startedAt: $WorkoutSessionsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      endedAt: $WorkoutSessionsTable.$converterendedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}ended_at'],
        )!,
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<WorkoutVariant, String> $convertervariant =
      const WorkoutVariantConverter();
  static TypeConverter<DateTime, int> $converterperformedDate =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterstartedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime, int> $converterendedAt =
      const DateTimeConverter();
}

class WorkoutSessionRow extends DataClass
    implements Insertable<WorkoutSessionRow> {
  final int id;
  final int? programId;
  final String programName;
  final int? programDayId;
  final int dayIndex;
  final WorkoutVariant variant;
  final DateTime performedDate;
  final DateTime startedAt;
  final DateTime endedAt;
  final String status;
  const WorkoutSessionRow({
    required this.id,
    this.programId,
    required this.programName,
    this.programDayId,
    required this.dayIndex,
    required this.variant,
    required this.performedDate,
    required this.startedAt,
    required this.endedAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || programId != null) {
      map['program_id'] = Variable<int>(programId);
    }
    map['program_name'] = Variable<String>(programName);
    if (!nullToAbsent || programDayId != null) {
      map['program_day_id'] = Variable<int>(programDayId);
    }
    map['day_index'] = Variable<int>(dayIndex);
    {
      map['variant'] = Variable<String>(
        $WorkoutSessionsTable.$convertervariant.toSql(variant),
      );
    }
    {
      map['performed_date'] = Variable<int>(
        $WorkoutSessionsTable.$converterperformedDate.toSql(performedDate),
      );
    }
    {
      map['started_at'] = Variable<int>(
        $WorkoutSessionsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    {
      map['ended_at'] = Variable<int>(
        $WorkoutSessionsTable.$converterendedAt.toSql(endedAt),
      );
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      programId: programId == null && nullToAbsent
          ? const Value.absent()
          : Value(programId),
      programName: Value(programName),
      programDayId: programDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(programDayId),
      dayIndex: Value(dayIndex),
      variant: Value(variant),
      performedDate: Value(performedDate),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      status: Value(status),
    );
  }

  factory WorkoutSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSessionRow(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<int?>(json['programId']),
      programName: serializer.fromJson<String>(json['programName']),
      programDayId: serializer.fromJson<int?>(json['programDayId']),
      dayIndex: serializer.fromJson<int>(json['dayIndex']),
      variant: serializer.fromJson<WorkoutVariant>(json['variant']),
      performedDate: serializer.fromJson<DateTime>(json['performedDate']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<int?>(programId),
      'programName': serializer.toJson<String>(programName),
      'programDayId': serializer.toJson<int?>(programDayId),
      'dayIndex': serializer.toJson<int>(dayIndex),
      'variant': serializer.toJson<WorkoutVariant>(variant),
      'performedDate': serializer.toJson<DateTime>(performedDate),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  WorkoutSessionRow copyWith({
    int? id,
    Value<int?> programId = const Value.absent(),
    String? programName,
    Value<int?> programDayId = const Value.absent(),
    int? dayIndex,
    WorkoutVariant? variant,
    DateTime? performedDate,
    DateTime? startedAt,
    DateTime? endedAt,
    String? status,
  }) => WorkoutSessionRow(
    id: id ?? this.id,
    programId: programId.present ? programId.value : this.programId,
    programName: programName ?? this.programName,
    programDayId: programDayId.present ? programDayId.value : this.programDayId,
    dayIndex: dayIndex ?? this.dayIndex,
    variant: variant ?? this.variant,
    performedDate: performedDate ?? this.performedDate,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    status: status ?? this.status,
  );
  WorkoutSessionRow copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSessionRow(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      programName: data.programName.present
          ? data.programName.value
          : this.programName,
      programDayId: data.programDayId.present
          ? data.programDayId.value
          : this.programDayId,
      dayIndex: data.dayIndex.present ? data.dayIndex.value : this.dayIndex,
      variant: data.variant.present ? data.variant.value : this.variant,
      performedDate: data.performedDate.present
          ? data.performedDate.value
          : this.performedDate,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionRow(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('programName: $programName, ')
          ..write('programDayId: $programDayId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('variant: $variant, ')
          ..write('performedDate: $performedDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    programId,
    programName,
    programDayId,
    dayIndex,
    variant,
    performedDate,
    startedAt,
    endedAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSessionRow &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.programName == this.programName &&
          other.programDayId == this.programDayId &&
          other.dayIndex == this.dayIndex &&
          other.variant == this.variant &&
          other.performedDate == this.performedDate &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSessionRow> {
  final Value<int> id;
  final Value<int?> programId;
  final Value<String> programName;
  final Value<int?> programDayId;
  final Value<int> dayIndex;
  final Value<WorkoutVariant> variant;
  final Value<DateTime> performedDate;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<String> status;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.programName = const Value.absent(),
    this.programDayId = const Value.absent(),
    this.dayIndex = const Value.absent(),
    this.variant = const Value.absent(),
    this.performedDate = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    required String programName,
    this.programDayId = const Value.absent(),
    required int dayIndex,
    required WorkoutVariant variant,
    required DateTime performedDate,
    required DateTime startedAt,
    required DateTime endedAt,
    this.status = const Value.absent(),
  }) : programName = Value(programName),
       dayIndex = Value(dayIndex),
       variant = Value(variant),
       performedDate = Value(performedDate),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt);
  static Insertable<WorkoutSessionRow> custom({
    Expression<int>? id,
    Expression<int>? programId,
    Expression<String>? programName,
    Expression<int>? programDayId,
    Expression<int>? dayIndex,
    Expression<String>? variant,
    Expression<int>? performedDate,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (programName != null) 'program_name': programName,
      if (programDayId != null) 'program_day_id': programDayId,
      if (dayIndex != null) 'day_index': dayIndex,
      if (variant != null) 'variant': variant,
      if (performedDate != null) 'performed_date': performedDate,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? programId,
    Value<String>? programName,
    Value<int?>? programDayId,
    Value<int>? dayIndex,
    Value<WorkoutVariant>? variant,
    Value<DateTime>? performedDate,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<String>? status,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      programDayId: programDayId ?? this.programDayId,
      dayIndex: dayIndex ?? this.dayIndex,
      variant: variant ?? this.variant,
      performedDate: performedDate ?? this.performedDate,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<int>(programId.value);
    }
    if (programName.present) {
      map['program_name'] = Variable<String>(programName.value);
    }
    if (programDayId.present) {
      map['program_day_id'] = Variable<int>(programDayId.value);
    }
    if (dayIndex.present) {
      map['day_index'] = Variable<int>(dayIndex.value);
    }
    if (variant.present) {
      map['variant'] = Variable<String>(
        $WorkoutSessionsTable.$convertervariant.toSql(variant.value),
      );
    }
    if (performedDate.present) {
      map['performed_date'] = Variable<int>(
        $WorkoutSessionsTable.$converterperformedDate.toSql(
          performedDate.value,
        ),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $WorkoutSessionsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(
        $WorkoutSessionsTable.$converterendedAt.toSql(endedAt.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('programName: $programName, ')
          ..write('programDayId: $programDayId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('variant: $variant, ')
          ..write('performedDate: $performedDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetResultsTable extends WorkoutSetResults
    with TableInfo<$WorkoutSetResultsTable, WorkoutSetResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExerciseType, String>
  exerciseType = GeneratedColumn<String>(
    'exercise_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ExerciseType>($WorkoutSetResultsTable.$converterexerciseType);
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
    'side',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($WorkoutSetResultsTable.$convertercompletedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    exerciseId,
    exerciseName,
    exerciseType,
    setIndex,
    reps,
    weightKg,
    durationSeconds,
    distanceMeters,
    side,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_set_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSetResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('side')) {
      context.handle(
        _sideMeta,
        side.isAcceptableOrUnknown(data['side']!, _sideMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSetResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSetResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      ),
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      exerciseType: $WorkoutSetResultsTable.$converterexerciseType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}exercise_type'],
        )!,
      ),
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      ),
      side: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side'],
      ),
      completedAt: $WorkoutSetResultsTable.$convertercompletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}completed_at'],
        )!,
      ),
    );
  }

  @override
  $WorkoutSetResultsTable createAlias(String alias) {
    return $WorkoutSetResultsTable(attachedDatabase, alias);
  }

  static TypeConverter<ExerciseType, String> $converterexerciseType =
      const ExerciseTypeConverter();
  static TypeConverter<DateTime, int> $convertercompletedAt =
      const DateTimeConverter();
}

class WorkoutSetResultRow extends DataClass
    implements Insertable<WorkoutSetResultRow> {
  final int id;
  final int sessionId;
  final int? exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final int setIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final String? side;
  final DateTime completedAt;
  const WorkoutSetResultRow({
    required this.id,
    required this.sessionId,
    this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.setIndex,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.side,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<int>(exerciseId);
    }
    map['exercise_name'] = Variable<String>(exerciseName);
    {
      map['exercise_type'] = Variable<String>(
        $WorkoutSetResultsTable.$converterexerciseType.toSql(exerciseType),
      );
    }
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_meters'] = Variable<double>(distanceMeters);
    }
    if (!nullToAbsent || side != null) {
      map['side'] = Variable<String>(side);
    }
    {
      map['completed_at'] = Variable<int>(
        $WorkoutSetResultsTable.$convertercompletedAt.toSql(completedAt),
      );
    }
    return map;
  }

  WorkoutSetResultsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetResultsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      exerciseName: Value(exerciseName),
      exerciseType: Value(exerciseType),
      setIndex: Value(setIndex),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
      side: side == null && nullToAbsent ? const Value.absent() : Value(side),
      completedAt: Value(completedAt),
    );
  }

  factory WorkoutSetResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSetResultRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<int?>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      exerciseType: serializer.fromJson<ExerciseType>(json['exerciseType']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      reps: serializer.fromJson<int?>(json['reps']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
      side: serializer.fromJson<String?>(json['side']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<int?>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'exerciseType': serializer.toJson<ExerciseType>(exerciseType),
      'setIndex': serializer.toJson<int>(setIndex),
      'reps': serializer.toJson<int?>(reps),
      'weightKg': serializer.toJson<double?>(weightKg),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
      'side': serializer.toJson<String?>(side),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  WorkoutSetResultRow copyWith({
    int? id,
    int? sessionId,
    Value<int?> exerciseId = const Value.absent(),
    String? exerciseName,
    ExerciseType? exerciseType,
    int? setIndex,
    Value<int?> reps = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<double?> distanceMeters = const Value.absent(),
    Value<String?> side = const Value.absent(),
    DateTime? completedAt,
  }) => WorkoutSetResultRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    exerciseType: exerciseType ?? this.exerciseType,
    setIndex: setIndex ?? this.setIndex,
    reps: reps.present ? reps.value : this.reps,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
    side: side.present ? side.value : this.side,
    completedAt: completedAt ?? this.completedAt,
  );
  WorkoutSetResultRow copyWithCompanion(WorkoutSetResultsCompanion data) {
    return WorkoutSetResultRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      exerciseType: data.exerciseType.present
          ? data.exerciseType.value
          : this.exerciseType,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      side: data.side.present ? data.side.value : this.side,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetResultRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('side: $side, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    exerciseId,
    exerciseName,
    exerciseType,
    setIndex,
    reps,
    weightKg,
    durationSeconds,
    distanceMeters,
    side,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSetResultRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.exerciseType == this.exerciseType &&
          other.setIndex == this.setIndex &&
          other.reps == this.reps &&
          other.weightKg == this.weightKg &&
          other.durationSeconds == this.durationSeconds &&
          other.distanceMeters == this.distanceMeters &&
          other.side == this.side &&
          other.completedAt == this.completedAt);
}

class WorkoutSetResultsCompanion extends UpdateCompanion<WorkoutSetResultRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int?> exerciseId;
  final Value<String> exerciseName;
  final Value<ExerciseType> exerciseType;
  final Value<int> setIndex;
  final Value<int?> reps;
  final Value<double?> weightKg;
  final Value<int?> durationSeconds;
  final Value<double?> distanceMeters;
  final Value<String?> side;
  final Value<DateTime> completedAt;
  const WorkoutSetResultsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.side = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  WorkoutSetResultsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    this.exerciseId = const Value.absent(),
    required String exerciseName,
    required ExerciseType exerciseType,
    required int setIndex,
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.side = const Value.absent(),
    required DateTime completedAt,
  }) : sessionId = Value(sessionId),
       exerciseName = Value(exerciseName),
       exerciseType = Value(exerciseType),
       setIndex = Value(setIndex),
       completedAt = Value(completedAt);
  static Insertable<WorkoutSetResultRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? exerciseId,
    Expression<String>? exerciseName,
    Expression<String>? exerciseType,
    Expression<int>? setIndex,
    Expression<int>? reps,
    Expression<double>? weightKg,
    Expression<int>? durationSeconds,
    Expression<double>? distanceMeters,
    Expression<String>? side,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (setIndex != null) 'set_index': setIndex,
      if (reps != null) 'reps': reps,
      if (weightKg != null) 'weight_kg': weightKg,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (side != null) 'side': side,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  WorkoutSetResultsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int?>? exerciseId,
    Value<String>? exerciseName,
    Value<ExerciseType>? exerciseType,
    Value<int>? setIndex,
    Value<int?>? reps,
    Value<double?>? weightKg,
    Value<int?>? durationSeconds,
    Value<double?>? distanceMeters,
    Value<String?>? side,
    Value<DateTime>? completedAt,
  }) {
    return WorkoutSetResultsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      side: side ?? this.side,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<String>(
        $WorkoutSetResultsTable.$converterexerciseType.toSql(
          exerciseType.value,
        ),
      );
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $WorkoutSetResultsTable.$convertercompletedAt.toSql(completedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetResultsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('side: $side, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduleMarksTable extends ScheduleMarks
    with TableInfo<$ScheduleMarksTable, ScheduleMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programDayIdMeta = const VerificationMeta(
    'programDayId',
  );
  @override
  late final GeneratedColumn<int> programDayId = GeneratedColumn<int>(
    'program_day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES program_days (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> weekStart =
      GeneratedColumn<int>(
        'week_start',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ScheduleMarksTable.$converterweekStart);
  @override
  late final GeneratedColumnWithTypeConverter<ScheduleMarkStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ScheduleMarkStatus>($ScheduleMarksTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [id, programDayId, weekStart, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_day_id')) {
      context.handle(
        _programDayIdMeta,
        programDayId.isAcceptableOrUnknown(
          data['program_day_id']!,
          _programDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_programDayIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleMarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_day_id'],
      )!,
      weekStart: $ScheduleMarksTable.$converterweekStart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}week_start'],
        )!,
      ),
      status: $ScheduleMarksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $ScheduleMarksTable createAlias(String alias) {
    return $ScheduleMarksTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterweekStart =
      const DateTimeConverter();
  static TypeConverter<ScheduleMarkStatus, String> $converterstatus =
      const ScheduleMarkStatusConverter();
}

class ScheduleMarkRow extends DataClass implements Insertable<ScheduleMarkRow> {
  final int id;
  final int programDayId;
  final DateTime weekStart;
  final ScheduleMarkStatus status;
  const ScheduleMarkRow({
    required this.id,
    required this.programDayId,
    required this.weekStart,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_day_id'] = Variable<int>(programDayId);
    {
      map['week_start'] = Variable<int>(
        $ScheduleMarksTable.$converterweekStart.toSql(weekStart),
      );
    }
    {
      map['status'] = Variable<String>(
        $ScheduleMarksTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  ScheduleMarksCompanion toCompanion(bool nullToAbsent) {
    return ScheduleMarksCompanion(
      id: Value(id),
      programDayId: Value(programDayId),
      weekStart: Value(weekStart),
      status: Value(status),
    );
  }

  factory ScheduleMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleMarkRow(
      id: serializer.fromJson<int>(json['id']),
      programDayId: serializer.fromJson<int>(json['programDayId']),
      weekStart: serializer.fromJson<DateTime>(json['weekStart']),
      status: serializer.fromJson<ScheduleMarkStatus>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programDayId': serializer.toJson<int>(programDayId),
      'weekStart': serializer.toJson<DateTime>(weekStart),
      'status': serializer.toJson<ScheduleMarkStatus>(status),
    };
  }

  ScheduleMarkRow copyWith({
    int? id,
    int? programDayId,
    DateTime? weekStart,
    ScheduleMarkStatus? status,
  }) => ScheduleMarkRow(
    id: id ?? this.id,
    programDayId: programDayId ?? this.programDayId,
    weekStart: weekStart ?? this.weekStart,
    status: status ?? this.status,
  );
  ScheduleMarkRow copyWithCompanion(ScheduleMarksCompanion data) {
    return ScheduleMarkRow(
      id: data.id.present ? data.id.value : this.id,
      programDayId: data.programDayId.present
          ? data.programDayId.value
          : this.programDayId,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleMarkRow(')
          ..write('id: $id, ')
          ..write('programDayId: $programDayId, ')
          ..write('weekStart: $weekStart, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, programDayId, weekStart, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleMarkRow &&
          other.id == this.id &&
          other.programDayId == this.programDayId &&
          other.weekStart == this.weekStart &&
          other.status == this.status);
}

class ScheduleMarksCompanion extends UpdateCompanion<ScheduleMarkRow> {
  final Value<int> id;
  final Value<int> programDayId;
  final Value<DateTime> weekStart;
  final Value<ScheduleMarkStatus> status;
  const ScheduleMarksCompanion({
    this.id = const Value.absent(),
    this.programDayId = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.status = const Value.absent(),
  });
  ScheduleMarksCompanion.insert({
    this.id = const Value.absent(),
    required int programDayId,
    required DateTime weekStart,
    required ScheduleMarkStatus status,
  }) : programDayId = Value(programDayId),
       weekStart = Value(weekStart),
       status = Value(status);
  static Insertable<ScheduleMarkRow> custom({
    Expression<int>? id,
    Expression<int>? programDayId,
    Expression<int>? weekStart,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programDayId != null) 'program_day_id': programDayId,
      if (weekStart != null) 'week_start': weekStart,
      if (status != null) 'status': status,
    });
  }

  ScheduleMarksCompanion copyWith({
    Value<int>? id,
    Value<int>? programDayId,
    Value<DateTime>? weekStart,
    Value<ScheduleMarkStatus>? status,
  }) {
    return ScheduleMarksCompanion(
      id: id ?? this.id,
      programDayId: programDayId ?? this.programDayId,
      weekStart: weekStart ?? this.weekStart,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programDayId.present) {
      map['program_day_id'] = Variable<int>(programDayId.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<int>(
        $ScheduleMarksTable.$converterweekStart.toSql(weekStart.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ScheduleMarksTable.$converterstatus.toSql(status.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleMarksCompanion(')
          ..write('id: $id, ')
          ..write('programDayId: $programDayId, ')
          ..write('weekStart: $weekStart, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> date =
      GeneratedColumn<int>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BodyMeasurementsTable.$converterdate);
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neckCmMeta = const VerificationMeta('neckCm');
  @override
  late final GeneratedColumn<double> neckCm = GeneratedColumn<double>(
    'neck_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chestCmMeta = const VerificationMeta(
    'chestCm',
  );
  @override
  late final GeneratedColumn<double> chestCm = GeneratedColumn<double>(
    'chest_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waistCmMeta = const VerificationMeta(
    'waistCm',
  );
  @override
  late final GeneratedColumn<double> waistCm = GeneratedColumn<double>(
    'waist_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hipsCmMeta = const VerificationMeta('hipsCm');
  @override
  late final GeneratedColumn<double> hipsCm = GeneratedColumn<double>(
    'hips_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bicepsCmMeta = const VerificationMeta(
    'bicepsCm',
  );
  @override
  late final GeneratedColumn<double> bicepsCm = GeneratedColumn<double>(
    'biceps_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _forearmCmMeta = const VerificationMeta(
    'forearmCm',
  );
  @override
  late final GeneratedColumn<double> forearmCm = GeneratedColumn<double>(
    'forearm_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thighCmMeta = const VerificationMeta(
    'thighCm',
  );
  @override
  late final GeneratedColumn<double> thighCm = GeneratedColumn<double>(
    'thigh_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calfCmMeta = const VerificationMeta('calfCm');
  @override
  late final GeneratedColumn<double> calfCm = GeneratedColumn<double>(
    'calf_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyMeasurementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('neck_cm')) {
      context.handle(
        _neckCmMeta,
        neckCm.isAcceptableOrUnknown(data['neck_cm']!, _neckCmMeta),
      );
    }
    if (data.containsKey('chest_cm')) {
      context.handle(
        _chestCmMeta,
        chestCm.isAcceptableOrUnknown(data['chest_cm']!, _chestCmMeta),
      );
    }
    if (data.containsKey('waist_cm')) {
      context.handle(
        _waistCmMeta,
        waistCm.isAcceptableOrUnknown(data['waist_cm']!, _waistCmMeta),
      );
    }
    if (data.containsKey('hips_cm')) {
      context.handle(
        _hipsCmMeta,
        hipsCm.isAcceptableOrUnknown(data['hips_cm']!, _hipsCmMeta),
      );
    }
    if (data.containsKey('biceps_cm')) {
      context.handle(
        _bicepsCmMeta,
        bicepsCm.isAcceptableOrUnknown(data['biceps_cm']!, _bicepsCmMeta),
      );
    }
    if (data.containsKey('forearm_cm')) {
      context.handle(
        _forearmCmMeta,
        forearmCm.isAcceptableOrUnknown(data['forearm_cm']!, _forearmCmMeta),
      );
    }
    if (data.containsKey('thigh_cm')) {
      context.handle(
        _thighCmMeta,
        thighCm.isAcceptableOrUnknown(data['thigh_cm']!, _thighCmMeta),
      );
    }
    if (data.containsKey('calf_cm')) {
      context.handle(
        _calfCmMeta,
        calfCm.isAcceptableOrUnknown(data['calf_cm']!, _calfCmMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: $BodyMeasurementsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}date'],
        )!,
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      neckCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}neck_cm'],
      ),
      chestCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chest_cm'],
      ),
      waistCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waist_cm'],
      ),
      hipsCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hips_cm'],
      ),
      bicepsCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}biceps_cm'],
      ),
      forearmCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}forearm_cm'],
      ),
      thighCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thigh_cm'],
      ),
      calfCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calf_cm'],
      ),
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdate =
      const DateTimeConverter();
}

class BodyMeasurementRow extends DataClass
    implements Insertable<BodyMeasurementRow> {
  final int id;
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
  const BodyMeasurementRow({
    required this.id,
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['date'] = Variable<int>(
        $BodyMeasurementsTable.$converterdate.toSql(date),
      );
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || neckCm != null) {
      map['neck_cm'] = Variable<double>(neckCm);
    }
    if (!nullToAbsent || chestCm != null) {
      map['chest_cm'] = Variable<double>(chestCm);
    }
    if (!nullToAbsent || waistCm != null) {
      map['waist_cm'] = Variable<double>(waistCm);
    }
    if (!nullToAbsent || hipsCm != null) {
      map['hips_cm'] = Variable<double>(hipsCm);
    }
    if (!nullToAbsent || bicepsCm != null) {
      map['biceps_cm'] = Variable<double>(bicepsCm);
    }
    if (!nullToAbsent || forearmCm != null) {
      map['forearm_cm'] = Variable<double>(forearmCm);
    }
    if (!nullToAbsent || thighCm != null) {
      map['thigh_cm'] = Variable<double>(thighCm);
    }
    if (!nullToAbsent || calfCm != null) {
      map['calf_cm'] = Variable<double>(calfCm);
    }
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      date: Value(date),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      neckCm: neckCm == null && nullToAbsent
          ? const Value.absent()
          : Value(neckCm),
      chestCm: chestCm == null && nullToAbsent
          ? const Value.absent()
          : Value(chestCm),
      waistCm: waistCm == null && nullToAbsent
          ? const Value.absent()
          : Value(waistCm),
      hipsCm: hipsCm == null && nullToAbsent
          ? const Value.absent()
          : Value(hipsCm),
      bicepsCm: bicepsCm == null && nullToAbsent
          ? const Value.absent()
          : Value(bicepsCm),
      forearmCm: forearmCm == null && nullToAbsent
          ? const Value.absent()
          : Value(forearmCm),
      thighCm: thighCm == null && nullToAbsent
          ? const Value.absent()
          : Value(thighCm),
      calfCm: calfCm == null && nullToAbsent
          ? const Value.absent()
          : Value(calfCm),
    );
  }

  factory BodyMeasurementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurementRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      neckCm: serializer.fromJson<double?>(json['neckCm']),
      chestCm: serializer.fromJson<double?>(json['chestCm']),
      waistCm: serializer.fromJson<double?>(json['waistCm']),
      hipsCm: serializer.fromJson<double?>(json['hipsCm']),
      bicepsCm: serializer.fromJson<double?>(json['bicepsCm']),
      forearmCm: serializer.fromJson<double?>(json['forearmCm']),
      thighCm: serializer.fromJson<double?>(json['thighCm']),
      calfCm: serializer.fromJson<double?>(json['calfCm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'neckCm': serializer.toJson<double?>(neckCm),
      'chestCm': serializer.toJson<double?>(chestCm),
      'waistCm': serializer.toJson<double?>(waistCm),
      'hipsCm': serializer.toJson<double?>(hipsCm),
      'bicepsCm': serializer.toJson<double?>(bicepsCm),
      'forearmCm': serializer.toJson<double?>(forearmCm),
      'thighCm': serializer.toJson<double?>(thighCm),
      'calfCm': serializer.toJson<double?>(calfCm),
    };
  }

  BodyMeasurementRow copyWith({
    int? id,
    DateTime? date,
    Value<double?> heightCm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> neckCm = const Value.absent(),
    Value<double?> chestCm = const Value.absent(),
    Value<double?> waistCm = const Value.absent(),
    Value<double?> hipsCm = const Value.absent(),
    Value<double?> bicepsCm = const Value.absent(),
    Value<double?> forearmCm = const Value.absent(),
    Value<double?> thighCm = const Value.absent(),
    Value<double?> calfCm = const Value.absent(),
  }) => BodyMeasurementRow(
    id: id ?? this.id,
    date: date ?? this.date,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    neckCm: neckCm.present ? neckCm.value : this.neckCm,
    chestCm: chestCm.present ? chestCm.value : this.chestCm,
    waistCm: waistCm.present ? waistCm.value : this.waistCm,
    hipsCm: hipsCm.present ? hipsCm.value : this.hipsCm,
    bicepsCm: bicepsCm.present ? bicepsCm.value : this.bicepsCm,
    forearmCm: forearmCm.present ? forearmCm.value : this.forearmCm,
    thighCm: thighCm.present ? thighCm.value : this.thighCm,
    calfCm: calfCm.present ? calfCm.value : this.calfCm,
  );
  BodyMeasurementRow copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurementRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      neckCm: data.neckCm.present ? data.neckCm.value : this.neckCm,
      chestCm: data.chestCm.present ? data.chestCm.value : this.chestCm,
      waistCm: data.waistCm.present ? data.waistCm.value : this.waistCm,
      hipsCm: data.hipsCm.present ? data.hipsCm.value : this.hipsCm,
      bicepsCm: data.bicepsCm.present ? data.bicepsCm.value : this.bicepsCm,
      forearmCm: data.forearmCm.present ? data.forearmCm.value : this.forearmCm,
      thighCm: data.thighCm.present ? data.thighCm.value : this.thighCm,
      calfCm: data.calfCm.present ? data.calfCm.value : this.calfCm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('neckCm: $neckCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('bicepsCm: $bicepsCm, ')
          ..write('forearmCm: $forearmCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('calfCm: $calfCm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurementRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.neckCm == this.neckCm &&
          other.chestCm == this.chestCm &&
          other.waistCm == this.waistCm &&
          other.hipsCm == this.hipsCm &&
          other.bicepsCm == this.bicepsCm &&
          other.forearmCm == this.forearmCm &&
          other.thighCm == this.thighCm &&
          other.calfCm == this.calfCm);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurementRow> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<double?> neckCm;
  final Value<double?> chestCm;
  final Value<double?> waistCm;
  final Value<double?> hipsCm;
  final Value<double?> bicepsCm;
  final Value<double?> forearmCm;
  final Value<double?> thighCm;
  final Value<double?> calfCm;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.bicepsCm = const Value.absent(),
    this.forearmCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.calfCm = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.bicepsCm = const Value.absent(),
    this.forearmCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.calfCm = const Value.absent(),
  }) : date = Value(date);
  static Insertable<BodyMeasurementRow> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<double>? neckCm,
    Expression<double>? chestCm,
    Expression<double>? waistCm,
    Expression<double>? hipsCm,
    Expression<double>? bicepsCm,
    Expression<double>? forearmCm,
    Expression<double>? thighCm,
    Expression<double>? calfCm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (neckCm != null) 'neck_cm': neckCm,
      if (chestCm != null) 'chest_cm': chestCm,
      if (waistCm != null) 'waist_cm': waistCm,
      if (hipsCm != null) 'hips_cm': hipsCm,
      if (bicepsCm != null) 'biceps_cm': bicepsCm,
      if (forearmCm != null) 'forearm_cm': forearmCm,
      if (thighCm != null) 'thigh_cm': thighCm,
      if (calfCm != null) 'calf_cm': calfCm,
    });
  }

  BodyMeasurementsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<double?>? heightCm,
    Value<double?>? weightKg,
    Value<double?>? neckCm,
    Value<double?>? chestCm,
    Value<double?>? waistCm,
    Value<double?>? hipsCm,
    Value<double?>? bicepsCm,
    Value<double?>? forearmCm,
    Value<double?>? thighCm,
    Value<double?>? calfCm,
  }) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
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
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(
        $BodyMeasurementsTable.$converterdate.toSql(date.value),
      );
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (neckCm.present) {
      map['neck_cm'] = Variable<double>(neckCm.value);
    }
    if (chestCm.present) {
      map['chest_cm'] = Variable<double>(chestCm.value);
    }
    if (waistCm.present) {
      map['waist_cm'] = Variable<double>(waistCm.value);
    }
    if (hipsCm.present) {
      map['hips_cm'] = Variable<double>(hipsCm.value);
    }
    if (bicepsCm.present) {
      map['biceps_cm'] = Variable<double>(bicepsCm.value);
    }
    if (forearmCm.present) {
      map['forearm_cm'] = Variable<double>(forearmCm.value);
    }
    if (thighCm.present) {
      map['thigh_cm'] = Variable<double>(thighCm.value);
    }
    if (calfCm.present) {
      map['calf_cm'] = Variable<double>(calfCm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('neckCm: $neckCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('bicepsCm: $bicepsCm, ')
          ..write('forearmCm: $forearmCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('calfCm: $calfCm')
          ..write(')'))
        .toString();
  }
}

class $ProgramWarningDismissalsTable extends ProgramWarningDismissals
    with TableInfo<$ProgramWarningDismissalsTable, ProgramWarningDismissalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramWarningDismissalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<int> programId = GeneratedColumn<int>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES programs (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> dismissedAt =
      GeneratedColumn<int>(
        'dismissed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $ProgramWarningDismissalsTable.$converterdismissedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [id, programId, dismissedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'program_warning_dismissals';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramWarningDismissalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramWarningDismissalRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramWarningDismissalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_id'],
      )!,
      dismissedAt: $ProgramWarningDismissalsTable.$converterdismissedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}dismissed_at'],
        )!,
      ),
    );
  }

  @override
  $ProgramWarningDismissalsTable createAlias(String alias) {
    return $ProgramWarningDismissalsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdismissedAt =
      const DateTimeConverter();
}

class ProgramWarningDismissalRow extends DataClass
    implements Insertable<ProgramWarningDismissalRow> {
  final int id;
  final int programId;
  final DateTime dismissedAt;
  const ProgramWarningDismissalRow({
    required this.id,
    required this.programId,
    required this.dismissedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<int>(programId);
    {
      map['dismissed_at'] = Variable<int>(
        $ProgramWarningDismissalsTable.$converterdismissedAt.toSql(dismissedAt),
      );
    }
    return map;
  }

  ProgramWarningDismissalsCompanion toCompanion(bool nullToAbsent) {
    return ProgramWarningDismissalsCompanion(
      id: Value(id),
      programId: Value(programId),
      dismissedAt: Value(dismissedAt),
    );
  }

  factory ProgramWarningDismissalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramWarningDismissalRow(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<int>(json['programId']),
      dismissedAt: serializer.fromJson<DateTime>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<int>(programId),
      'dismissedAt': serializer.toJson<DateTime>(dismissedAt),
    };
  }

  ProgramWarningDismissalRow copyWith({
    int? id,
    int? programId,
    DateTime? dismissedAt,
  }) => ProgramWarningDismissalRow(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    dismissedAt: dismissedAt ?? this.dismissedAt,
  );
  ProgramWarningDismissalRow copyWithCompanion(
    ProgramWarningDismissalsCompanion data,
  ) {
    return ProgramWarningDismissalRow(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      dismissedAt: data.dismissedAt.present
          ? data.dismissedAt.value
          : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramWarningDismissalRow(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, programId, dismissedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramWarningDismissalRow &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.dismissedAt == this.dismissedAt);
}

class ProgramWarningDismissalsCompanion
    extends UpdateCompanion<ProgramWarningDismissalRow> {
  final Value<int> id;
  final Value<int> programId;
  final Value<DateTime> dismissedAt;
  const ProgramWarningDismissalsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.dismissedAt = const Value.absent(),
  });
  ProgramWarningDismissalsCompanion.insert({
    this.id = const Value.absent(),
    required int programId,
    required DateTime dismissedAt,
  }) : programId = Value(programId),
       dismissedAt = Value(dismissedAt);
  static Insertable<ProgramWarningDismissalRow> custom({
    Expression<int>? id,
    Expression<int>? programId,
    Expression<int>? dismissedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
    });
  }

  ProgramWarningDismissalsCompanion copyWith({
    Value<int>? id,
    Value<int>? programId,
    Value<DateTime>? dismissedAt,
  }) {
    return ProgramWarningDismissalsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<int>(programId.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<int>(
        $ProgramWarningDismissalsTable.$converterdismissedAt.toSql(
          dismissedAt.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramWarningDismissalsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }
}

class $PlanScheduleTable extends PlanSchedule
    with TableInfo<$PlanScheduleTable, PlanScheduleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanScheduleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programDayIdMeta = const VerificationMeta(
    'programDayId',
  );
  @override
  late final GeneratedColumn<int> programDayId = GeneratedColumn<int>(
    'program_day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES program_days (id)',
    ),
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [id, programDayId, scheduledDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_schedule';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanScheduleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_day_id')) {
      context.handle(
        _programDayIdMeta,
        programDayId.isAcceptableOrUnknown(
          data['program_day_id']!,
          _programDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_programDayIdMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {programDayId, scheduledDate},
  ];
  @override
  PlanScheduleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanScheduleData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_day_id'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      )!,
    );
  }

  @override
  $PlanScheduleTable createAlias(String alias) {
    return $PlanScheduleTable(attachedDatabase, alias);
  }
}

class PlanScheduleData extends DataClass
    implements Insertable<PlanScheduleData> {
  final int id;
  final int programDayId;
  final DateTime scheduledDate;
  const PlanScheduleData({
    required this.id,
    required this.programDayId,
    required this.scheduledDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_day_id'] = Variable<int>(programDayId);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    return map;
  }

  PlanScheduleCompanion toCompanion(bool nullToAbsent) {
    return PlanScheduleCompanion(
      id: Value(id),
      programDayId: Value(programDayId),
      scheduledDate: Value(scheduledDate),
    );
  }

  factory PlanScheduleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanScheduleData(
      id: serializer.fromJson<int>(json['id']),
      programDayId: serializer.fromJson<int>(json['programDayId']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programDayId': serializer.toJson<int>(programDayId),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
    };
  }

  PlanScheduleData copyWith({
    int? id,
    int? programDayId,
    DateTime? scheduledDate,
  }) => PlanScheduleData(
    id: id ?? this.id,
    programDayId: programDayId ?? this.programDayId,
    scheduledDate: scheduledDate ?? this.scheduledDate,
  );
  PlanScheduleData copyWithCompanion(PlanScheduleCompanion data) {
    return PlanScheduleData(
      id: data.id.present ? data.id.value : this.id,
      programDayId: data.programDayId.present
          ? data.programDayId.value
          : this.programDayId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanScheduleData(')
          ..write('id: $id, ')
          ..write('programDayId: $programDayId, ')
          ..write('scheduledDate: $scheduledDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, programDayId, scheduledDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanScheduleData &&
          other.id == this.id &&
          other.programDayId == this.programDayId &&
          other.scheduledDate == this.scheduledDate);
}

class PlanScheduleCompanion extends UpdateCompanion<PlanScheduleData> {
  final Value<int> id;
  final Value<int> programDayId;
  final Value<DateTime> scheduledDate;
  const PlanScheduleCompanion({
    this.id = const Value.absent(),
    this.programDayId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
  });
  PlanScheduleCompanion.insert({
    this.id = const Value.absent(),
    required int programDayId,
    required DateTime scheduledDate,
  }) : programDayId = Value(programDayId),
       scheduledDate = Value(scheduledDate);
  static Insertable<PlanScheduleData> custom({
    Expression<int>? id,
    Expression<int>? programDayId,
    Expression<DateTime>? scheduledDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programDayId != null) 'program_day_id': programDayId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
    });
  }

  PlanScheduleCompanion copyWith({
    Value<int>? id,
    Value<int>? programDayId,
    Value<DateTime>? scheduledDate,
  }) {
    return PlanScheduleCompanion(
      id: id ?? this.id,
      programDayId: programDayId ?? this.programDayId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programDayId.present) {
      map['program_day_id'] = Variable<int>(programDayId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanScheduleCompanion(')
          ..write('id: $id, ')
          ..write('programDayId: $programDayId, ')
          ..write('scheduledDate: $scheduledDate')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $MuscleGroupsTable muscleGroups = $MuscleGroupsTable(this);
  late final $ContraindicationTagsTable contraindicationTags =
      $ContraindicationTagsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $ExerciseMusclesTable exerciseMuscles = $ExerciseMusclesTable(
    this,
  );
  late final $ExerciseContraindicationsTable exerciseContraindications =
      $ExerciseContraindicationsTable(this);
  late final $UserContraindicationsTable userContraindications =
      $UserContraindicationsTable(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $ProgramDaysTable programDays = $ProgramDaysTable(this);
  late final $ProgramDayExercisesTable programDayExercises =
      $ProgramDayExercisesTable(this);
  late final $WorkoutRemindersTable workoutReminders = $WorkoutRemindersTable(
    this,
  );
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $WorkoutSetResultsTable workoutSetResults =
      $WorkoutSetResultsTable(this);
  late final $ScheduleMarksTable scheduleMarks = $ScheduleMarksTable(this);
  late final $BodyMeasurementsTable bodyMeasurements = $BodyMeasurementsTable(
    this,
  );
  late final $ProgramWarningDismissalsTable programWarningDismissals =
      $ProgramWarningDismissalsTable(this);
  late final $PlanScheduleTable planSchedule = $PlanScheduleTable(this);
  late final Index exerciseMusclesMuscleGroupIdx = Index(
    'exercise_muscles_muscle_group_idx',
    'CREATE INDEX exercise_muscles_muscle_group_idx ON exercise_muscles (muscle_group_id)',
  );
  late final Index exerciseContraindicationsTagIdx = Index(
    'exercise_contraindications_tag_idx',
    'CREATE INDEX exercise_contraindications_tag_idx ON exercise_contraindications (contraindication_tag_id)',
  );
  late final Index userContraindicationsTagIdx = Index(
    'user_contraindications_tag_idx',
    'CREATE INDEX user_contraindications_tag_idx ON user_contraindications (contraindication_tag_id)',
  );
  late final Index programDaysProgramIdx = Index(
    'program_days_program_idx',
    'CREATE INDEX program_days_program_idx ON program_days (program_id)',
  );
  late final Index programDayExercisesDayIdx = Index(
    'program_day_exercises_day_idx',
    'CREATE INDEX program_day_exercises_day_idx ON program_day_exercises (day_id)',
  );
  late final Index programDayExercisesExerciseIdx = Index(
    'program_day_exercises_exercise_idx',
    'CREATE INDEX program_day_exercises_exercise_idx ON program_day_exercises (exercise_id)',
  );
  late final Index workoutRemindersDayIdx = Index(
    'workout_reminders_day_idx',
    'CREATE INDEX workout_reminders_day_idx ON workout_reminders (program_day_id)',
  );
  late final Index workoutSessionsProgramIdx = Index(
    'workout_sessions_program_idx',
    'CREATE INDEX workout_sessions_program_idx ON workout_sessions (program_id)',
  );
  late final Index workoutSessionsDayIdx = Index(
    'workout_sessions_day_idx',
    'CREATE INDEX workout_sessions_day_idx ON workout_sessions (program_day_id)',
  );
  late final Index workoutSetResultsSessionIdx = Index(
    'workout_set_results_session_idx',
    'CREATE INDEX workout_set_results_session_idx ON workout_set_results (session_id)',
  );
  late final Index workoutSetResultsExerciseIdx = Index(
    'workout_set_results_exercise_idx',
    'CREATE INDEX workout_set_results_exercise_idx ON workout_set_results (exercise_id)',
  );
  late final Index scheduleMarksDayIdx = Index(
    'schedule_marks_day_idx',
    'CREATE INDEX schedule_marks_day_idx ON schedule_marks (program_day_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMeta,
    muscleGroups,
    contraindicationTags,
    exercises,
    userProfiles,
    exerciseMuscles,
    exerciseContraindications,
    userContraindications,
    programs,
    programDays,
    programDayExercises,
    workoutReminders,
    workoutSessions,
    workoutSetResults,
    scheduleMarks,
    bodyMeasurements,
    programWarningDismissals,
    planSchedule,
    exerciseMusclesMuscleGroupIdx,
    exerciseContraindicationsTagIdx,
    userContraindicationsTagIdx,
    programDaysProgramIdx,
    programDayExercisesDayIdx,
    programDayExercisesExerciseIdx,
    workoutRemindersDayIdx,
    workoutSessionsProgramIdx,
    workoutSessionsDayIdx,
    workoutSetResultsSessionIdx,
    workoutSetResultsExerciseIdx,
    scheduleMarksDayIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_muscles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'muscle_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_muscles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('exercise_contraindications', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contraindication_tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('exercise_contraindications', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'user_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_contraindications', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contraindication_tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_contraindications', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'programs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('program_days', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'program_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('program_day_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('program_day_exercises', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'program_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_reminders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'programs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'program_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_set_results', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_set_results', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'program_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_marks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'programs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('program_warning_dismissals', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaData,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaData,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>,
          ),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaData,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;
typedef $$MuscleGroupsTableCreateCompanionBuilder =
    MuscleGroupsCompanion Function({
      Value<int> id,
      required String key,
      required String labelRu,
      required MuscleView view,
      required String regionKey,
      Value<String?> parentKey,
    });
typedef $$MuscleGroupsTableUpdateCompanionBuilder =
    MuscleGroupsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> labelRu,
      Value<MuscleView> view,
      Value<String> regionKey,
      Value<String?> parentKey,
    });

final class $$MuscleGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $MuscleGroupsTable, MuscleGroupRow> {
  $$MuscleGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseMusclesTable, List<ExerciseMuscleRow>>
  _exerciseMusclesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseMuscles,
    aliasName: 'muscle_groups__id__exercise_muscles__muscle_group_id',
  );

  $$ExerciseMusclesTableProcessedTableManager get exerciseMusclesRefs {
    final manager = $$ExerciseMusclesTableTableManager(
      $_db,
      $_db.exerciseMuscles,
    ).filter((f) => f.muscleGroupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseMusclesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MuscleGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $MuscleGroupsTable> {
  $$MuscleGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelRu => $composableBuilder(
    column: $table.labelRu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MuscleView, MuscleView, String> get view =>
      $composableBuilder(
        column: $table.view,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get regionKey => $composableBuilder(
    column: $table.regionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentKey => $composableBuilder(
    column: $table.parentKey,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exerciseMusclesRefs(
    Expression<bool> Function($$ExerciseMusclesTableFilterComposer f) f,
  ) {
    final $$ExerciseMusclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseMuscles,
      getReferencedColumn: (t) => t.muscleGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseMusclesTableFilterComposer(
            $db: $db,
            $table: $db.exerciseMuscles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MuscleGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $MuscleGroupsTable> {
  $$MuscleGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelRu => $composableBuilder(
    column: $table.labelRu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get view => $composableBuilder(
    column: $table.view,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionKey => $composableBuilder(
    column: $table.regionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentKey => $composableBuilder(
    column: $table.parentKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MuscleGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MuscleGroupsTable> {
  $$MuscleGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get labelRu =>
      $composableBuilder(column: $table.labelRu, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MuscleView, String> get view =>
      $composableBuilder(column: $table.view, builder: (column) => column);

  GeneratedColumn<String> get regionKey =>
      $composableBuilder(column: $table.regionKey, builder: (column) => column);

  GeneratedColumn<String> get parentKey =>
      $composableBuilder(column: $table.parentKey, builder: (column) => column);

  Expression<T> exerciseMusclesRefs<T extends Object>(
    Expression<T> Function($$ExerciseMusclesTableAnnotationComposer a) f,
  ) {
    final $$ExerciseMusclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseMuscles,
      getReferencedColumn: (t) => t.muscleGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseMusclesTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseMuscles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MuscleGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MuscleGroupsTable,
          MuscleGroupRow,
          $$MuscleGroupsTableFilterComposer,
          $$MuscleGroupsTableOrderingComposer,
          $$MuscleGroupsTableAnnotationComposer,
          $$MuscleGroupsTableCreateCompanionBuilder,
          $$MuscleGroupsTableUpdateCompanionBuilder,
          (MuscleGroupRow, $$MuscleGroupsTableReferences),
          MuscleGroupRow,
          PrefetchHooks Function({bool exerciseMusclesRefs})
        > {
  $$MuscleGroupsTableTableManager(_$AppDatabase db, $MuscleGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MuscleGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MuscleGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MuscleGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> labelRu = const Value.absent(),
                Value<MuscleView> view = const Value.absent(),
                Value<String> regionKey = const Value.absent(),
                Value<String?> parentKey = const Value.absent(),
              }) => MuscleGroupsCompanion(
                id: id,
                key: key,
                labelRu: labelRu,
                view: view,
                regionKey: regionKey,
                parentKey: parentKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String labelRu,
                required MuscleView view,
                required String regionKey,
                Value<String?> parentKey = const Value.absent(),
              }) => MuscleGroupsCompanion.insert(
                id: id,
                key: key,
                labelRu: labelRu,
                view: view,
                regionKey: regionKey,
                parentKey: parentKey,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MuscleGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseMusclesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exerciseMusclesRefs) db.exerciseMuscles,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exerciseMusclesRefs)
                    await $_getPrefetchedData<
                      MuscleGroupRow,
                      $MuscleGroupsTable,
                      ExerciseMuscleRow
                    >(
                      currentTable: table,
                      referencedTable: $$MuscleGroupsTableReferences
                          ._exerciseMusclesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MuscleGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).exerciseMusclesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.muscleGroupId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MuscleGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MuscleGroupsTable,
      MuscleGroupRow,
      $$MuscleGroupsTableFilterComposer,
      $$MuscleGroupsTableOrderingComposer,
      $$MuscleGroupsTableAnnotationComposer,
      $$MuscleGroupsTableCreateCompanionBuilder,
      $$MuscleGroupsTableUpdateCompanionBuilder,
      (MuscleGroupRow, $$MuscleGroupsTableReferences),
      MuscleGroupRow,
      PrefetchHooks Function({bool exerciseMusclesRefs})
    >;
typedef $$ContraindicationTagsTableCreateCompanionBuilder =
    ContraindicationTagsCompanion Function({
      Value<int> id,
      required String key,
      required String labelRu,
    });
typedef $$ContraindicationTagsTableUpdateCompanionBuilder =
    ContraindicationTagsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> labelRu,
    });

final class $$ContraindicationTagsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ContraindicationTagsTable,
          ContraindicationTagRow
        > {
  $$ContraindicationTagsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ExerciseContraindicationsTable,
    List<ExerciseContraindicationRow>
  >
  _exerciseContraindicationsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.exerciseContraindications,
    aliasName:
        'contraindication_tags__id__exercise_contraindications__contraindication_tag_id',
  );

  $$ExerciseContraindicationsTableProcessedTableManager
  get exerciseContraindicationsRefs {
    final manager =
        $$ExerciseContraindicationsTableTableManager(
          $_db,
          $_db.exerciseContraindications,
        ).filter(
          (f) => f.contraindicationTagId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _exerciseContraindicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $UserContraindicationsTable,
    List<UserContraindicationRow>
  >
  _userContraindicationsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.userContraindications,
    aliasName:
        'contraindication_tags__id__user_contraindications__contraindication_tag_id',
  );

  $$UserContraindicationsTableProcessedTableManager
  get userContraindicationsRefs {
    final manager =
        $$UserContraindicationsTableTableManager(
          $_db,
          $_db.userContraindications,
        ).filter(
          (f) => f.contraindicationTagId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _userContraindicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContraindicationTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ContraindicationTagsTable> {
  $$ContraindicationTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelRu => $composableBuilder(
    column: $table.labelRu,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exerciseContraindicationsRefs(
    Expression<bool> Function($$ExerciseContraindicationsTableFilterComposer f)
    f,
  ) {
    final $$ExerciseContraindicationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseContraindications,
          getReferencedColumn: (t) => t.contraindicationTagId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseContraindicationsTableFilterComposer(
                $db: $db,
                $table: $db.exerciseContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> userContraindicationsRefs(
    Expression<bool> Function($$UserContraindicationsTableFilterComposer f) f,
  ) {
    final $$UserContraindicationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userContraindications,
          getReferencedColumn: (t) => t.contraindicationTagId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserContraindicationsTableFilterComposer(
                $db: $db,
                $table: $db.userContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContraindicationTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContraindicationTagsTable> {
  $$ContraindicationTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelRu => $composableBuilder(
    column: $table.labelRu,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContraindicationTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContraindicationTagsTable> {
  $$ContraindicationTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get labelRu =>
      $composableBuilder(column: $table.labelRu, builder: (column) => column);

  Expression<T> exerciseContraindicationsRefs<T extends Object>(
    Expression<T> Function($$ExerciseContraindicationsTableAnnotationComposer a)
    f,
  ) {
    final $$ExerciseContraindicationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseContraindications,
          getReferencedColumn: (t) => t.contraindicationTagId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseContraindicationsTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> userContraindicationsRefs<T extends Object>(
    Expression<T> Function($$UserContraindicationsTableAnnotationComposer a) f,
  ) {
    final $$UserContraindicationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userContraindications,
          getReferencedColumn: (t) => t.contraindicationTagId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserContraindicationsTableAnnotationComposer(
                $db: $db,
                $table: $db.userContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContraindicationTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContraindicationTagsTable,
          ContraindicationTagRow,
          $$ContraindicationTagsTableFilterComposer,
          $$ContraindicationTagsTableOrderingComposer,
          $$ContraindicationTagsTableAnnotationComposer,
          $$ContraindicationTagsTableCreateCompanionBuilder,
          $$ContraindicationTagsTableUpdateCompanionBuilder,
          (ContraindicationTagRow, $$ContraindicationTagsTableReferences),
          ContraindicationTagRow,
          PrefetchHooks Function({
            bool exerciseContraindicationsRefs,
            bool userContraindicationsRefs,
          })
        > {
  $$ContraindicationTagsTableTableManager(
    _$AppDatabase db,
    $ContraindicationTagsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContraindicationTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContraindicationTagsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContraindicationTagsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> labelRu = const Value.absent(),
              }) => ContraindicationTagsCompanion(
                id: id,
                key: key,
                labelRu: labelRu,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String labelRu,
              }) => ContraindicationTagsCompanion.insert(
                id: id,
                key: key,
                labelRu: labelRu,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContraindicationTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                exerciseContraindicationsRefs = false,
                userContraindicationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseContraindicationsRefs)
                      db.exerciseContraindications,
                    if (userContraindicationsRefs) db.userContraindications,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseContraindicationsRefs)
                        await $_getPrefetchedData<
                          ContraindicationTagRow,
                          $ContraindicationTagsTable,
                          ExerciseContraindicationRow
                        >(
                          currentTable: table,
                          referencedTable: $$ContraindicationTagsTableReferences
                              ._exerciseContraindicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContraindicationTagsTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseContraindicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contraindicationTagId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userContraindicationsRefs)
                        await $_getPrefetchedData<
                          ContraindicationTagRow,
                          $ContraindicationTagsTable,
                          UserContraindicationRow
                        >(
                          currentTable: table,
                          referencedTable: $$ContraindicationTagsTableReferences
                              ._userContraindicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContraindicationTagsTableReferences(
                                db,
                                table,
                                p0,
                              ).userContraindicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contraindicationTagId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContraindicationTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContraindicationTagsTable,
      ContraindicationTagRow,
      $$ContraindicationTagsTableFilterComposer,
      $$ContraindicationTagsTableOrderingComposer,
      $$ContraindicationTagsTableAnnotationComposer,
      $$ContraindicationTagsTableCreateCompanionBuilder,
      $$ContraindicationTagsTableUpdateCompanionBuilder,
      (ContraindicationTagRow, $$ContraindicationTagsTableReferences),
      ContraindicationTagRow,
      PrefetchHooks Function({
        bool exerciseContraindicationsRefs,
        bool userContraindicationsRefs,
      })
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      required String name,
      Value<String> description,
      Value<String> instructions,
      Value<List<String>> commonMistakes,
      required ExerciseType type,
      Value<String?> thumbnailPath,
      Value<String?> animationPath,
      Value<Uint8List?> thumbnailBlob,
      Value<Uint8List?> animationBlob,
      Value<bool> isCustom,
      Value<bool> hideOptional,
      Value<bool> fixedWeight,
      Value<bool> perSide,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> description,
      Value<String> instructions,
      Value<List<String>> commonMistakes,
      Value<ExerciseType> type,
      Value<String?> thumbnailPath,
      Value<String?> animationPath,
      Value<Uint8List?> thumbnailBlob,
      Value<Uint8List?> animationBlob,
      Value<bool> isCustom,
      Value<bool> hideOptional,
      Value<bool> fixedWeight,
      Value<bool> perSide,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, ExerciseRow> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseMusclesTable, List<ExerciseMuscleRow>>
  _exerciseMusclesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseMuscles,
    aliasName: 'exercises__id__exercise_muscles__exercise_id',
  );

  $$ExerciseMusclesTableProcessedTableManager get exerciseMusclesRefs {
    final manager = $$ExerciseMusclesTableTableManager(
      $_db,
      $_db.exerciseMuscles,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseMusclesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ExerciseContraindicationsTable,
    List<ExerciseContraindicationRow>
  >
  _exerciseContraindicationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exerciseContraindications,
        aliasName: 'exercises__id__exercise_contraindications__exercise_id',
      );

  $$ExerciseContraindicationsTableProcessedTableManager
  get exerciseContraindicationsRefs {
    final manager = $$ExerciseContraindicationsTableTableManager(
      $_db,
      $_db.exerciseContraindications,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseContraindicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ProgramDayExercisesTable,
    List<ProgramDayExerciseRow>
  >
  _programDayExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.programDayExercises,
        aliasName: 'exercises__id__program_day_exercises__exercise_id',
      );

  $$ProgramDayExercisesTableProcessedTableManager get programDayExercisesRefs {
    final manager = $$ProgramDayExercisesTableTableManager(
      $_db,
      $_db.programDayExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _programDayExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutSetResultsTable, List<WorkoutSetResultRow>>
  _workoutSetResultsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workoutSetResults,
        aliasName: 'exercises__id__workout_set_results__exercise_id',
      );

  $$WorkoutSetResultsTableProcessedTableManager get workoutSetResultsRefs {
    final manager = $$WorkoutSetResultsTableTableManager(
      $_db,
      $_db.workoutSetResults,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutSetResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get commonMistakes => $composableBuilder(
    column: $table.commonMistakes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ExerciseType, ExerciseType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animationPath => $composableBuilder(
    column: $table.animationPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get thumbnailBlob => $composableBuilder(
    column: $table.thumbnailBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get animationBlob => $composableBuilder(
    column: $table.animationBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hideOptional => $composableBuilder(
    column: $table.hideOptional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fixedWeight => $composableBuilder(
    column: $table.fixedWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get perSide => $composableBuilder(
    column: $table.perSide,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> exerciseMusclesRefs(
    Expression<bool> Function($$ExerciseMusclesTableFilterComposer f) f,
  ) {
    final $$ExerciseMusclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseMuscles,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseMusclesTableFilterComposer(
            $db: $db,
            $table: $db.exerciseMuscles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseContraindicationsRefs(
    Expression<bool> Function($$ExerciseContraindicationsTableFilterComposer f)
    f,
  ) {
    final $$ExerciseContraindicationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseContraindications,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseContraindicationsTableFilterComposer(
                $db: $db,
                $table: $db.exerciseContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> programDayExercisesRefs(
    Expression<bool> Function($$ProgramDayExercisesTableFilterComposer f) f,
  ) {
    final $$ProgramDayExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programDayExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDayExercisesTableFilterComposer(
            $db: $db,
            $table: $db.programDayExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutSetResultsRefs(
    Expression<bool> Function($$WorkoutSetResultsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSetResults,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetResultsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSetResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commonMistakes => $composableBuilder(
    column: $table.commonMistakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animationPath => $composableBuilder(
    column: $table.animationPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get thumbnailBlob => $composableBuilder(
    column: $table.thumbnailBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get animationBlob => $composableBuilder(
    column: $table.animationBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hideOptional => $composableBuilder(
    column: $table.hideOptional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fixedWeight => $composableBuilder(
    column: $table.fixedWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get perSide => $composableBuilder(
    column: $table.perSide,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get commonMistakes =>
      $composableBuilder(
        column: $table.commonMistakes,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<ExerciseType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get animationPath => $composableBuilder(
    column: $table.animationPath,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get thumbnailBlob => $composableBuilder(
    column: $table.thumbnailBlob,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get animationBlob => $composableBuilder(
    column: $table.animationBlob,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<bool> get hideOptional => $composableBuilder(
    column: $table.hideOptional,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fixedWeight => $composableBuilder(
    column: $table.fixedWeight,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get perSide =>
      $composableBuilder(column: $table.perSide, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> exerciseMusclesRefs<T extends Object>(
    Expression<T> Function($$ExerciseMusclesTableAnnotationComposer a) f,
  ) {
    final $$ExerciseMusclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseMuscles,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseMusclesTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseMuscles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exerciseContraindicationsRefs<T extends Object>(
    Expression<T> Function($$ExerciseContraindicationsTableAnnotationComposer a)
    f,
  ) {
    final $$ExerciseContraindicationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseContraindications,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseContraindicationsTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> programDayExercisesRefs<T extends Object>(
    Expression<T> Function($$ProgramDayExercisesTableAnnotationComposer a) f,
  ) {
    final $$ProgramDayExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.programDayExercises,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProgramDayExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.programDayExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> workoutSetResultsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetResultsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetResultsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workoutSetResults,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkoutSetResultsTableAnnotationComposer(
                $db: $db,
                $table: $db.workoutSetResults,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          ExerciseRow,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (ExerciseRow, $$ExercisesTableReferences),
          ExerciseRow,
          PrefetchHooks Function({
            bool exerciseMusclesRefs,
            bool exerciseContraindicationsRefs,
            bool programDayExercisesRefs,
            bool workoutSetResultsRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<List<String>> commonMistakes = const Value.absent(),
                Value<ExerciseType> type = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> animationPath = const Value.absent(),
                Value<Uint8List?> thumbnailBlob = const Value.absent(),
                Value<Uint8List?> animationBlob = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<bool> hideOptional = const Value.absent(),
                Value<bool> fixedWeight = const Value.absent(),
                Value<bool> perSide = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                description: description,
                instructions: instructions,
                commonMistakes: commonMistakes,
                type: type,
                thumbnailPath: thumbnailPath,
                animationPath: animationPath,
                thumbnailBlob: thumbnailBlob,
                animationBlob: animationBlob,
                isCustom: isCustom,
                hideOptional: hideOptional,
                fixedWeight: fixedWeight,
                perSide: perSide,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> description = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<List<String>> commonMistakes = const Value.absent(),
                required ExerciseType type,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> animationPath = const Value.absent(),
                Value<Uint8List?> thumbnailBlob = const Value.absent(),
                Value<Uint8List?> animationBlob = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<bool> hideOptional = const Value.absent(),
                Value<bool> fixedWeight = const Value.absent(),
                Value<bool> perSide = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                description: description,
                instructions: instructions,
                commonMistakes: commonMistakes,
                type: type,
                thumbnailPath: thumbnailPath,
                animationPath: animationPath,
                thumbnailBlob: thumbnailBlob,
                animationBlob: animationBlob,
                isCustom: isCustom,
                hideOptional: hideOptional,
                fixedWeight: fixedWeight,
                perSide: perSide,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                exerciseMusclesRefs = false,
                exerciseContraindicationsRefs = false,
                programDayExercisesRefs = false,
                workoutSetResultsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseMusclesRefs) db.exerciseMuscles,
                    if (exerciseContraindicationsRefs)
                      db.exerciseContraindications,
                    if (programDayExercisesRefs) db.programDayExercises,
                    if (workoutSetResultsRefs) db.workoutSetResults,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseMusclesRefs)
                        await $_getPrefetchedData<
                          ExerciseRow,
                          $ExercisesTable,
                          ExerciseMuscleRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._exerciseMusclesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseMusclesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseContraindicationsRefs)
                        await $_getPrefetchedData<
                          ExerciseRow,
                          $ExercisesTable,
                          ExerciseContraindicationRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._exerciseContraindicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseContraindicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (programDayExercisesRefs)
                        await $_getPrefetchedData<
                          ExerciseRow,
                          $ExercisesTable,
                          ProgramDayExerciseRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._programDayExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).programDayExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutSetResultsRefs)
                        await $_getPrefetchedData<
                          ExerciseRow,
                          $ExercisesTable,
                          WorkoutSetResultRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._workoutSetResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      ExerciseRow,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (ExerciseRow, $$ExercisesTableReferences),
      ExerciseRow,
      PrefetchHooks Function({
        bool exerciseMusclesRefs,
        bool exerciseContraindicationsRefs,
        bool programDayExercisesRefs,
        bool workoutSetResultsRefs,
      })
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<DateTime?> birthDate,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<String?> gender,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<DateTime?> birthDate,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<String?> gender,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
    });

final class $$UserProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow> {
  $$UserProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $UserContraindicationsTable,
    List<UserContraindicationRow>
  >
  _userContraindicationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userContraindications,
        aliasName: 'user_profiles__id__user_contraindications__user_id',
      );

  $$UserContraindicationsTableProcessedTableManager
  get userContraindicationsRefs {
    final manager = $$UserContraindicationsTableTableManager(
      $_db,
      $_db.userContraindications,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userContraindicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get birthDate =>
      $composableBuilder(
        column: $table.birthDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> userContraindicationsRefs(
    Expression<bool> Function($$UserContraindicationsTableFilterComposer f) f,
  ) {
    final $$UserContraindicationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userContraindications,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserContraindicationsTableFilterComposer(
                $db: $db,
                $table: $db.userContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> userContraindicationsRefs<T extends Object>(
    Expression<T> Function($$UserContraindicationsTableAnnotationComposer a) f,
  ) {
    final $$UserContraindicationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userContraindications,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserContraindicationsTableAnnotationComposer(
                $db: $db,
                $table: $db.userContraindications,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfileRow,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (UserProfileRow, $$UserProfilesTableReferences),
          UserProfileRow,
          PrefetchHooks Function({bool userContraindicationsRefs})
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                name: name,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                gender: gender,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                name: name,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                gender: gender,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userContraindicationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userContraindicationsRefs) db.userContraindications,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userContraindicationsRefs)
                    await $_getPrefetchedData<
                      UserProfileRow,
                      $UserProfilesTable,
                      UserContraindicationRow
                    >(
                      currentTable: table,
                      referencedTable: $$UserProfilesTableReferences
                          ._userContraindicationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).userContraindicationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfileRow,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (UserProfileRow, $$UserProfilesTableReferences),
      UserProfileRow,
      PrefetchHooks Function({bool userContraindicationsRefs})
    >;
typedef $$ExerciseMusclesTableCreateCompanionBuilder =
    ExerciseMusclesCompanion Function({
      required int exerciseId,
      required int muscleGroupId,
      required MuscleIntensity intensity,
      Value<int> rowid,
    });
typedef $$ExerciseMusclesTableUpdateCompanionBuilder =
    ExerciseMusclesCompanion Function({
      Value<int> exerciseId,
      Value<int> muscleGroupId,
      Value<MuscleIntensity> intensity,
      Value<int> rowid,
    });

final class $$ExerciseMusclesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseMusclesTable,
          ExerciseMuscleRow
        > {
  $$ExerciseMusclesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('exercise_muscles__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MuscleGroupsTable _muscleGroupIdTable(_$AppDatabase db) => db
      .muscleGroups
      .createAlias('exercise_muscles__muscle_group_id__muscle_groups__id');

  $$MuscleGroupsTableProcessedTableManager get muscleGroupId {
    final $_column = $_itemColumn<int>('muscle_group_id')!;

    final manager = $$MuscleGroupsTableTableManager(
      $_db,
      $_db.muscleGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_muscleGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseMusclesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseMusclesTable> {
  $$ExerciseMusclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<MuscleIntensity, MuscleIntensity, String>
  get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MuscleGroupsTableFilterComposer get muscleGroupId {
    final $$MuscleGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.muscleGroupId,
      referencedTable: $db.muscleGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MuscleGroupsTableFilterComposer(
            $db: $db,
            $table: $db.muscleGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseMusclesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseMusclesTable> {
  $$ExerciseMusclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MuscleGroupsTableOrderingComposer get muscleGroupId {
    final $$MuscleGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.muscleGroupId,
      referencedTable: $db.muscleGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MuscleGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.muscleGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseMusclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseMusclesTable> {
  $$ExerciseMusclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<MuscleIntensity, String> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MuscleGroupsTableAnnotationComposer get muscleGroupId {
    final $$MuscleGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.muscleGroupId,
      referencedTable: $db.muscleGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MuscleGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.muscleGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseMusclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseMusclesTable,
          ExerciseMuscleRow,
          $$ExerciseMusclesTableFilterComposer,
          $$ExerciseMusclesTableOrderingComposer,
          $$ExerciseMusclesTableAnnotationComposer,
          $$ExerciseMusclesTableCreateCompanionBuilder,
          $$ExerciseMusclesTableUpdateCompanionBuilder,
          (ExerciseMuscleRow, $$ExerciseMusclesTableReferences),
          ExerciseMuscleRow,
          PrefetchHooks Function({bool exerciseId, bool muscleGroupId})
        > {
  $$ExerciseMusclesTableTableManager(
    _$AppDatabase db,
    $ExerciseMusclesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseMusclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseMusclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseMusclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> exerciseId = const Value.absent(),
                Value<int> muscleGroupId = const Value.absent(),
                Value<MuscleIntensity> intensity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseMusclesCompanion(
                exerciseId: exerciseId,
                muscleGroupId: muscleGroupId,
                intensity: intensity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int exerciseId,
                required int muscleGroupId,
                required MuscleIntensity intensity,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseMusclesCompanion.insert(
                exerciseId: exerciseId,
                muscleGroupId: muscleGroupId,
                intensity: intensity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseMusclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false, muscleGroupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$ExerciseMusclesTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$ExerciseMusclesTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (muscleGroupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.muscleGroupId,
                                referencedTable:
                                    $$ExerciseMusclesTableReferences
                                        ._muscleGroupIdTable(db),
                                referencedColumn:
                                    $$ExerciseMusclesTableReferences
                                        ._muscleGroupIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseMusclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseMusclesTable,
      ExerciseMuscleRow,
      $$ExerciseMusclesTableFilterComposer,
      $$ExerciseMusclesTableOrderingComposer,
      $$ExerciseMusclesTableAnnotationComposer,
      $$ExerciseMusclesTableCreateCompanionBuilder,
      $$ExerciseMusclesTableUpdateCompanionBuilder,
      (ExerciseMuscleRow, $$ExerciseMusclesTableReferences),
      ExerciseMuscleRow,
      PrefetchHooks Function({bool exerciseId, bool muscleGroupId})
    >;
typedef $$ExerciseContraindicationsTableCreateCompanionBuilder =
    ExerciseContraindicationsCompanion Function({
      required int exerciseId,
      required int contraindicationTagId,
      Value<int> rowid,
    });
typedef $$ExerciseContraindicationsTableUpdateCompanionBuilder =
    ExerciseContraindicationsCompanion Function({
      Value<int> exerciseId,
      Value<int> contraindicationTagId,
      Value<int> rowid,
    });

final class $$ExerciseContraindicationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseContraindicationsTable,
          ExerciseContraindicationRow
        > {
  $$ExerciseContraindicationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) => db.exercises
      .createAlias('exercise_contraindications__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContraindicationTagsTable _contraindicationTagIdTable(
    _$AppDatabase db,
  ) => db.contraindicationTags.createAlias(
    'exercise_contraindications__contraindication_tag_id__contraindication_tags__id',
  );

  $$ContraindicationTagsTableProcessedTableManager get contraindicationTagId {
    final $_column = $_itemColumn<int>('contraindication_tag_id')!;

    final manager = $$ContraindicationTagsTableTableManager(
      $_db,
      $_db.contraindicationTags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _contraindicationTagIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseContraindicationsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseContraindicationsTable> {
  $$ExerciseContraindicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContraindicationTagsTableFilterComposer get contraindicationTagId {
    final $$ContraindicationTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contraindicationTagId,
      referencedTable: $db.contraindicationTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContraindicationTagsTableFilterComposer(
            $db: $db,
            $table: $db.contraindicationTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseContraindicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseContraindicationsTable> {
  $$ExerciseContraindicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContraindicationTagsTableOrderingComposer get contraindicationTagId {
    final $$ContraindicationTagsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contraindicationTagId,
          referencedTable: $db.contraindicationTags,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContraindicationTagsTableOrderingComposer(
                $db: $db,
                $table: $db.contraindicationTags,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExerciseContraindicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseContraindicationsTable> {
  $$ExerciseContraindicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContraindicationTagsTableAnnotationComposer get contraindicationTagId {
    final $$ContraindicationTagsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contraindicationTagId,
          referencedTable: $db.contraindicationTags,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContraindicationTagsTableAnnotationComposer(
                $db: $db,
                $table: $db.contraindicationTags,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExerciseContraindicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseContraindicationsTable,
          ExerciseContraindicationRow,
          $$ExerciseContraindicationsTableFilterComposer,
          $$ExerciseContraindicationsTableOrderingComposer,
          $$ExerciseContraindicationsTableAnnotationComposer,
          $$ExerciseContraindicationsTableCreateCompanionBuilder,
          $$ExerciseContraindicationsTableUpdateCompanionBuilder,
          (
            ExerciseContraindicationRow,
            $$ExerciseContraindicationsTableReferences,
          ),
          ExerciseContraindicationRow,
          PrefetchHooks Function({bool exerciseId, bool contraindicationTagId})
        > {
  $$ExerciseContraindicationsTableTableManager(
    _$AppDatabase db,
    $ExerciseContraindicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseContraindicationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExerciseContraindicationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseContraindicationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> exerciseId = const Value.absent(),
                Value<int> contraindicationTagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseContraindicationsCompanion(
                exerciseId: exerciseId,
                contraindicationTagId: contraindicationTagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int exerciseId,
                required int contraindicationTagId,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseContraindicationsCompanion.insert(
                exerciseId: exerciseId,
                contraindicationTagId: contraindicationTagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseContraindicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false, contraindicationTagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$ExerciseContraindicationsTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$ExerciseContraindicationsTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (contraindicationTagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contraindicationTagId,
                                referencedTable:
                                    $$ExerciseContraindicationsTableReferences
                                        ._contraindicationTagIdTable(db),
                                referencedColumn:
                                    $$ExerciseContraindicationsTableReferences
                                        ._contraindicationTagIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseContraindicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseContraindicationsTable,
      ExerciseContraindicationRow,
      $$ExerciseContraindicationsTableFilterComposer,
      $$ExerciseContraindicationsTableOrderingComposer,
      $$ExerciseContraindicationsTableAnnotationComposer,
      $$ExerciseContraindicationsTableCreateCompanionBuilder,
      $$ExerciseContraindicationsTableUpdateCompanionBuilder,
      (ExerciseContraindicationRow, $$ExerciseContraindicationsTableReferences),
      ExerciseContraindicationRow,
      PrefetchHooks Function({bool exerciseId, bool contraindicationTagId})
    >;
typedef $$UserContraindicationsTableCreateCompanionBuilder =
    UserContraindicationsCompanion Function({
      required int userId,
      required int contraindicationTagId,
      Value<int> rowid,
    });
typedef $$UserContraindicationsTableUpdateCompanionBuilder =
    UserContraindicationsCompanion Function({
      Value<int> userId,
      Value<int> contraindicationTagId,
      Value<int> rowid,
    });

final class $$UserContraindicationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserContraindicationsTable,
          UserContraindicationRow
        > {
  $$UserContraindicationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserProfilesTable _userIdTable(_$AppDatabase db) => db.userProfiles
      .createAlias('user_contraindications__user_id__user_profiles__id');

  $$UserProfilesTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UserProfilesTableTableManager(
      $_db,
      $_db.userProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContraindicationTagsTable _contraindicationTagIdTable(
    _$AppDatabase db,
  ) => db.contraindicationTags.createAlias(
    'user_contraindications__contraindication_tag_id__contraindication_tags__id',
  );

  $$ContraindicationTagsTableProcessedTableManager get contraindicationTagId {
    final $_column = $_itemColumn<int>('contraindication_tag_id')!;

    final manager = $$ContraindicationTagsTableTableManager(
      $_db,
      $_db.contraindicationTags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _contraindicationTagIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserContraindicationsTableFilterComposer
    extends Composer<_$AppDatabase, $UserContraindicationsTable> {
  $$UserContraindicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$UserProfilesTableFilterComposer get userId {
    final $$UserProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.userProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProfilesTableFilterComposer(
            $db: $db,
            $table: $db.userProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContraindicationTagsTableFilterComposer get contraindicationTagId {
    final $$ContraindicationTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contraindicationTagId,
      referencedTable: $db.contraindicationTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContraindicationTagsTableFilterComposer(
            $db: $db,
            $table: $db.contraindicationTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserContraindicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserContraindicationsTable> {
  $$UserContraindicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$UserProfilesTableOrderingComposer get userId {
    final $$UserProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.userProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.userProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContraindicationTagsTableOrderingComposer get contraindicationTagId {
    final $$ContraindicationTagsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contraindicationTagId,
          referencedTable: $db.contraindicationTags,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContraindicationTagsTableOrderingComposer(
                $db: $db,
                $table: $db.contraindicationTags,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$UserContraindicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserContraindicationsTable> {
  $$UserContraindicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$UserProfilesTableAnnotationComposer get userId {
    final $$UserProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.userProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.userProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContraindicationTagsTableAnnotationComposer get contraindicationTagId {
    final $$ContraindicationTagsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contraindicationTagId,
          referencedTable: $db.contraindicationTags,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContraindicationTagsTableAnnotationComposer(
                $db: $db,
                $table: $db.contraindicationTags,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$UserContraindicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserContraindicationsTable,
          UserContraindicationRow,
          $$UserContraindicationsTableFilterComposer,
          $$UserContraindicationsTableOrderingComposer,
          $$UserContraindicationsTableAnnotationComposer,
          $$UserContraindicationsTableCreateCompanionBuilder,
          $$UserContraindicationsTableUpdateCompanionBuilder,
          (UserContraindicationRow, $$UserContraindicationsTableReferences),
          UserContraindicationRow,
          PrefetchHooks Function({bool userId, bool contraindicationTagId})
        > {
  $$UserContraindicationsTableTableManager(
    _$AppDatabase db,
    $UserContraindicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserContraindicationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserContraindicationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserContraindicationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<int> contraindicationTagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserContraindicationsCompanion(
                userId: userId,
                contraindicationTagId: contraindicationTagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int userId,
                required int contraindicationTagId,
                Value<int> rowid = const Value.absent(),
              }) => UserContraindicationsCompanion.insert(
                userId: userId,
                contraindicationTagId: contraindicationTagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserContraindicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, contraindicationTagId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$UserContraindicationsTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$UserContraindicationsTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (contraindicationTagId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contraindicationTagId,
                                    referencedTable:
                                        $$UserContraindicationsTableReferences
                                            ._contraindicationTagIdTable(db),
                                    referencedColumn:
                                        $$UserContraindicationsTableReferences
                                            ._contraindicationTagIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$UserContraindicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserContraindicationsTable,
      UserContraindicationRow,
      $$UserContraindicationsTableFilterComposer,
      $$UserContraindicationsTableOrderingComposer,
      $$UserContraindicationsTableAnnotationComposer,
      $$UserContraindicationsTableCreateCompanionBuilder,
      $$UserContraindicationsTableUpdateCompanionBuilder,
      (UserContraindicationRow, $$UserContraindicationsTableReferences),
      UserContraindicationRow,
      PrefetchHooks Function({bool userId, bool contraindicationTagId})
    >;
typedef $$ProgramsTableCreateCompanionBuilder =
    ProgramsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> description,
      Value<int> daysCount,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isActive,
      Value<DateTime?> activatedAt,
      Value<DateTime?> deactivatedAt,
      Value<int?> exerciseRestSeconds,
    });
typedef $$ProgramsTableUpdateCompanionBuilder =
    ProgramsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> description,
      Value<int> daysCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isActive,
      Value<DateTime?> activatedAt,
      Value<DateTime?> deactivatedAt,
      Value<int?> exerciseRestSeconds,
    });

final class $$ProgramsTableReferences
    extends BaseReferences<_$AppDatabase, $ProgramsTable, ProgramRow> {
  $$ProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProgramDaysTable, List<ProgramDayRow>>
  _programDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.programDays,
    aliasName: 'programs__id__program_days__program_id',
  );

  $$ProgramDaysTableProcessedTableManager get programDaysRefs {
    final manager = $$ProgramDaysTableTableManager(
      $_db,
      $_db.programDays,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_programDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutSessionsTable, List<WorkoutSessionRow>>
  _workoutSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSessions,
    aliasName: 'programs__id__workout_sessions__program_id',
  );

  $$WorkoutSessionsTableProcessedTableManager get workoutSessionsRefs {
    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ProgramWarningDismissalsTable,
    List<ProgramWarningDismissalRow>
  >
  _programWarningDismissalsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.programWarningDismissals,
        aliasName: 'programs__id__program_warning_dismissals__program_id',
      );

  $$ProgramWarningDismissalsTableProcessedTableManager
  get programWarningDismissalsRefs {
    final manager = $$ProgramWarningDismissalsTableTableManager(
      $_db,
      $_db.programWarningDismissals,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _programWarningDismissalsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysCount => $composableBuilder(
    column: $table.daysCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get activatedAt =>
      $composableBuilder(
        column: $table.activatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deactivatedAt =>
      $composableBuilder(
        column: $table.deactivatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get exerciseRestSeconds => $composableBuilder(
    column: $table.exerciseRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> programDaysRefs(
    Expression<bool> Function($$ProgramDaysTableFilterComposer f) f,
  ) {
    final $$ProgramDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableFilterComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutSessionsRefs(
    Expression<bool> Function($$WorkoutSessionsTableFilterComposer f) f,
  ) {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> programWarningDismissalsRefs(
    Expression<bool> Function($$ProgramWarningDismissalsTableFilterComposer f)
    f,
  ) {
    final $$ProgramWarningDismissalsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.programWarningDismissals,
          getReferencedColumn: (t) => t.programId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProgramWarningDismissalsTableFilterComposer(
                $db: $db,
                $table: $db.programWarningDismissals,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysCount => $composableBuilder(
    column: $table.daysCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseRestSeconds => $composableBuilder(
    column: $table.exerciseRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get daysCount =>
      $composableBuilder(column: $table.daysCount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get activatedAt =>
      $composableBuilder(
        column: $table.activatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get deactivatedAt =>
      $composableBuilder(
        column: $table.deactivatedAt,
        builder: (column) => column,
      );

  GeneratedColumn<int> get exerciseRestSeconds => $composableBuilder(
    column: $table.exerciseRestSeconds,
    builder: (column) => column,
  );

  Expression<T> programDaysRefs<T extends Object>(
    Expression<T> Function($$ProgramDaysTableAnnotationComposer a) f,
  ) {
    final $$ProgramDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutSessionsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSessionsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> programWarningDismissalsRefs<T extends Object>(
    Expression<T> Function($$ProgramWarningDismissalsTableAnnotationComposer a)
    f,
  ) {
    final $$ProgramWarningDismissalsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.programWarningDismissals,
          getReferencedColumn: (t) => t.programId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProgramWarningDismissalsTableAnnotationComposer(
                $db: $db,
                $table: $db.programWarningDismissals,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          ProgramRow,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (ProgramRow, $$ProgramsTableReferences),
          ProgramRow,
          PrefetchHooks Function({
            bool programDaysRefs,
            bool workoutSessionsRefs,
            bool programWarningDismissalsRefs,
          })
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> daysCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> activatedAt = const Value.absent(),
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<int?> exerciseRestSeconds = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                name: name,
                description: description,
                daysCount: daysCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isActive: isActive,
                activatedAt: activatedAt,
                deactivatedAt: deactivatedAt,
                exerciseRestSeconds: exerciseRestSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> description = const Value.absent(),
                Value<int> daysCount = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> activatedAt = const Value.absent(),
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<int?> exerciseRestSeconds = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                name: name,
                description: description,
                daysCount: daysCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isActive: isActive,
                activatedAt: activatedAt,
                deactivatedAt: deactivatedAt,
                exerciseRestSeconds: exerciseRestSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                programDaysRefs = false,
                workoutSessionsRefs = false,
                programWarningDismissalsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (programDaysRefs) db.programDays,
                    if (workoutSessionsRefs) db.workoutSessions,
                    if (programWarningDismissalsRefs)
                      db.programWarningDismissals,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (programDaysRefs)
                        await $_getPrefetchedData<
                          ProgramRow,
                          $ProgramsTable,
                          ProgramDayRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramsTableReferences
                              ._programDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramsTableReferences(
                                db,
                                table,
                                p0,
                              ).programDaysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutSessionsRefs)
                        await $_getPrefetchedData<
                          ProgramRow,
                          $ProgramsTable,
                          WorkoutSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramsTableReferences
                              ._workoutSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramsTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (programWarningDismissalsRefs)
                        await $_getPrefetchedData<
                          ProgramRow,
                          $ProgramsTable,
                          ProgramWarningDismissalRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramsTableReferences
                              ._programWarningDismissalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramsTableReferences(
                                db,
                                table,
                                p0,
                              ).programWarningDismissalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      ProgramRow,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (ProgramRow, $$ProgramsTableReferences),
      ProgramRow,
      PrefetchHooks Function({
        bool programDaysRefs,
        bool workoutSessionsRefs,
        bool programWarningDismissalsRefs,
      })
    >;
typedef $$ProgramDaysTableCreateCompanionBuilder =
    ProgramDaysCompanion Function({
      Value<int> id,
      required int programId,
      required int dayIndex,
      Value<int?> dayOfWeek,
      Value<int?> warmupMinutes,
    });
typedef $$ProgramDaysTableUpdateCompanionBuilder =
    ProgramDaysCompanion Function({
      Value<int> id,
      Value<int> programId,
      Value<int> dayIndex,
      Value<int?> dayOfWeek,
      Value<int?> warmupMinutes,
    });

final class $$ProgramDaysTableReferences
    extends BaseReferences<_$AppDatabase, $ProgramDaysTable, ProgramDayRow> {
  $$ProgramDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProgramsTable _programIdTable(_$AppDatabase db) =>
      db.programs.createAlias('program_days__program_id__programs__id');

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<int>('program_id')!;

    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ProgramDayExercisesTable,
    List<ProgramDayExerciseRow>
  >
  _programDayExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.programDayExercises,
        aliasName: 'program_days__id__program_day_exercises__day_id',
      );

  $$ProgramDayExercisesTableProcessedTableManager get programDayExercisesRefs {
    final manager = $$ProgramDayExercisesTableTableManager(
      $_db,
      $_db.programDayExercises,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _programDayExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutRemindersTable, List<WorkoutReminderRow>>
  _workoutRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutReminders,
    aliasName: 'program_days__id__workout_reminders__program_day_id',
  );

  $$WorkoutRemindersTableProcessedTableManager get workoutRemindersRefs {
    final manager = $$WorkoutRemindersTableTableManager(
      $_db,
      $_db.workoutReminders,
    ).filter((f) => f.programDayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutRemindersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutSessionsTable, List<WorkoutSessionRow>>
  _workoutSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSessions,
    aliasName: 'program_days__id__workout_sessions__program_day_id',
  );

  $$WorkoutSessionsTableProcessedTableManager get workoutSessionsRefs {
    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.programDayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScheduleMarksTable, List<ScheduleMarkRow>>
  _scheduleMarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scheduleMarks,
    aliasName: 'program_days__id__schedule_marks__program_day_id',
  );

  $$ScheduleMarksTableProcessedTableManager get scheduleMarksRefs {
    final manager = $$ScheduleMarksTableTableManager(
      $_db,
      $_db.scheduleMarks,
    ).filter((f) => f.programDayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scheduleMarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlanScheduleTable, List<PlanScheduleData>>
  _planScheduleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planSchedule,
    aliasName: 'program_days__id__plan_schedule__program_day_id',
  );

  $$PlanScheduleTableProcessedTableManager get planScheduleRefs {
    final manager = $$PlanScheduleTableTableManager(
      $_db,
      $_db.planSchedule,
    ).filter((f) => f.programDayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planScheduleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProgramDaysTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramDaysTable> {
  $$ProgramDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warmupMinutes => $composableBuilder(
    column: $table.warmupMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> programDayExercisesRefs(
    Expression<bool> Function($$ProgramDayExercisesTableFilterComposer f) f,
  ) {
    final $$ProgramDayExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programDayExercises,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDayExercisesTableFilterComposer(
            $db: $db,
            $table: $db.programDayExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutRemindersRefs(
    Expression<bool> Function($$WorkoutRemindersTableFilterComposer f) f,
  ) {
    final $$WorkoutRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutReminders,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutRemindersTableFilterComposer(
            $db: $db,
            $table: $db.workoutReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutSessionsRefs(
    Expression<bool> Function($$WorkoutSessionsTableFilterComposer f) f,
  ) {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scheduleMarksRefs(
    Expression<bool> Function($$ScheduleMarksTableFilterComposer f) f,
  ) {
    final $$ScheduleMarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleMarks,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleMarksTableFilterComposer(
            $db: $db,
            $table: $db.scheduleMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> planScheduleRefs(
    Expression<bool> Function($$PlanScheduleTableFilterComposer f) f,
  ) {
    final $$PlanScheduleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planSchedule,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanScheduleTableFilterComposer(
            $db: $db,
            $table: $db.planSchedule,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramDaysTable> {
  $$ProgramDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warmupMinutes => $composableBuilder(
    column: $table.warmupMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramDaysTable> {
  $$ProgramDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayIndex =>
      $composableBuilder(column: $table.dayIndex, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get warmupMinutes => $composableBuilder(
    column: $table.warmupMinutes,
    builder: (column) => column,
  );

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> programDayExercisesRefs<T extends Object>(
    Expression<T> Function($$ProgramDayExercisesTableAnnotationComposer a) f,
  ) {
    final $$ProgramDayExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.programDayExercises,
          getReferencedColumn: (t) => t.dayId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProgramDayExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.programDayExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> workoutRemindersRefs<T extends Object>(
    Expression<T> Function($$WorkoutRemindersTableAnnotationComposer a) f,
  ) {
    final $$WorkoutRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutReminders,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutSessionsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSessionsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scheduleMarksRefs<T extends Object>(
    Expression<T> Function($$ScheduleMarksTableAnnotationComposer a) f,
  ) {
    final $$ScheduleMarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleMarks,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleMarksTableAnnotationComposer(
            $db: $db,
            $table: $db.scheduleMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> planScheduleRefs<T extends Object>(
    Expression<T> Function($$PlanScheduleTableAnnotationComposer a) f,
  ) {
    final $$PlanScheduleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planSchedule,
      getReferencedColumn: (t) => t.programDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanScheduleTableAnnotationComposer(
            $db: $db,
            $table: $db.planSchedule,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramDaysTable,
          ProgramDayRow,
          $$ProgramDaysTableFilterComposer,
          $$ProgramDaysTableOrderingComposer,
          $$ProgramDaysTableAnnotationComposer,
          $$ProgramDaysTableCreateCompanionBuilder,
          $$ProgramDaysTableUpdateCompanionBuilder,
          (ProgramDayRow, $$ProgramDaysTableReferences),
          ProgramDayRow,
          PrefetchHooks Function({
            bool programId,
            bool programDayExercisesRefs,
            bool workoutRemindersRefs,
            bool workoutSessionsRefs,
            bool scheduleMarksRefs,
            bool planScheduleRefs,
          })
        > {
  $$ProgramDaysTableTableManager(_$AppDatabase db, $ProgramDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> programId = const Value.absent(),
                Value<int> dayIndex = const Value.absent(),
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> warmupMinutes = const Value.absent(),
              }) => ProgramDaysCompanion(
                id: id,
                programId: programId,
                dayIndex: dayIndex,
                dayOfWeek: dayOfWeek,
                warmupMinutes: warmupMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int programId,
                required int dayIndex,
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> warmupMinutes = const Value.absent(),
              }) => ProgramDaysCompanion.insert(
                id: id,
                programId: programId,
                dayIndex: dayIndex,
                dayOfWeek: dayOfWeek,
                warmupMinutes: warmupMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                programId = false,
                programDayExercisesRefs = false,
                workoutRemindersRefs = false,
                workoutSessionsRefs = false,
                scheduleMarksRefs = false,
                planScheduleRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (programDayExercisesRefs) db.programDayExercises,
                    if (workoutRemindersRefs) db.workoutReminders,
                    if (workoutSessionsRefs) db.workoutSessions,
                    if (scheduleMarksRefs) db.scheduleMarks,
                    if (planScheduleRefs) db.planSchedule,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (programId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.programId,
                                    referencedTable:
                                        $$ProgramDaysTableReferences
                                            ._programIdTable(db),
                                    referencedColumn:
                                        $$ProgramDaysTableReferences
                                            ._programIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (programDayExercisesRefs)
                        await $_getPrefetchedData<
                          ProgramDayRow,
                          $ProgramDaysTable,
                          ProgramDayExerciseRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramDaysTableReferences
                              ._programDayExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).programDayExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutRemindersRefs)
                        await $_getPrefetchedData<
                          ProgramDayRow,
                          $ProgramDaysTable,
                          WorkoutReminderRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramDaysTableReferences
                              ._workoutRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutSessionsRefs)
                        await $_getPrefetchedData<
                          ProgramDayRow,
                          $ProgramDaysTable,
                          WorkoutSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramDaysTableReferences
                              ._workoutSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scheduleMarksRefs)
                        await $_getPrefetchedData<
                          ProgramDayRow,
                          $ProgramDaysTable,
                          ScheduleMarkRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramDaysTableReferences
                              ._scheduleMarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleMarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (planScheduleRefs)
                        await $_getPrefetchedData<
                          ProgramDayRow,
                          $ProgramDaysTable,
                          PlanScheduleData
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramDaysTableReferences
                              ._planScheduleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).planScheduleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProgramDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramDaysTable,
      ProgramDayRow,
      $$ProgramDaysTableFilterComposer,
      $$ProgramDaysTableOrderingComposer,
      $$ProgramDaysTableAnnotationComposer,
      $$ProgramDaysTableCreateCompanionBuilder,
      $$ProgramDaysTableUpdateCompanionBuilder,
      (ProgramDayRow, $$ProgramDaysTableReferences),
      ProgramDayRow,
      PrefetchHooks Function({
        bool programId,
        bool programDayExercisesRefs,
        bool workoutRemindersRefs,
        bool workoutSessionsRefs,
        bool scheduleMarksRefs,
        bool planScheduleRefs,
      })
    >;
typedef $$ProgramDayExercisesTableCreateCompanionBuilder =
    ProgramDayExercisesCompanion Function({
      Value<int> id,
      required int dayId,
      Value<int?> exerciseId,
      required int orderIndex,
      Value<int?> sets,
      Value<int?> reps,
      Value<int?> durationSeconds,
      Value<double?> weightKg,
      Value<double?> distanceMeters,
      Value<int?> restSeconds,
      Value<bool> isAlternative,
    });
typedef $$ProgramDayExercisesTableUpdateCompanionBuilder =
    ProgramDayExercisesCompanion Function({
      Value<int> id,
      Value<int> dayId,
      Value<int?> exerciseId,
      Value<int> orderIndex,
      Value<int?> sets,
      Value<int?> reps,
      Value<int?> durationSeconds,
      Value<double?> weightKg,
      Value<double?> distanceMeters,
      Value<int?> restSeconds,
      Value<bool> isAlternative,
    });

final class $$ProgramDayExercisesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProgramDayExercisesTable,
          ProgramDayExerciseRow
        > {
  $$ProgramDayExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProgramDaysTable _dayIdTable(_$AppDatabase db) => db.programDays
      .createAlias('program_day_exercises__day_id__program_days__id');

  $$ProgramDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$ProgramDaysTableTableManager(
      $_db,
      $_db.programDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) => db.exercises
      .createAlias('program_day_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager? get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgramDayExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramDayExercisesTable> {
  $$ProgramDayExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sets => $composableBuilder(
    column: $table.sets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlternative => $composableBuilder(
    column: $table.isAlternative,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramDaysTableFilterComposer get dayId {
    final $$ProgramDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableFilterComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramDayExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramDayExercisesTable> {
  $$ProgramDayExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sets => $composableBuilder(
    column: $table.sets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlternative => $composableBuilder(
    column: $table.isAlternative,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramDaysTableOrderingComposer get dayId {
    final $$ProgramDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableOrderingComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramDayExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramDayExercisesTable> {
  $$ProgramDayExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sets =>
      $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAlternative => $composableBuilder(
    column: $table.isAlternative,
    builder: (column) => column,
  );

  $$ProgramDaysTableAnnotationComposer get dayId {
    final $$ProgramDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramDayExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramDayExercisesTable,
          ProgramDayExerciseRow,
          $$ProgramDayExercisesTableFilterComposer,
          $$ProgramDayExercisesTableOrderingComposer,
          $$ProgramDayExercisesTableAnnotationComposer,
          $$ProgramDayExercisesTableCreateCompanionBuilder,
          $$ProgramDayExercisesTableUpdateCompanionBuilder,
          (ProgramDayExerciseRow, $$ProgramDayExercisesTableReferences),
          ProgramDayExerciseRow,
          PrefetchHooks Function({bool dayId, bool exerciseId})
        > {
  $$ProgramDayExercisesTableTableManager(
    _$AppDatabase db,
    $ProgramDayExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramDayExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramDayExercisesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProgramDayExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayId = const Value.absent(),
                Value<int?> exerciseId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int?> sets = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> isAlternative = const Value.absent(),
              }) => ProgramDayExercisesCompanion(
                id: id,
                dayId: dayId,
                exerciseId: exerciseId,
                orderIndex: orderIndex,
                sets: sets,
                reps: reps,
                durationSeconds: durationSeconds,
                weightKg: weightKg,
                distanceMeters: distanceMeters,
                restSeconds: restSeconds,
                isAlternative: isAlternative,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayId,
                Value<int?> exerciseId = const Value.absent(),
                required int orderIndex,
                Value<int?> sets = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> isAlternative = const Value.absent(),
              }) => ProgramDayExercisesCompanion.insert(
                id: id,
                dayId: dayId,
                exerciseId: exerciseId,
                orderIndex: orderIndex,
                sets: sets,
                reps: reps,
                durationSeconds: durationSeconds,
                weightKg: weightKg,
                distanceMeters: distanceMeters,
                restSeconds: restSeconds,
                isAlternative: isAlternative,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramDayExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dayId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayId,
                                referencedTable:
                                    $$ProgramDayExercisesTableReferences
                                        ._dayIdTable(db),
                                referencedColumn:
                                    $$ProgramDayExercisesTableReferences
                                        ._dayIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$ProgramDayExercisesTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$ProgramDayExercisesTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgramDayExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramDayExercisesTable,
      ProgramDayExerciseRow,
      $$ProgramDayExercisesTableFilterComposer,
      $$ProgramDayExercisesTableOrderingComposer,
      $$ProgramDayExercisesTableAnnotationComposer,
      $$ProgramDayExercisesTableCreateCompanionBuilder,
      $$ProgramDayExercisesTableUpdateCompanionBuilder,
      (ProgramDayExerciseRow, $$ProgramDayExercisesTableReferences),
      ProgramDayExerciseRow,
      PrefetchHooks Function({bool dayId, bool exerciseId})
    >;
typedef $$WorkoutRemindersTableCreateCompanionBuilder =
    WorkoutRemindersCompanion Function({
      Value<int> id,
      required int programDayId,
      required int hour,
      required int minute,
      Value<bool> enabled,
    });
typedef $$WorkoutRemindersTableUpdateCompanionBuilder =
    WorkoutRemindersCompanion Function({
      Value<int> id,
      Value<int> programDayId,
      Value<int> hour,
      Value<int> minute,
      Value<bool> enabled,
    });

final class $$WorkoutRemindersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WorkoutRemindersTable,
          WorkoutReminderRow
        > {
  $$WorkoutRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProgramDaysTable _programDayIdTable(_$AppDatabase db) => db
      .programDays
      .createAlias('workout_reminders__program_day_id__program_days__id');

  $$ProgramDaysTableProcessedTableManager get programDayId {
    final $_column = $_itemColumn<int>('program_day_id')!;

    final manager = $$ProgramDaysTableTableManager(
      $_db,
      $_db.programDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutRemindersTable> {
  $$WorkoutRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramDaysTableFilterComposer get programDayId {
    final $$ProgramDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableFilterComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutRemindersTable> {
  $$WorkoutRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramDaysTableOrderingComposer get programDayId {
    final $$ProgramDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableOrderingComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutRemindersTable> {
  $$WorkoutRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  $$ProgramDaysTableAnnotationComposer get programDayId {
    final $$ProgramDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutRemindersTable,
          WorkoutReminderRow,
          $$WorkoutRemindersTableFilterComposer,
          $$WorkoutRemindersTableOrderingComposer,
          $$WorkoutRemindersTableAnnotationComposer,
          $$WorkoutRemindersTableCreateCompanionBuilder,
          $$WorkoutRemindersTableUpdateCompanionBuilder,
          (WorkoutReminderRow, $$WorkoutRemindersTableReferences),
          WorkoutReminderRow,
          PrefetchHooks Function({bool programDayId})
        > {
  $$WorkoutRemindersTableTableManager(
    _$AppDatabase db,
    $WorkoutRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> programDayId = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => WorkoutRemindersCompanion(
                id: id,
                programDayId: programDayId,
                hour: hour,
                minute: minute,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int programDayId,
                required int hour,
                required int minute,
                Value<bool> enabled = const Value.absent(),
              }) => WorkoutRemindersCompanion.insert(
                id: id,
                programDayId: programDayId,
                hour: hour,
                minute: minute,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programDayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programDayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programDayId,
                                referencedTable:
                                    $$WorkoutRemindersTableReferences
                                        ._programDayIdTable(db),
                                referencedColumn:
                                    $$WorkoutRemindersTableReferences
                                        ._programDayIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutRemindersTable,
      WorkoutReminderRow,
      $$WorkoutRemindersTableFilterComposer,
      $$WorkoutRemindersTableOrderingComposer,
      $$WorkoutRemindersTableAnnotationComposer,
      $$WorkoutRemindersTableCreateCompanionBuilder,
      $$WorkoutRemindersTableUpdateCompanionBuilder,
      (WorkoutReminderRow, $$WorkoutRemindersTableReferences),
      WorkoutReminderRow,
      PrefetchHooks Function({bool programDayId})
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<int?> programId,
      required String programName,
      Value<int?> programDayId,
      required int dayIndex,
      required WorkoutVariant variant,
      required DateTime performedDate,
      required DateTime startedAt,
      required DateTime endedAt,
      Value<String> status,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<int?> programId,
      Value<String> programName,
      Value<int?> programDayId,
      Value<int> dayIndex,
      Value<WorkoutVariant> variant,
      Value<DateTime> performedDate,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<String> status,
    });

final class $$WorkoutSessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSessionRow
        > {
  $$WorkoutSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProgramsTable _programIdTable(_$AppDatabase db) =>
      db.programs.createAlias('workout_sessions__program_id__programs__id');

  $$ProgramsTableProcessedTableManager? get programId {
    final $_column = $_itemColumn<int>('program_id');
    if ($_column == null) return null;
    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProgramDaysTable _programDayIdTable(_$AppDatabase db) => db
      .programDays
      .createAlias('workout_sessions__program_day_id__program_days__id');

  $$ProgramDaysTableProcessedTableManager? get programDayId {
    final $_column = $_itemColumn<int>('program_day_id');
    if ($_column == null) return null;
    final manager = $$ProgramDaysTableTableManager(
      $_db,
      $_db.programDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutSetResultsTable, List<WorkoutSetResultRow>>
  _workoutSetResultsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workoutSetResults,
        aliasName: 'workout_sessions__id__workout_set_results__session_id',
      );

  $$WorkoutSetResultsTableProcessedTableManager get workoutSetResultsRefs {
    final manager = $$WorkoutSetResultsTableTableManager(
      $_db,
      $_db.workoutSetResults,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutSetResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programName => $composableBuilder(
    column: $table.programName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WorkoutVariant, WorkoutVariant, String>
  get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get performedDate =>
      $composableBuilder(
        column: $table.performedDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get endedAt =>
      $composableBuilder(
        column: $table.endedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProgramDaysTableFilterComposer get programDayId {
    final $$ProgramDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableFilterComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutSetResultsRefs(
    Expression<bool> Function($$WorkoutSetResultsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSetResults,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetResultsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSetResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programName => $composableBuilder(
    column: $table.programName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get performedDate => $composableBuilder(
    column: $table.performedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProgramDaysTableOrderingComposer get programDayId {
    final $$ProgramDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableOrderingComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programName => $composableBuilder(
    column: $table.programName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayIndex =>
      $composableBuilder(column: $table.dayIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkoutVariant, String> get variant =>
      $composableBuilder(column: $table.variant, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get performedDate =>
      $composableBuilder(
        column: $table.performedDate,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProgramDaysTableAnnotationComposer get programDayId {
    final $$ProgramDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutSetResultsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetResultsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetResultsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workoutSetResults,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkoutSetResultsTableAnnotationComposer(
                $db: $db,
                $table: $db.workoutSetResults,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSessionRow,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (WorkoutSessionRow, $$WorkoutSessionsTableReferences),
          WorkoutSessionRow,
          PrefetchHooks Function({
            bool programId,
            bool programDayId,
            bool workoutSetResultsRefs,
          })
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> programId = const Value.absent(),
                Value<String> programName = const Value.absent(),
                Value<int?> programDayId = const Value.absent(),
                Value<int> dayIndex = const Value.absent(),
                Value<WorkoutVariant> variant = const Value.absent(),
                Value<DateTime> performedDate = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                programId: programId,
                programName: programName,
                programDayId: programDayId,
                dayIndex: dayIndex,
                variant: variant,
                performedDate: performedDate,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> programId = const Value.absent(),
                required String programName,
                Value<int?> programDayId = const Value.absent(),
                required int dayIndex,
                required WorkoutVariant variant,
                required DateTime performedDate,
                required DateTime startedAt,
                required DateTime endedAt,
                Value<String> status = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                programId: programId,
                programName: programName,
                programDayId: programDayId,
                dayIndex: dayIndex,
                variant: variant,
                performedDate: performedDate,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                programId = false,
                programDayId = false,
                workoutSetResultsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutSetResultsRefs) db.workoutSetResults,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (programId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.programId,
                                    referencedTable:
                                        $$WorkoutSessionsTableReferences
                                            ._programIdTable(db),
                                    referencedColumn:
                                        $$WorkoutSessionsTableReferences
                                            ._programIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (programDayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.programDayId,
                                    referencedTable:
                                        $$WorkoutSessionsTableReferences
                                            ._programDayIdTable(db),
                                    referencedColumn:
                                        $$WorkoutSessionsTableReferences
                                            ._programDayIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutSetResultsRefs)
                        await $_getPrefetchedData<
                          WorkoutSessionRow,
                          $WorkoutSessionsTable,
                          WorkoutSetResultRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutSessionsTableReferences
                              ._workoutSetResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSessionRow,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (WorkoutSessionRow, $$WorkoutSessionsTableReferences),
      WorkoutSessionRow,
      PrefetchHooks Function({
        bool programId,
        bool programDayId,
        bool workoutSetResultsRefs,
      })
    >;
typedef $$WorkoutSetResultsTableCreateCompanionBuilder =
    WorkoutSetResultsCompanion Function({
      Value<int> id,
      required int sessionId,
      Value<int?> exerciseId,
      required String exerciseName,
      required ExerciseType exerciseType,
      required int setIndex,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<int?> durationSeconds,
      Value<double?> distanceMeters,
      Value<String?> side,
      required DateTime completedAt,
    });
typedef $$WorkoutSetResultsTableUpdateCompanionBuilder =
    WorkoutSetResultsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int?> exerciseId,
      Value<String> exerciseName,
      Value<ExerciseType> exerciseType,
      Value<int> setIndex,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<int?> durationSeconds,
      Value<double?> distanceMeters,
      Value<String?> side,
      Value<DateTime> completedAt,
    });

final class $$WorkoutSetResultsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WorkoutSetResultsTable,
          WorkoutSetResultRow
        > {
  $$WorkoutSetResultsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .workoutSessions
      .createAlias('workout_set_results__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) => db.exercises
      .createAlias('workout_set_results__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager? get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutSetResultsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetResultsTable> {
  $$WorkoutSetResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExerciseType, ExerciseType, String>
  get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetResultsTable> {
  $$WorkoutSetResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetResultsTable> {
  $$WorkoutSetResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExerciseType, String> get exerciseType =>
      $composableBuilder(
        column: $table.exerciseType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => column,
      );

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetResultsTable,
          WorkoutSetResultRow,
          $$WorkoutSetResultsTableFilterComposer,
          $$WorkoutSetResultsTableOrderingComposer,
          $$WorkoutSetResultsTableAnnotationComposer,
          $$WorkoutSetResultsTableCreateCompanionBuilder,
          $$WorkoutSetResultsTableUpdateCompanionBuilder,
          (WorkoutSetResultRow, $$WorkoutSetResultsTableReferences),
          WorkoutSetResultRow,
          PrefetchHooks Function({bool sessionId, bool exerciseId})
        > {
  $$WorkoutSetResultsTableTableManager(
    _$AppDatabase db,
    $WorkoutSetResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int?> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<ExerciseType> exerciseType = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<String?> side = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => WorkoutSetResultsCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                exerciseType: exerciseType,
                setIndex: setIndex,
                reps: reps,
                weightKg: weightKg,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                side: side,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                Value<int?> exerciseId = const Value.absent(),
                required String exerciseName,
                required ExerciseType exerciseType,
                required int setIndex,
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<double?> distanceMeters = const Value.absent(),
                Value<String?> side = const Value.absent(),
                required DateTime completedAt,
              }) => WorkoutSetResultsCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                exerciseType: exerciseType,
                setIndex: setIndex,
                reps: reps,
                weightKg: weightKg,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                side: side,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSetResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$WorkoutSetResultsTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$WorkoutSetResultsTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$WorkoutSetResultsTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$WorkoutSetResultsTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSetResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetResultsTable,
      WorkoutSetResultRow,
      $$WorkoutSetResultsTableFilterComposer,
      $$WorkoutSetResultsTableOrderingComposer,
      $$WorkoutSetResultsTableAnnotationComposer,
      $$WorkoutSetResultsTableCreateCompanionBuilder,
      $$WorkoutSetResultsTableUpdateCompanionBuilder,
      (WorkoutSetResultRow, $$WorkoutSetResultsTableReferences),
      WorkoutSetResultRow,
      PrefetchHooks Function({bool sessionId, bool exerciseId})
    >;
typedef $$ScheduleMarksTableCreateCompanionBuilder =
    ScheduleMarksCompanion Function({
      Value<int> id,
      required int programDayId,
      required DateTime weekStart,
      required ScheduleMarkStatus status,
    });
typedef $$ScheduleMarksTableUpdateCompanionBuilder =
    ScheduleMarksCompanion Function({
      Value<int> id,
      Value<int> programDayId,
      Value<DateTime> weekStart,
      Value<ScheduleMarkStatus> status,
    });

final class $$ScheduleMarksTableReferences
    extends
        BaseReferences<_$AppDatabase, $ScheduleMarksTable, ScheduleMarkRow> {
  $$ScheduleMarksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProgramDaysTable _programDayIdTable(_$AppDatabase db) => db
      .programDays
      .createAlias('schedule_marks__program_day_id__program_days__id');

  $$ProgramDaysTableProcessedTableManager get programDayId {
    final $_column = $_itemColumn<int>('program_day_id')!;

    final manager = $$ProgramDaysTableTableManager(
      $_db,
      $_db.programDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScheduleMarksTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleMarksTable> {
  $$ScheduleMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get weekStart =>
      $composableBuilder(
        column: $table.weekStart,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ScheduleMarkStatus, ScheduleMarkStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ProgramDaysTableFilterComposer get programDayId {
    final $$ProgramDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableFilterComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleMarksTable> {
  $$ScheduleMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramDaysTableOrderingComposer get programDayId {
    final $$ProgramDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableOrderingComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleMarksTable> {
  $$ScheduleMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScheduleMarkStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$ProgramDaysTableAnnotationComposer get programDayId {
    final $$ProgramDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleMarksTable,
          ScheduleMarkRow,
          $$ScheduleMarksTableFilterComposer,
          $$ScheduleMarksTableOrderingComposer,
          $$ScheduleMarksTableAnnotationComposer,
          $$ScheduleMarksTableCreateCompanionBuilder,
          $$ScheduleMarksTableUpdateCompanionBuilder,
          (ScheduleMarkRow, $$ScheduleMarksTableReferences),
          ScheduleMarkRow,
          PrefetchHooks Function({bool programDayId})
        > {
  $$ScheduleMarksTableTableManager(_$AppDatabase db, $ScheduleMarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> programDayId = const Value.absent(),
                Value<DateTime> weekStart = const Value.absent(),
                Value<ScheduleMarkStatus> status = const Value.absent(),
              }) => ScheduleMarksCompanion(
                id: id,
                programDayId: programDayId,
                weekStart: weekStart,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int programDayId,
                required DateTime weekStart,
                required ScheduleMarkStatus status,
              }) => ScheduleMarksCompanion.insert(
                id: id,
                programDayId: programDayId,
                weekStart: weekStart,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScheduleMarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programDayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programDayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programDayId,
                                referencedTable: $$ScheduleMarksTableReferences
                                    ._programDayIdTable(db),
                                referencedColumn: $$ScheduleMarksTableReferences
                                    ._programDayIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScheduleMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleMarksTable,
      ScheduleMarkRow,
      $$ScheduleMarksTableFilterComposer,
      $$ScheduleMarksTableOrderingComposer,
      $$ScheduleMarksTableAnnotationComposer,
      $$ScheduleMarksTableCreateCompanionBuilder,
      $$ScheduleMarksTableUpdateCompanionBuilder,
      (ScheduleMarkRow, $$ScheduleMarksTableReferences),
      ScheduleMarkRow,
      PrefetchHooks Function({bool programDayId})
    >;
typedef $$BodyMeasurementsTableCreateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<double?> neckCm,
      Value<double?> chestCm,
      Value<double?> waistCm,
      Value<double?> hipsCm,
      Value<double?> bicepsCm,
      Value<double?> forearmCm,
      Value<double?> thighCm,
      Value<double?> calfCm,
    });
typedef $$BodyMeasurementsTableUpdateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<double?> neckCm,
      Value<double?> chestCm,
      Value<double?> waistCm,
      Value<double?> hipsCm,
      Value<double?> bicepsCm,
      Value<double?> forearmCm,
      Value<double?> thighCm,
      Value<double?> calfCm,
    });

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bicepsCm => $composableBuilder(
    column: $table.bicepsCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get forearmCm => $composableBuilder(
    column: $table.forearmCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calfCm => $composableBuilder(
    column: $table.calfCm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bicepsCm => $composableBuilder(
    column: $table.bicepsCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get forearmCm => $composableBuilder(
    column: $table.forearmCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calfCm => $composableBuilder(
    column: $table.calfCm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get neckCm =>
      $composableBuilder(column: $table.neckCm, builder: (column) => column);

  GeneratedColumn<double> get chestCm =>
      $composableBuilder(column: $table.chestCm, builder: (column) => column);

  GeneratedColumn<double> get waistCm =>
      $composableBuilder(column: $table.waistCm, builder: (column) => column);

  GeneratedColumn<double> get hipsCm =>
      $composableBuilder(column: $table.hipsCm, builder: (column) => column);

  GeneratedColumn<double> get bicepsCm =>
      $composableBuilder(column: $table.bicepsCm, builder: (column) => column);

  GeneratedColumn<double> get forearmCm =>
      $composableBuilder(column: $table.forearmCm, builder: (column) => column);

  GeneratedColumn<double> get thighCm =>
      $composableBuilder(column: $table.thighCm, builder: (column) => column);

  GeneratedColumn<double> get calfCm =>
      $composableBuilder(column: $table.calfCm, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurementRow,
          $$BodyMeasurementsTableFilterComposer,
          $$BodyMeasurementsTableOrderingComposer,
          $$BodyMeasurementsTableAnnotationComposer,
          $$BodyMeasurementsTableCreateCompanionBuilder,
          $$BodyMeasurementsTableUpdateCompanionBuilder,
          (
            BodyMeasurementRow,
            BaseReferences<
              _$AppDatabase,
              $BodyMeasurementsTable,
              BodyMeasurementRow
            >,
          ),
          BodyMeasurementRow,
          PrefetchHooks Function()
        > {
  $$BodyMeasurementsTableTableManager(
    _$AppDatabase db,
    $BodyMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> bicepsCm = const Value.absent(),
                Value<double?> forearmCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> calfCm = const Value.absent(),
              }) => BodyMeasurementsCompanion(
                id: id,
                date: date,
                heightCm: heightCm,
                weightKg: weightKg,
                neckCm: neckCm,
                chestCm: chestCm,
                waistCm: waistCm,
                hipsCm: hipsCm,
                bicepsCm: bicepsCm,
                forearmCm: forearmCm,
                thighCm: thighCm,
                calfCm: calfCm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> bicepsCm = const Value.absent(),
                Value<double?> forearmCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> calfCm = const Value.absent(),
              }) => BodyMeasurementsCompanion.insert(
                id: id,
                date: date,
                heightCm: heightCm,
                weightKg: weightKg,
                neckCm: neckCm,
                chestCm: chestCm,
                waistCm: waistCm,
                hipsCm: hipsCm,
                bicepsCm: bicepsCm,
                forearmCm: forearmCm,
                thighCm: thighCm,
                calfCm: calfCm,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyMeasurementsTable,
      BodyMeasurementRow,
      $$BodyMeasurementsTableFilterComposer,
      $$BodyMeasurementsTableOrderingComposer,
      $$BodyMeasurementsTableAnnotationComposer,
      $$BodyMeasurementsTableCreateCompanionBuilder,
      $$BodyMeasurementsTableUpdateCompanionBuilder,
      (
        BodyMeasurementRow,
        BaseReferences<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurementRow
        >,
      ),
      BodyMeasurementRow,
      PrefetchHooks Function()
    >;
typedef $$ProgramWarningDismissalsTableCreateCompanionBuilder =
    ProgramWarningDismissalsCompanion Function({
      Value<int> id,
      required int programId,
      required DateTime dismissedAt,
    });
typedef $$ProgramWarningDismissalsTableUpdateCompanionBuilder =
    ProgramWarningDismissalsCompanion Function({
      Value<int> id,
      Value<int> programId,
      Value<DateTime> dismissedAt,
    });

final class $$ProgramWarningDismissalsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProgramWarningDismissalsTable,
          ProgramWarningDismissalRow
        > {
  $$ProgramWarningDismissalsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProgramsTable _programIdTable(_$AppDatabase db) => db.programs
      .createAlias('program_warning_dismissals__program_id__programs__id');

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<int>('program_id')!;

    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgramWarningDismissalsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramWarningDismissalsTable> {
  $$ProgramWarningDismissalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get dismissedAt =>
      $composableBuilder(
        column: $table.dismissedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramWarningDismissalsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramWarningDismissalsTable> {
  $$ProgramWarningDismissalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramWarningDismissalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramWarningDismissalsTable> {
  $$ProgramWarningDismissalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get dismissedAt =>
      $composableBuilder(
        column: $table.dismissedAt,
        builder: (column) => column,
      );

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramWarningDismissalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramWarningDismissalsTable,
          ProgramWarningDismissalRow,
          $$ProgramWarningDismissalsTableFilterComposer,
          $$ProgramWarningDismissalsTableOrderingComposer,
          $$ProgramWarningDismissalsTableAnnotationComposer,
          $$ProgramWarningDismissalsTableCreateCompanionBuilder,
          $$ProgramWarningDismissalsTableUpdateCompanionBuilder,
          (
            ProgramWarningDismissalRow,
            $$ProgramWarningDismissalsTableReferences,
          ),
          ProgramWarningDismissalRow,
          PrefetchHooks Function({bool programId})
        > {
  $$ProgramWarningDismissalsTableTableManager(
    _$AppDatabase db,
    $ProgramWarningDismissalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramWarningDismissalsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProgramWarningDismissalsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProgramWarningDismissalsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> programId = const Value.absent(),
                Value<DateTime> dismissedAt = const Value.absent(),
              }) => ProgramWarningDismissalsCompanion(
                id: id,
                programId: programId,
                dismissedAt: dismissedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int programId,
                required DateTime dismissedAt,
              }) => ProgramWarningDismissalsCompanion.insert(
                id: id,
                programId: programId,
                dismissedAt: dismissedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramWarningDismissalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programId,
                                referencedTable:
                                    $$ProgramWarningDismissalsTableReferences
                                        ._programIdTable(db),
                                referencedColumn:
                                    $$ProgramWarningDismissalsTableReferences
                                        ._programIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgramWarningDismissalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramWarningDismissalsTable,
      ProgramWarningDismissalRow,
      $$ProgramWarningDismissalsTableFilterComposer,
      $$ProgramWarningDismissalsTableOrderingComposer,
      $$ProgramWarningDismissalsTableAnnotationComposer,
      $$ProgramWarningDismissalsTableCreateCompanionBuilder,
      $$ProgramWarningDismissalsTableUpdateCompanionBuilder,
      (ProgramWarningDismissalRow, $$ProgramWarningDismissalsTableReferences),
      ProgramWarningDismissalRow,
      PrefetchHooks Function({bool programId})
    >;
typedef $$PlanScheduleTableCreateCompanionBuilder =
    PlanScheduleCompanion Function({
      Value<int> id,
      required int programDayId,
      required DateTime scheduledDate,
    });
typedef $$PlanScheduleTableUpdateCompanionBuilder =
    PlanScheduleCompanion Function({
      Value<int> id,
      Value<int> programDayId,
      Value<DateTime> scheduledDate,
    });

final class $$PlanScheduleTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlanScheduleTable, PlanScheduleData> {
  $$PlanScheduleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProgramDaysTable _programDayIdTable(_$AppDatabase db) => db
      .programDays
      .createAlias('plan_schedule__program_day_id__program_days__id');

  $$ProgramDaysTableProcessedTableManager get programDayId {
    final $_column = $_itemColumn<int>('program_day_id')!;

    final manager = $$ProgramDaysTableTableManager(
      $_db,
      $_db.programDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlanScheduleTableFilterComposer
    extends Composer<_$AppDatabase, $PlanScheduleTable> {
  $$PlanScheduleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramDaysTableFilterComposer get programDayId {
    final $$ProgramDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableFilterComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanScheduleTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanScheduleTable> {
  $$PlanScheduleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramDaysTableOrderingComposer get programDayId {
    final $$ProgramDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableOrderingComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanScheduleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanScheduleTable> {
  $$PlanScheduleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  $$ProgramDaysTableAnnotationComposer get programDayId {
    final $$ProgramDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programDayId,
      referencedTable: $db.programDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.programDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanScheduleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanScheduleTable,
          PlanScheduleData,
          $$PlanScheduleTableFilterComposer,
          $$PlanScheduleTableOrderingComposer,
          $$PlanScheduleTableAnnotationComposer,
          $$PlanScheduleTableCreateCompanionBuilder,
          $$PlanScheduleTableUpdateCompanionBuilder,
          (PlanScheduleData, $$PlanScheduleTableReferences),
          PlanScheduleData,
          PrefetchHooks Function({bool programDayId})
        > {
  $$PlanScheduleTableTableManager(_$AppDatabase db, $PlanScheduleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanScheduleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanScheduleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanScheduleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> programDayId = const Value.absent(),
                Value<DateTime> scheduledDate = const Value.absent(),
              }) => PlanScheduleCompanion(
                id: id,
                programDayId: programDayId,
                scheduledDate: scheduledDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int programDayId,
                required DateTime scheduledDate,
              }) => PlanScheduleCompanion.insert(
                id: id,
                programDayId: programDayId,
                scheduledDate: scheduledDate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlanScheduleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programDayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programDayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programDayId,
                                referencedTable: $$PlanScheduleTableReferences
                                    ._programDayIdTable(db),
                                referencedColumn: $$PlanScheduleTableReferences
                                    ._programDayIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlanScheduleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanScheduleTable,
      PlanScheduleData,
      $$PlanScheduleTableFilterComposer,
      $$PlanScheduleTableOrderingComposer,
      $$PlanScheduleTableAnnotationComposer,
      $$PlanScheduleTableCreateCompanionBuilder,
      $$PlanScheduleTableUpdateCompanionBuilder,
      (PlanScheduleData, $$PlanScheduleTableReferences),
      PlanScheduleData,
      PrefetchHooks Function({bool programDayId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$MuscleGroupsTableTableManager get muscleGroups =>
      $$MuscleGroupsTableTableManager(_db, _db.muscleGroups);
  $$ContraindicationTagsTableTableManager get contraindicationTags =>
      $$ContraindicationTagsTableTableManager(_db, _db.contraindicationTags);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$ExerciseMusclesTableTableManager get exerciseMuscles =>
      $$ExerciseMusclesTableTableManager(_db, _db.exerciseMuscles);
  $$ExerciseContraindicationsTableTableManager get exerciseContraindications =>
      $$ExerciseContraindicationsTableTableManager(
        _db,
        _db.exerciseContraindications,
      );
  $$UserContraindicationsTableTableManager get userContraindications =>
      $$UserContraindicationsTableTableManager(_db, _db.userContraindications);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$ProgramDaysTableTableManager get programDays =>
      $$ProgramDaysTableTableManager(_db, _db.programDays);
  $$ProgramDayExercisesTableTableManager get programDayExercises =>
      $$ProgramDayExercisesTableTableManager(_db, _db.programDayExercises);
  $$WorkoutRemindersTableTableManager get workoutReminders =>
      $$WorkoutRemindersTableTableManager(_db, _db.workoutReminders);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$WorkoutSetResultsTableTableManager get workoutSetResults =>
      $$WorkoutSetResultsTableTableManager(_db, _db.workoutSetResults);
  $$ScheduleMarksTableTableManager get scheduleMarks =>
      $$ScheduleMarksTableTableManager(_db, _db.scheduleMarks);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$ProgramWarningDismissalsTableTableManager get programWarningDismissals =>
      $$ProgramWarningDismissalsTableTableManager(
        _db,
        _db.programWarningDismissals,
      );
  $$PlanScheduleTableTableManager get planSchedule =>
      $$PlanScheduleTableTableManager(_db, _db.planSchedule);
}
