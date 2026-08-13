import 'package:drift/drift.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/media/media_store.dart';

/// Репозиторий упражнений: CRUD, поиск/фильтр, мышцы и противопоказания.
class ExerciseRepository {
  ExerciseRepository(this._db, this._mediaStore, {DataChangeNotifier? changes})
    : _changes = changes ?? appDataChanges;

  final AppDatabase _db;
  final MediaStore _mediaStore;
  final DataChangeNotifier _changes;

  void _notify() => _changes.notifyChanged();

  /// Возвращает все упражнения, отсортированные по названию.
  Future<List<Exercise>> getAll() async {
    final rows = await (_db.select(
      _db.exercises,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
    return rows.map(_toModel).toList();
  }

  /// Возвращает упражнение по [id] или `null`, если его нет.
  Future<Exercise?> getById(int id) async {
    final row = await (_db.select(
      _db.exercises,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Ищет упражнения по подстроке в названии (без учёта регистра).
  ///
  /// Фильтрация выполняется в Dart, т.к. LIKE в SQLite не учитывает регистр
  /// кириллицы.
  Future<List<Exercise>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return getAll();
    }
    final all = await getAll();
    return all.where((e) => e.name.toLowerCase().contains(normalized)).toList();
  }

  /// Возвращает упражнения заданного типа.
  Future<List<Exercise>> getByType(ExerciseType type) async {
    final rows =
        await (_db.select(_db.exercises)
              ..where((t) => t.type.equalsValue(type))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return rows.map(_toModel).toList();
  }

  /// Возвращает весь каталог мышечных групп.
  Future<List<MuscleGroup>> getAllMuscleGroups() async {
    final rows = await (_db.select(
      _db.muscleGroups,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return rows.map(_muscleGroupFromRow).toList();
  }

  /// Возвращает весь каталог тегов противопоказаний.
  Future<List<ContraindicationTag>> getAllContraindicationTags() async {
    final rows = await (_db.select(
      _db.contraindicationTags,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return rows.map(_tagFromRow).toList();
  }

  /// Создаёт упражнение и привязывает [muscles].
  Future<Exercise> create(
    Exercise exercise,
    List<ExerciseMuscle> muscles,
  ) async {
    final created = await _db.transaction(() async {
      final id = await _db.into(_db.exercises).insert(_toCompanion(exercise));
      if (muscles.isNotEmpty) {
        await _insertMuscles(id, muscles);
      }
      return (await getById(id))!;
    });
    _notify();
    return created;
  }

  /// Обновляет упражнение. Если [muscles] передан, заменяет привязки мышц.
  Future<Exercise> update(
    Exercise exercise, {
    List<ExerciseMuscle>? muscles,
  }) async {
    final updated = await _db.transaction(() async {
      final id = exercise.id!;
      await (_db.update(
        _db.exercises,
      )..where((t) => t.id.equals(id))).write(_toCompanion(exercise));
      if (muscles != null) {
        await _replaceMuscles(id, muscles);
      }
      return (await getById(id))!;
    });
    _notify();
    return updated;
  }

  /// Удаляет упражнение вместе со связями (FK cascade) и файлами медиа.
  Future<void> delete(int id) async {
    final exercise = await getById(id);
    if (exercise == null) {
      return;
    }
    await (_db.delete(_db.exercises)..where((t) => t.id.equals(id))).go();
    for (final path in _mediaPaths(exercise)) {
      await _mediaStore.deleteFile(path);
    }
    _notify();
  }

  /// Возвращает привязки мышц упражнения.
  Future<List<ExerciseMuscle>> getMuscles(int exerciseId) async {
    final rows = await (_db.select(
      _db.exerciseMuscles,
    )..where((t) => t.exerciseId.equals(exerciseId))).get();
    return rows
        .map(
          (r) => ExerciseMuscle(
            exerciseId: r.exerciseId,
            muscleGroupId: r.muscleGroupId,
            intensity: r.intensity,
          ),
        )
        .toList();
  }

  /// Возвращает карту «id упражнения → мышечные группы» для списка.
  Future<Map<int, List<MuscleGroup>>> muscleGroupsByExercise() async {
    final query = _db.select(_db.muscleGroups).join([
      innerJoin(
        _db.exerciseMuscles,
        _db.exerciseMuscles.muscleGroupId.equalsExp(_db.muscleGroups.id),
      ),
    ]);
    final result = <int, List<MuscleGroup>>{};
    for (final row in await query.get()) {
      final link = row.readTable(_db.exerciseMuscles);
      final group = _muscleGroupFromRow(row.readTable(_db.muscleGroups));
      result.putIfAbsent(link.exerciseId, () => []).add(group);
    }
    return result;
  }

  /// Возвращает карту «id упражнения → теги противопоказаний» для предупреждений.
  Future<Map<int, List<ContraindicationTag>>>
  contraindicationsByExercise() async {
    final query = _db.select(_db.contraindicationTags).join([
      innerJoin(
        _db.exerciseContraindications,
        _db.exerciseContraindications.contraindicationTagId.equalsExp(
          _db.contraindicationTags.id,
        ),
      ),
    ]);
    final result = <int, List<ContraindicationTag>>{};
    for (final row in await query.get()) {
      final link = row.readTable(_db.exerciseContraindications);
      result
          .putIfAbsent(link.exerciseId, () => [])
          .add(_tagFromRow(row.readTable(_db.contraindicationTags)));
    }
    return result;
  }

  /// Заменяет привязки мышц упражнения.
  Future<void> setMuscles(int exerciseId, List<ExerciseMuscle> muscles) async {
    await _db.transaction(() => _replaceMuscles(exerciseId, muscles));
    _notify();
  }

  /// Возвращает теги противопоказаний упражнения.
  Future<List<ContraindicationTag>> getContraindications(int exerciseId) async {
    final query = _db.select(_db.contraindicationTags).join([
      innerJoin(
        _db.exerciseContraindications,
        _db.exerciseContraindications.contraindicationTagId.equalsExp(
          _db.contraindicationTags.id,
        ),
      ),
    ])..where(_db.exerciseContraindications.exerciseId.equals(exerciseId));
    final rows = await query.get();
    return rows
        .map((row) => _tagFromRow(row.readTable(_db.contraindicationTags)))
        .toList();
  }

  /// Заменяет теги противопоказаний упражнения.
  Future<void> setContraindications(int exerciseId, List<int> tagIds) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.exerciseContraindications,
      )..where((t) => t.exerciseId.equals(exerciseId))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.exerciseContraindications, [
          for (final tagId in tagIds)
            ExerciseContraindicationsCompanion.insert(
              exerciseId: exerciseId,
              contraindicationTagId: tagId,
            ),
        ]);
      });
    });
    _notify();
  }

  Future<void> _insertMuscles(int exerciseId, List<ExerciseMuscle> muscles) {
    return _db.batch((batch) {
      batch.insertAll(_db.exerciseMuscles, [
        for (final m in muscles)
          ExerciseMusclesCompanion.insert(
            exerciseId: exerciseId,
            muscleGroupId: m.muscleGroupId,
            intensity: m.intensity,
          ),
      ]);
    });
  }

  Future<void> _replaceMuscles(
    int exerciseId,
    List<ExerciseMuscle> muscles,
  ) async {
    await (_db.delete(
      _db.exerciseMuscles,
    )..where((t) => t.exerciseId.equals(exerciseId))).go();
    if (muscles.isNotEmpty) {
      await _insertMuscles(exerciseId, muscles);
    }
  }

  List<String> _mediaPaths(Exercise exercise) => [
    if (exercise.thumbnailPath != null) exercise.thumbnailPath!,
    if (exercise.animationPath != null) exercise.animationPath!,
  ];

  ExercisesCompanion _toCompanion(Exercise e) => ExercisesCompanion(
    id: e.id == null ? const Value.absent() : Value(e.id!),
    name: Value(e.name),
    description: Value(e.description),
    instructions: Value(e.instructions),
    commonMistakes: Value(e.commonMistakes),
    type: Value(e.type),
    thumbnailPath: Value(e.thumbnailPath),
    animationPath: Value(e.animationPath),
    isCustom: Value(e.isCustom),
    createdAt: Value(e.createdAt),
    updatedAt: Value(e.updatedAt),
  );

  Exercise _toModel(ExerciseRow row) => Exercise(
    id: row.id,
    name: row.name,
    description: row.description,
    instructions: row.instructions,
    commonMistakes: row.commonMistakes,
    type: row.type,
    thumbnailPath: row.thumbnailPath,
    animationPath: row.animationPath,
    isCustom: row.isCustom,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ContraindicationTag _tagFromRow(ContraindicationTagRow row) =>
      ContraindicationTag(id: row.id, key: row.key, labelRu: row.labelRu);

  MuscleGroup _muscleGroupFromRow(MuscleGroupRow row) => MuscleGroup(
    id: row.id,
    key: row.key,
    labelRu: row.labelRu,
    view: row.view,
    regionKey: row.regionKey,
  );
}
