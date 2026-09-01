import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/data/seed/exercise_seed_parser.dart';

/// Заливка упражнений из `assets/data/exercises_seed.json`.
///
/// При первом запуске копирует анимации через [MediaStore], вставляет
/// упражнения с мышцами и тегами противопоказаний и ставит флаг в
/// [AppMeta]. Повторные вызовы ничего не делают.
class ExerciseSeeder {
  ExerciseSeeder({
    required AppDatabase db,
    required MediaStore mediaStore,
    required Future<String> Function() seedJsonLoader,
  }) : this._(db, mediaStore, seedJsonLoader);

  ExerciseSeeder._(this._db, this._mediaStore, this._seedJsonLoader);

  static const String seededFlagKey = 'exercises_seeded_v2';
  static const String exercisesAssetDir = 'assets/exercises';

  /// Путь к seed-файлу упражнений в ассетах приложения.
  static const String seedAssetPath = 'assets/data/exercises_seed.json';

  final AppDatabase _db;
  final MediaStore _mediaStore;
  final Future<String> Function() _seedJsonLoader;

  /// Возвращает `true`, если сид уже выполнялся.
  Future<bool> isSeeded() async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(seededFlagKey))).getSingleOrNull();
    return row != null;
  }

  /// Выполняет сид, если он ещё не выполнялся.
  Future<void> seed() async {
    if (await isSeeded()) {
      return;
    }

    final parser = ExerciseSeedParser();
    final exercises = parser.parse(await _seedJsonLoader());
    final repo = ExerciseRepository(_db, _mediaStore);
    final now = DateTime.now();

    for (final seed in exercises) {
      final existing = await (_db.select(
        _db.exercises,
      )..where((t) => t.name.equals(seed.name))).getSingleOrNull();
      if (existing != null) {
        continue;
      }
      final animationPath = await _mediaStore.copyAssetToStorage(
        '$exercisesAssetDir/${seed.animation}',
      );
      final exercise = Exercise(
        name: seed.name,
        description: seed.description,
        instructions: seed.instructions,
        commonMistakes: seed.commonMistakes,
        type: seed.type,
        animationPath: animationPath,
        isCustom: false,
        createdAt: now,
        updatedAt: now,
      );
      final muscles = <ExerciseMuscle>[];
      for (final muscle in seed.muscles) {
        final muscleGroupId = await _muscleIdByKey(muscle.key);
        if (muscleGroupId != null) {
          muscles.add(
            ExerciseMuscle(
              exerciseId: 0,
              muscleGroupId: muscleGroupId,
              intensity: muscle.intensity,
            ),
          );
        }
      }
      final created = await repo.create(exercise, muscles);

      final tagIds = <int>[];
      for (final key in seed.contraindications) {
        final tagId = await _tagIdByKey(key);
        if (tagId != null) {
          tagIds.add(tagId);
        }
      }
      if (tagIds.isNotEmpty) {
        await repo.setContraindications(created.id!, tagIds);
      }
    }

    await _db
        .into(_db.appMeta)
        .insert(
          AppMetaCompanion.insert(
            key: seededFlagKey,
            value: const Value('true'),
          ),
        );
  }

  Future<int?> _muscleIdByKey(String key) async {
    final row = await (_db.select(
      _db.muscleGroups,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _tagIdByKey(String key) async {
    final row = await (_db.select(
      _db.contraindicationTags,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.id;
  }
}
