import 'package:drift/drift.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';

/// Сессия вместе с результатами подходов.
class WorkoutSessionDetail {
  const WorkoutSessionDetail({required this.session, required this.results});

  final WorkoutSession session;
  final List<WorkoutSetResult> results;
}

/// Репозиторий тренировок: запись сессий с результатами и отметки пропусков.
class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  /// Сохраняет сессию и результаты подходов в одной транзакции.
  ///
  /// Идентификатор сессии присваивается базой и подставляется в результаты.
  Future<WorkoutSessionDetail> saveSession(
    WorkoutSession session,
    List<WorkoutSetResult> results,
  ) {
    return _db.transaction(() async {
      final sessionId = await _db
          .into(_db.workoutSessions)
          .insert(_toSessionCompanion(session));
      await _db.batch((batch) {
        for (final result in results) {
          batch.insert(
            _db.workoutSetResults,
            _toResultCompanion(result).copyWith(sessionId: Value(sessionId)),
          );
        }
      });
      return (await getSession(sessionId))!;
    });
  }

  /// Сессии тренировочного дня за неделю с понедельником [weekStart].
  Future<List<WorkoutSession>> getSessions(
    int programDayId,
    DateTime weekStart,
  ) async {
    final startMs = weekStart.millisecondsSinceEpoch;
    final endMs = weekStart.add(const Duration(days: 7)).millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.workoutSessions)
              ..where(
                (t) =>
                    t.programDayId.equals(programDayId) &
                    t.performedDate.isBiggerOrEqualValue(startMs) &
                    t.performedDate.isSmallerThanValue(endMs),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.performedDate)]))
            .get();
    return rows.map(_toSession).toList();
  }

  /// Все сессии в диапазоне дат `[start, end)`.
  Future<List<WorkoutSession>> getSessionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.workoutSessions)
              ..where(
                (t) =>
                    t.performedDate.isBiggerOrEqualValue(startMs) &
                    t.performedDate.isSmallerThanValue(endMs),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.performedDate)]))
            .get();
    return rows.map(_toSession).toList();
  }

  /// Возвращает сессию по [id] с результатами или `null`.
  Future<WorkoutSessionDetail?> getSession(int id) async {
    final row = await (_db.select(
      _db.workoutSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final resultRows =
        await (_db.select(_db.workoutSetResults)
              ..where((t) => t.sessionId.equals(id))
              ..orderBy([
                (t) => OrderingTerm.asc(t.setIndex),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    return WorkoutSessionDetail(
      session: _toSession(row),
      results: resultRows.map(_toResult).toList(),
    );
  }

  /// Отмечает день пропущенным на неделе [weekStart]. Идемпотентно.
  Future<void> markSkipped(int programDayId, DateTime weekStart) async {
    final existing =
        await (_db.select(_db.scheduleMarks)..where(
              (t) =>
                  t.programDayId.equals(programDayId) &
                  t.weekStart.equals(weekStart.millisecondsSinceEpoch),
            ))
            .getSingleOrNull();
    if (existing != null) {
      return;
    }
    await _db
        .into(_db.scheduleMarks)
        .insert(
          ScheduleMarksCompanion.insert(
            programDayId: programDayId,
            weekStart: weekStart,
            status: ScheduleMarkStatus.skipped,
          ),
        );
  }

  /// Убирает отметку пропуска дня на неделе [weekStart].
  Future<void> clearSkip(int programDayId, DateTime weekStart) async {
    await (_db.delete(_db.scheduleMarks)..where(
          (t) =>
              t.programDayId.equals(programDayId) &
              t.weekStart.equals(weekStart.millisecondsSinceEpoch),
        ))
        .go();
  }

  /// Отметки пропусков за неделю с понедельником [weekStart].
  Future<List<ScheduleMark>> getSkips(DateTime weekStart) async {
    final startMs = weekStart.millisecondsSinceEpoch;
    final endMs = weekStart.add(const Duration(days: 7)).millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.scheduleMarks)..where(
              (t) =>
                  t.weekStart.isBiggerOrEqualValue(startMs) &
                  t.weekStart.isSmallerThanValue(endMs),
            ))
            .get();
    return rows.map(_toMark).toList();
  }

  WorkoutSessionsCompanion _toSessionCompanion(WorkoutSession s) =>
      WorkoutSessionsCompanion.insert(
        programId: Value(s.programId),
        programName: s.programName,
        programDayId: Value(s.programDayId),
        dayIndex: s.dayIndex,
        variant: s.variant,
        performedDate: s.performedDate,
        startedAt: s.startedAt,
        endedAt: s.endedAt,
      );

  WorkoutSetResultsCompanion _toResultCompanion(WorkoutSetResult r) =>
      WorkoutSetResultsCompanion.insert(
        sessionId: r.sessionId,
        exerciseId: Value(r.exerciseId),
        exerciseName: r.exerciseName,
        exerciseType: r.exerciseType,
        setIndex: r.setIndex,
        reps: Value(r.reps),
        weightKg: Value(r.weightKg),
        durationSeconds: Value(r.durationSeconds),
        distanceMeters: Value(r.distanceMeters),
        completedAt: r.completedAt,
      );

  WorkoutSession _toSession(WorkoutSessionRow row) => WorkoutSession(
    id: row.id,
    programId: row.programId,
    programName: row.programName,
    programDayId: row.programDayId,
    dayIndex: row.dayIndex,
    variant: row.variant,
    performedDate: row.performedDate,
    startedAt: row.startedAt,
    endedAt: row.endedAt,
    status: row.status,
  );

  WorkoutSetResult _toResult(WorkoutSetResultRow row) => WorkoutSetResult(
    id: row.id,
    sessionId: row.sessionId,
    exerciseId: row.exerciseId,
    exerciseName: row.exerciseName,
    exerciseType: row.exerciseType,
    setIndex: row.setIndex,
    reps: row.reps,
    weightKg: row.weightKg,
    durationSeconds: row.durationSeconds,
    distanceMeters: row.distanceMeters,
    completedAt: row.completedAt,
  );

  ScheduleMark _toMark(ScheduleMarkRow row) => ScheduleMark(
    id: row.id,
    programDayId: row.programDayId,
    weekStart: row.weekStart,
    status: row.status,
  );
}
