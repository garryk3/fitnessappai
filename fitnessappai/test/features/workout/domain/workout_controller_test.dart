import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/workout/domain/workout_controller.dart';
import 'package:fitnessappai/features/workout/domain/workout_exercise.dart';
import 'package:fitnessappai/features/workout/domain/workout_session_context.dart';
import 'package:fitnessappai/features/workout/domain/workout_set_input.dart';

void main() {
  final startTime = DateTime(2026, 8, 9, 18, 0);

  Exercise exercise(int id, String name, ExerciseType type) => Exercise(
    id: id,
    name: name,
    type: type,
    createdAt: startTime,
    updatedAt: startTime,
  );

  WorkoutExercise strengthExercise({
    int sets = 3,
    int? reps = 8,
    double? weightKg = 20,
    int? rest = 60,
  }) => WorkoutExercise(
    position: ProgramDayExercise(
      dayId: 1,
      orderIndex: 0,
      sets: sets,
      reps: reps,
      weightKg: weightKg,
      restSeconds: rest,
    ),
    exercise: exercise(10, 'Приседания', ExerciseType.strength),
  );

  WorkoutExercise plankExercise({int? duration = 45, int sets = 1}) =>
      WorkoutExercise(
        position: ProgramDayExercise(
          dayId: 1,
          orderIndex: 0,
          sets: sets,
          durationSeconds: duration,
        ),
        exercise: exercise(11, 'Планка', ExerciseType.plank),
      );

  WorkoutExercise runningExercise({
    int? duration = 1800,
    double? distanceMeters = 5000,
  }) => WorkoutExercise(
    position: ProgramDayExercise(
      dayId: 1,
      orderIndex: 0,
      sets: 1,
      durationSeconds: duration,
      distanceMeters: distanceMeters,
    ),
    exercise: exercise(12, 'Бег', ExerciseType.running),
  );

  test('start: невалидно без упражнений', () {
    final controller = WorkoutController(clock: () => startTime);
    expect(
      () => controller.start(const []),
      throwsA(isA<WorkoutStateException>()),
    );
    controller.dispose();
  });

  test('strength: 3×8 с отдыхом 60 с', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([strengthExercise(sets: 3, rest: 60)]);

      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.currentSet.value, 1);
      expect(controller.currentExercise!.name, 'Приседания');

      for (var set = 1; set <= 3; set++) {
        controller.setResult(const WorkoutSetInput(reps: 8, weightKg: 20));
        controller.confirmSet();
        if (set < 3) {
          expect(controller.phase.value, WorkoutPhase.rest);
          expect(controller.restRemainingSeconds.value, 60);
          expect(controller.currentSet.value, set + 1);

          async.elapse(const Duration(seconds: 60));
          expect(controller.phase.value, WorkoutPhase.exercise);
          expect(controller.restRemainingSeconds.value, isNull);
        } else {
          expect(controller.phase.value, WorkoutPhase.finished);
        }
      }
      expect(controller.completedSets.value, 3);
      expect(controller.results.value, hasLength(3));
      controller.dispose();
    });
  });

  test('rest: skipRest прерывает отдых', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([strengthExercise(sets: 2, rest: 60)]);
      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.rest);
      controller.skipRest();
      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.currentSet.value, 2);
      expect(controller.restRemainingSeconds.value, isNull);

      async.elapse(const Duration(seconds: 5));
      expect(controller.restRemainingSeconds.value, isNull);
      controller.dispose();
    });
  });

  test('подход нельзя подтвердить во время отдыха', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([strengthExercise(sets: 2, rest: 60)]);
      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.rest);
      expect(
        () => controller.confirmSet(),
        throwsA(isA<WorkoutStateException>()),
      );
      controller.dispose();
    });
  });

  test('plank: запускается таймер удержания', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([plankExercise(duration: 45)]);

      expect(controller.holdRemainingSeconds.value, 45);
      async.elapse(const Duration(seconds: 5));
      expect(controller.holdRemainingSeconds.value, 40);
      async.elapse(const Duration(seconds: 40));
      expect(controller.holdRemainingSeconds.value, 0);

      controller.dispose();
    });
  });

  test('plank: фиксация подхода останавливает таймер удержания', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([plankExercise(duration: 45)]);

      controller.setResult(const WorkoutSetInput(durationSeconds: 40));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.finished);
      expect(controller.holdRemainingSeconds.value, isNull);
      expect(controller.results.value.single.durationSeconds, 40);
      expect(controller.results.value.single.exerciseName, 'Планка');
      expect(controller.results.value.single.setIndex, 1);

      async.elapse(const Duration(seconds: 100));
      expect(controller.holdRemainingSeconds.value, isNull);
      controller.dispose();
    });
  });

  test('running: фиксация дистанции и времени', () {
    final controller = WorkoutController(clock: () => startTime);
    controller.start([runningExercise()]);

    controller.setResult(
      const WorkoutSetInput(durationSeconds: 1800, distanceMeters: 5000),
    );
    controller.confirmSet();

    expect(controller.phase.value, WorkoutPhase.finished);
    final result = controller.results.value.single;
    expect(result.exerciseType, ExerciseType.running);
    expect(result.durationSeconds, 1800);
    expect(result.distanceMeters, 5000);
    controller.dispose();
  });

  test('переход к следующему упражнению после последнего подхода', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([strengthExercise(sets: 1), runningExercise()]);

      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();

      expect(controller.currentExerciseIndex.value, 1);
      expect(controller.currentExercise!.name, 'Бег');
      expect(controller.currentSet.value, 1);
      expect(controller.phase.value, WorkoutPhase.exercise);
      controller.dispose();
    });
  });

  test('nextExercise переходит к следующему упражнению, пропуская отдых', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([
        strengthExercise(sets: 2, rest: 60),
        runningExercise(),
      ]);

      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();
      expect(controller.phase.value, WorkoutPhase.rest);

      controller.nextExercise();
      expect(controller.currentExerciseIndex.value, 1);
      expect(controller.currentSet.value, 1);
      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.restRemainingSeconds.value, isNull);
      controller.dispose();
    });
  });

  test('completeWorkout возвращает сессию и результаты', () {
    final controller = WorkoutController(clock: () => startTime);
    controller.start(
      [strengthExercise(sets: 1)],
      context: const WorkoutSessionContext(
        programId: 5,
        programName: 'База',
        programDayId: 7,
        dayIndex: 2,
        variant: WorkoutVariant.alternative,
      ),
    );
    controller.setResult(const WorkoutSetInput(reps: 8, weightKg: 20));
    controller.confirmSet();
    expect(controller.phase.value, WorkoutPhase.finished);

    final outcome = controller.completeWorkout();
    expect(outcome.session.programName, 'База');
    expect(outcome.session.programId, 5);
    expect(outcome.session.programDayId, 7);
    expect(outcome.session.dayIndex, 2);
    expect(outcome.session.variant, WorkoutVariant.alternative);
    expect(outcome.session.performedDate, DateTime(2026, 8, 9));
    expect(outcome.session.startedAt, startTime);
    expect(outcome.session.endedAt, startTime);

    expect(outcome.results, hasLength(1));
    expect(outcome.results.first.exerciseName, 'Приседания');
    expect(outcome.results.first.reps, 8);
    expect(outcome.results.first.weightKg, 20);
    expect(outcome.results.first.setIndex, 1);
    expect(outcome.results.first.sessionId, 0);
    controller.dispose();
  });

  test('completeWorkout до завершения бросает WorkoutStateException', () {
    final controller = WorkoutController(clock: () => startTime);
    controller.start([strengthExercise(sets: 2)]);
    controller.setResult(const WorkoutSetInput(reps: 8));

    expect(
      () => controller.completeWorkout(),
      throwsA(isA<WorkoutStateException>()),
    );
    controller.dispose();
  });

  test('cancelWorkout ничего не сохраняет и останавливает таймеры', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([strengthExercise(sets: 2, rest: 60)]);
      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();
      expect(controller.phase.value, WorkoutPhase.rest);

      controller.cancelWorkout();
      expect(controller.phase.value, WorkoutPhase.idle);
      expect(controller.currentExercise, isNull);
      expect(controller.exercises, isEmpty);
      expect(controller.results.value, isEmpty);
      expect(controller.completedSets.value, 0);
      expect(
        () => controller.completeWorkout(),
        throwsA(isA<WorkoutStateException>()),
      );

      async.elapse(const Duration(seconds: 10));
      expect(controller.restRemainingSeconds.value, isNull);
      controller.dispose();
    });
  });

  test('невалидный подход отклоняется', () {
    final controller = WorkoutController(clock: () => startTime);
    controller.start([strengthExercise(sets: 1)]);

    expect(controller.validateDraft(), isNotEmpty);
    expect(
      () => controller.confirmSet(),
      throwsA(isA<WorkoutStateException>()),
    );
    expect(controller.results.value, isEmpty);

    controller.setResult(const WorkoutSetInput(reps: 8, weightKg: -5));
    expect(controller.validateDraft(), isNotEmpty);
    expect(
      () => controller.confirmSet(),
      throwsA(isA<WorkoutStateException>()),
    );
    expect(controller.results.value, isEmpty);
    controller.dispose();
  });

  test('инжектируемый timerFactory управляет отдыхом', () {
    final timers = <_FakeTimer>[];
    final controller = WorkoutController(
      clock: () => startTime,
      timerFactory: (duration, callback) {
        late final _FakeTimer timer;
        timer = _FakeTimer(() => callback(timer));
        timers.add(timer);
        return timer;
      },
    );
    controller.start([strengthExercise(sets: 2, rest: 60)]);
    controller.setResult(const WorkoutSetInput(reps: 8));
    controller.confirmSet();

    expect(timers, hasLength(1));
    expect(controller.restRemainingSeconds.value, 60);

    for (var i = 0; i < 59; i++) {
      timers[0].fire();
    }
    expect(controller.restRemainingSeconds.value, 1);

    timers[0].fire();
    expect(controller.restRemainingSeconds.value, isNull);
    expect(controller.phase.value, WorkoutPhase.exercise);
    controller.dispose();
  });

  test('инжектируемый timerFactory управляет удержанием планки', () {
    final timers = <_FakeTimer>[];
    final controller = WorkoutController(
      clock: () => startTime,
      timerFactory: (duration, callback) {
        late final _FakeTimer timer;
        timer = _FakeTimer(() => callback(timer));
        timers.add(timer);
        return timer;
      },
    );
    controller.start([plankExercise(duration: 45)]);

    expect(timers, hasLength(1));
    expect(controller.holdRemainingSeconds.value, 45);

    for (var i = 0; i < 44; i++) {
      timers[0].fire();
    }
    expect(controller.holdRemainingSeconds.value, 1);

    timers[0].fire();
    expect(controller.holdRemainingSeconds.value, 0);
    controller.dispose();
  });
}

class _FakeTimer implements Timer {
  _FakeTimer(this._onFire);

  final void Function() _onFire;
  bool _cancelled = false;

  @override
  void cancel() {
    _cancelled = true;
  }

  @override
  bool get isActive => !_cancelled;

  @override
  int get tick => 0;

  void fire() => _onFire();
}
