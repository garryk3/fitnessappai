import 'package:drift/drift.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/validators/program_day_exercise_validator.dart';
import 'package:fitnessappai/core/domain/validators/program_validator.dart';

/// Бросается при невалидной структуре программы или метриках упражнения.
class ProgramValidationException implements Exception {
  ProgramValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'ProgramValidationException($errors)';
}

/// Программа со счётчиком упражнений для экрана списка.
class ProgramSummary {
  const ProgramSummary({required this.program, required this.exercisesCount});

  final Program program;

  /// Суммарное количество позиций во всех днях программы.
  final int exercisesCount;
}

/// День программы с упражнениями основного и альтернативного наборов.
class ProgramDayDetail {
  const ProgramDayDetail({
    required this.day,
    required this.mainExercises,
    required this.alternativeExercises,
  });

  final ProgramDay day;
  final List<ProgramDayExercise> mainExercises;
  final List<ProgramDayExercise> alternativeExercises;
}

/// Программа с полной структурой дней и упражнений.
class ProgramDetail {
  const ProgramDetail({required this.program, required this.days});

  final Program program;
  final List<ProgramDayDetail> days;
}

/// Репозиторий программ: CRUD, дни и упражнения с реордером, валидация.
class ProgramRepository {
  ProgramRepository(this._db, {DataChangeNotifier? changes})
    : _changes = changes ?? appDataChanges;

  final AppDatabase _db;
  final DataChangeNotifier _changes;

  void _notify() => _changes.notifyChanged();

  static final ProgramValidator _programValidator = ProgramValidator();
  static final ProgramDayExerciseValidator _exerciseValidator =
      ProgramDayExerciseValidator();

  /// Возвращает все программы, отсортированные по названию.
  Future<List<ProgramSummary>> getPrograms() async {
    final rows = await (_db.select(
      _db.programs,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
    final counts = await _exercisesCountByProgram();
    return [
      for (final row in rows)
        ProgramSummary(
          program: _toProgram(row),
          exercisesCount: counts[row.id] ?? 0,
        ),
    ];
  }

  /// Возвращает программу по [id] с полной структурой дней или `null`.
  Future<ProgramDetail?> getProgram(int id) async {
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final days = await _daysOf(id);
    final detail = <ProgramDayDetail>[];
    for (final day in days) {
      final exercises =
          await (_db.select(_db.programDayExercises)
                ..where((t) => t.dayId.equals(day.id))
                ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
              .get();
      detail.add(
        ProgramDayDetail(
          day: _toDay(day),
          mainExercises: exercises
              .where((e) => !e.isAlternative)
              .map(_toDayExercise)
              .toList(),
          alternativeExercises: exercises
              .where((e) => e.isAlternative)
              .map(_toDayExercise)
              .toList(),
        ),
      );
    }
    return ProgramDetail(program: _toProgram(row), days: detail);
  }

  /// Возвращает программу по [id] или `null`, если её нет.
  Future<Program?> getById(int id) async {
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toProgram(row);
  }

  /// Возвращает активную программу или `null`, если активной нет.
  Future<Program?> getActiveProgram() async {
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.isActive.equals(true))).getSingleOrNull();
    return row == null ? null : _toProgram(row);
  }

  /// Возвращает все активные программы (мульти-активный режим).
  Future<List<Program>> getActivePrograms() async {
    final rows = await (_db.select(
      _db.programs,
    )..where((t) => t.isActive.equals(true))).get();
    return rows.map(_toProgram).toList();
  }

  /// Делает программу [id] активной, НЕ сбрасывая флаг у остальных
  /// (мульти-активный режим).
  Future<void> setActive(int id) async {
    await (_db.update(_db.programs)..where((t) => t.id.equals(id))).write(
      ProgramsCompanion(isActive: const Value(true)),
    );
    _notify();
  }

  /// Снимает флаг «активная» с программы [id].
  Future<void> deactivate(int id) async {
    await (_db.update(_db.programs)..where((t) => t.id.equals(id))).write(
      ProgramsCompanion(isActive: const Value(false)),
    );
    _notify();
  }

  /// Возвращает день программы по [id] или `null`, если его нет.
  Future<ProgramDay?> getDay(int id) async {
    final row = await _dayById(id);
    return row == null ? null : _toDay(row);
  }

  /// Возвращает дни программы, отсортированные по индексу.
  Future<List<ProgramDay>> getDays(int programId) async {
    final rows = await _daysOf(programId);
    return rows.map(_toDay).toList();
  }

  /// Возвращает упражнения дня, отсортированные по порядку.
  Future<List<ProgramDayExercise>> getExercises(int dayId) async {
    final rows =
        await (_db.select(_db.programDayExercises)
              ..where((t) => t.dayId.equals(dayId))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
            .get();
    return rows.map(_toDayExercise).toList();
  }

  /// Возвращает позицию упражнения по [id] или `null`.
  Future<ProgramDayExercise?> getExercise(int id) async {
    final row = await _dayExerciseById(id);
    return row == null ? null : _toDayExercise(row);
  }

  /// Создаёт программу с днями. Проверяется структура дней (1–7, индексы).
  Future<Program> create(Program program, List<ProgramDay> days) async {
    _validateDayStructure(program, days);
    final created = await _db.transaction(() async {
      final id = await _db.into(_db.programs).insert(_toCompanion(program));
      await _db.batch((batch) {
        batch.insertAll(_db.programDays, [
          for (final day in days)
            ProgramDaysCompanion.insert(
              programId: id,
              dayIndex: day.dayIndex,
              dayOfWeek: Value(day.dayOfWeek),
              warmupMinutes: Value(day.warmupMinutes),
            ),
        ]);
      });
      return (await getById(id))!;
    });
    _notify();
    return created;
  }

  /// Обновляет программу. При передаче [days] заменяет дни, при передаче
  /// [exercisesByDayIndex] заменяет упражнения и проверяет полную структуру.
  Future<Program> update(
    Program program, {
    List<ProgramDay>? days,
    Map<int, List<ProgramDayExercise>>? exercisesByDayIndex,
  }) async {
    final updated = await _db.transaction(() async {
      final id = program.id!;
      await (_db.update(
        _db.programs,
      )..where((t) => t.id.equals(id))).write(_toCompanion(program));

      if (days != null) {
        _validateDayStructure(program, days);
        await _replaceDays(id, days);
      }
      if (exercisesByDayIndex != null) {
        final targetDays = days ?? (await _daysOf(id)).map(_toDay).toList();
        _validateStructure(program, targetDays, exercisesByDayIndex);
        await _replaceExercises(id, targetDays, exercisesByDayIndex);
      }
      return (await getById(id))!;
    });
    _notify();
    return updated;
  }

  /// Удаляет программу вместе с днями и упражнениями (FK cascade).
  Future<void> delete(int id) async {
    await (_db.delete(_db.programs)..where((t) => t.id.equals(id))).go();
    _notify();
  }

  /// Добавляет день в программу на позицию [dayIndex], сдвигая следующие дни.
  Future<ProgramDay> addDay(
    int programId, {
    required int dayIndex,
    int? dayOfWeek,
    int? warmupMinutes,
  }) async {
    final day = await _db.transaction(() async {
      final rows =
          await (_db.select(_db.programDays)
                ..where((t) => t.programId.equals(programId))
                ..orderBy([(t) => OrderingTerm.desc(t.dayIndex)]))
              .get();
      for (final row in rows) {
        if (row.dayIndex >= dayIndex) {
          await (_db.update(_db.programDays)..where((t) => t.id.equals(row.id)))
              .write(ProgramDaysCompanion(dayIndex: Value(row.dayIndex + 1)));
        }
      }
      final id = await _db
          .into(_db.programDays)
          .insert(
            ProgramDaysCompanion.insert(
              programId: programId,
              dayIndex: dayIndex,
              dayOfWeek: Value(dayOfWeek),
              warmupMinutes: Value(warmupMinutes),
            ),
          );
      await _syncDaysCount(programId);
      return _toDay((await _dayById(id))!);
    });
    _notify();
    return day;
  }

  /// Обновляет день (день недели и/или индекс).
  Future<ProgramDay> updateDay(ProgramDay day) async {
    await (_db.update(
      _db.programDays,
    )..where((t) => t.id.equals(day.id!))).write(
      ProgramDaysCompanion(
        dayIndex: Value(day.dayIndex),
        dayOfWeek: Value(day.dayOfWeek),
        warmupMinutes: Value(day.warmupMinutes),
      ),
    );
    _notify();
    return _toDay((await _dayById(day.id!))!);
  }

  /// Удаляет день и переиндексирует оставшиеся дни программы.
  Future<void> removeDay(int dayId) async {
    await _db.transaction(() async {
      final day = await _dayById(dayId);
      if (day == null) {
        return;
      }
      await (_db.delete(
        _db.programDays,
      )..where((t) => t.id.equals(dayId))).go();
      final remaining =
          await (_db.select(_db.programDays)
                ..where((t) => t.programId.equals(day.programId))
                ..orderBy([(t) => OrderingTerm.asc(t.dayIndex)]))
              .get();
      await _db.batch((batch) {
        for (var i = 0; i < remaining.length; i++) {
          batch.update(
            _db.programDays,
            ProgramDaysCompanion(dayIndex: Value(i)),
            where: (t) => t.id.equals(remaining[i].id),
          );
        }
      });
      await _syncDaysCount(day.programId);
    });
    _notify();
  }

  /// Переиндексирует дни программы в порядке [dayIds].
  Future<void> reorderDays(int programId, List<int> dayIds) async {
    await _db.batch((batch) {
      for (var i = 0; i < dayIds.length; i++) {
        batch.update(
          _db.programDays,
          ProgramDaysCompanion(dayIndex: Value(i)),
          where: (t) => t.id.equals(dayIds[i]) & t.programId.equals(programId),
        );
      }
    });
    _notify();
  }

  /// Добавляет упражнение в день в конец набора ([isAlternative]).
  Future<ProgramDayExercise> addExerciseToDay(
    int dayId,
    int exerciseId, {
    bool isAlternative = false,
  }) async {
    final last =
        await (_db.selectOnly(_db.programDayExercises)
              ..addColumns([_db.programDayExercises.orderIndex.max()])
              ..where(_db.programDayExercises.dayId.equals(dayId)))
            .getSingle();
    final nextIndex =
        (last.read(_db.programDayExercises.orderIndex.max()) ?? -1) + 1;
    final id = await _db
        .into(_db.programDayExercises)
        .insert(
          ProgramDayExercisesCompanion.insert(
            dayId: dayId,
            exerciseId: Value(exerciseId),
            orderIndex: nextIndex,
            isAlternative: Value(isAlternative),
          ),
        );
    _notify();
    return _toDayExercise((await _dayExerciseById(id))!);
  }

  /// Обновляет метрики упражнения. Метрики проверяются по типу упражнения.
  Future<ProgramDayExercise> updateExercise(ProgramDayExercise item) async {
    final type = await _exerciseTypeOf(item.exerciseId);
    if (type != null) {
      final result = _exerciseValidator.validate(item, type);
      if (!result.isValid) {
        throw ProgramValidationException(result.errors);
      }
    }
    await (_db.update(_db.programDayExercises)
          ..where((t) => t.id.equals(item.id!)))
        .write(_toDayExerciseCompanion(item));
    _notify();
    return _toDayExercise((await _dayExerciseById(item.id!))!);
  }

  /// Удаляет позицию упражнения из дня.
  Future<void> removeExercise(int id) async {
    await (_db.delete(
      _db.programDayExercises,
    )..where((t) => t.id.equals(id))).go();
    _notify();
  }

  /// Переиндексирует упражнения дня в порядке [itemIds].
  Future<void> reorderExercises(int dayId, List<int> itemIds) async {
    await _db.batch((batch) {
      for (var i = 0; i < itemIds.length; i++) {
        batch.update(
          _db.programDayExercises,
          ProgramDayExercisesCompanion(orderIndex: Value(i)),
          where: (t) => t.id.equals(itemIds[i]) & t.dayId.equals(dayId),
        );
      }
    });
    _notify();
  }

  /// Заменяет упражнения одного дня без полной валидации программы.
  ///
  /// Используется при сохранении черновика дня, когда другие дни ещё не
  /// заполнены.
  Future<void> replaceDayExercises(
    int dayId,
    List<ProgramDayExercise> exercises,
  ) async {
    await (_db.delete(
      _db.programDayExercises,
    )..where((t) => t.dayId.equals(dayId))).go();
    await _db.batch((batch) {
      for (var i = 0; i < exercises.length; i++) {
        batch.insert(
          _db.programDayExercises,
          _toDayExerciseCompanion(
            exercises[i],
          ).copyWith(dayId: Value(dayId), orderIndex: Value(i)),
        );
      }
    });
    _notify();
  }

  /// Возвращает `true`, если предупреждения для программы скрыты.
  Future<bool> isWarningDismissed(int programId) async {
    final row = await (_db.select(
      _db.programWarningDismissals,
    )..where((t) => t.programId.equals(programId))).getSingleOrNull();
    return row != null;
  }

  /// Запоминает отметку «не показывать предупреждения» для программы.
  Future<void> dismissWarnings(int programId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.programWarningDismissals,
      )..where((t) => t.programId.equals(programId))).go();
      await _db
          .into(_db.programWarningDismissals)
          .insert(
            ProgramWarningDismissalsCompanion.insert(
              programId: programId,
              dismissedAt: DateTime.now(),
            ),
          );
    });
    _notify();
  }

  Future<Map<int, int>> _exercisesCountByProgram() async {
    final query = _db.selectOnly(_db.programDayExercises)
      ..addColumns([
        _db.programDays.programId,
        _db.programDayExercises.id.count(),
      ])
      ..join([
        innerJoin(
          _db.programDays,
          _db.programDays.id.equalsExp(_db.programDayExercises.dayId),
        ),
      ])
      ..groupBy([_db.programDays.programId]);
    final counts = <int, int>{};
    for (final row in await query.get()) {
      counts[row.read(_db.programDays.programId)!] = row.read(
        _db.programDayExercises.id.count(),
      )!;
    }
    return counts;
  }

  Future<List<ProgramDayRow>> _daysOf(int programId) async {
    return (_db.select(_db.programDays)
          ..where((t) => t.programId.equals(programId))
          ..orderBy([(t) => OrderingTerm.asc(t.dayIndex)]))
        .get();
  }

  Future<void> _replaceDays(int programId, List<ProgramDay> days) async {
    final existing = await (_db.select(
      _db.programDays,
    )..where((t) => t.programId.equals(programId))).get();
    final idById = {for (final row in existing) row.id: row};
    final idByDayIndex = {for (final row in existing) row.dayIndex: row.id};
    final requestedIds = <int>{};

    for (final day in days) {
      int? existingId;
      if (day.id != null && idById.containsKey(day.id)) {
        existingId = day.id;
      } else {
        existingId = idByDayIndex[day.dayIndex];
      }
      if (existingId != null) {
        final eid = existingId;
        requestedIds.add(eid);
        await (_db.update(
          _db.programDays,
        )..where((t) => t.id.equals(eid))).write(
          ProgramDaysCompanion(
            dayIndex: Value(day.dayIndex),
            dayOfWeek: Value(day.dayOfWeek),
            warmupMinutes: Value(day.warmupMinutes),
          ),
        );
      } else {
        final newId = await _db
            .into(_db.programDays)
            .insert(
              ProgramDaysCompanion.insert(
                programId: programId,
                dayIndex: day.dayIndex,
                dayOfWeek: Value(day.dayOfWeek),
                warmupMinutes: Value(day.warmupMinutes),
              ),
            );
        requestedIds.add(newId);
      }
    }
    for (final row in existing) {
      if (!requestedIds.contains(row.id)) {
        await (_db.delete(
          _db.programDays,
        )..where((t) => t.id.equals(row.id))).go();
      }
    }
    await _syncDaysCount(programId);
  }

  Future<void> _replaceExercises(
    int programId,
    List<ProgramDay> days,
    Map<int, List<ProgramDayExercise>> exercisesByDayIndex,
  ) async {
    final dayRows = await _daysOf(programId);
    final dayIds = dayRows.map((d) => d.id).toList();
    await (_db.delete(
      _db.programDayExercises,
    )..where((t) => t.dayId.isIn(dayIds))).go();
    final dayIdByIndex = {for (final d in dayRows) d.dayIndex: d.id};
    await _db.batch((batch) {
      for (final day in days) {
        final dayId = dayIdByIndex[day.dayIndex];
        if (dayId == null) {
          continue;
        }
        final items = exercisesByDayIndex[day.dayIndex] ?? const [];
        for (var i = 0; i < items.length; i++) {
          batch.insert(
            _db.programDayExercises,
            _toDayExerciseCompanion(
              items[i],
            ).copyWith(dayId: Value(dayId), orderIndex: Value(i)),
          );
        }
      }
    });
  }

  Future<void> _syncDaysCount(int programId) async {
    final row =
        await (_db.selectOnly(_db.programDays)
              ..addColumns([_db.programDays.id.count()])
              ..where(_db.programDays.programId.equals(programId)))
            .getSingle();
    final count = row.read(_db.programDays.id.count())!;
    await (_db.update(_db.programs)..where((t) => t.id.equals(programId)))
        .write(ProgramsCompanion(daysCount: Value(count)));
  }

  Future<ExerciseType?> _exerciseTypeOf(int? exerciseId) async {
    if (exerciseId == null) {
      return null;
    }
    final row = await (_db.select(
      _db.exercises,
    )..where((t) => t.id.equals(exerciseId))).getSingleOrNull();
    return row?.type;
  }

  void _validateDayStructure(Program program, List<ProgramDay> days) {
    final errors = <String>[];
    if (program.name.trim().isEmpty) {
      errors.add('Название программы обязательно');
    }
    if (days.length < ProgramValidator.minDays ||
        days.length > ProgramValidator.maxDays) {
      errors.add(
        'Количество дней должно быть от ${ProgramValidator.minDays} '
        'до ${ProgramValidator.maxDays}',
      );
    }
    if (days.length != program.daysCount) {
      errors.add('daysCount не совпадает с количеством дней');
    }
    final indexes = days.map((d) => d.dayIndex).toSet();
    if (indexes.length != days.length) {
      errors.add('Индексы дней должны быть уникальными');
    }
    if (errors.isNotEmpty) {
      throw ProgramValidationException(errors);
    }
  }

  void _validateStructure(
    Program program,
    List<ProgramDay> days,
    Map<int, List<ProgramDayExercise>> exercisesByDayIndex,
  ) {
    final result = _programValidator.validate(
      program: program,
      days: days,
      exercisesByDayIndex: exercisesByDayIndex,
    );
    if (!result.isValid) {
      throw ProgramValidationException(result.errors);
    }
  }

  Future<ProgramDayRow?> _dayById(int id) async {
    return (_db.select(
      _db.programDays,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<ProgramDayExerciseRow?> _dayExerciseById(int id) async {
    return (_db.select(
      _db.programDayExercises,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  ProgramsCompanion _toCompanion(Program p) => ProgramsCompanion(
    id: p.id == null ? const Value.absent() : Value(p.id!),
    name: Value(p.name),
    description: Value(p.description),
    daysCount: Value(p.daysCount),
    createdAt: Value(p.createdAt),
    updatedAt: Value(p.updatedAt),
    isActive: Value(p.isActive),
  );

  ProgramDayExercisesCompanion _toDayExerciseCompanion(ProgramDayExercise e) =>
      ProgramDayExercisesCompanion(
        id: e.id == null ? const Value.absent() : Value(e.id!),
        dayId: Value(e.dayId),
        exerciseId: Value(e.exerciseId),
        orderIndex: Value(e.orderIndex),
        sets: Value(e.sets),
        reps: Value(e.reps),
        durationSeconds: Value(e.durationSeconds),
        weightKg: Value(e.weightKg),
        distanceMeters: Value(e.distanceMeters),
        restSeconds: Value(e.restSeconds),
        isAlternative: Value(e.isAlternative),
      );

  Program _toProgram(ProgramRow row) => Program(
    id: row.id,
    name: row.name,
    description: row.description,
    daysCount: row.daysCount,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    isActive: row.isActive,
  );

  ProgramDay _toDay(ProgramDayRow row) => ProgramDay(
    id: row.id,
    programId: row.programId,
    dayIndex: row.dayIndex,
    dayOfWeek: row.dayOfWeek,
    warmupMinutes: row.warmupMinutes,
  );

  ProgramDayExercise _toDayExercise(ProgramDayExerciseRow row) =>
      ProgramDayExercise(
        id: row.id,
        dayId: row.dayId,
        exerciseId: row.exerciseId,
        orderIndex: row.orderIndex,
        sets: row.sets,
        reps: row.reps,
        durationSeconds: row.durationSeconds,
        weightKg: row.weightKg,
        distanceMeters: row.distanceMeters,
        restSeconds: row.restSeconds,
        isAlternative: row.isAlternative,
      );
}
