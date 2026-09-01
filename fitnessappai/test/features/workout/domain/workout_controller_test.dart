import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
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

  WorkoutExercise bodyweightExercise({int sets = 3, int? reps = 15}) =>
      WorkoutExercise(
        position: ProgramDayExercise(
          dayId: 1,
          orderIndex: 0,
          sets: sets,
          reps: reps,
        ),
        exercise: exercise(13, 'Отжимания', ExerciseType.bodyweight),
      );

  WorkoutExercise perSideExercise({int sets = 1, int? rest = 60}) =>
      WorkoutExercise(
        position: ProgramDayExercise(
          dayId: 1,
          orderIndex: 0,
          sets: sets,
          reps: 8,
          weightKg: 20,
          restSeconds: rest,
        ),
        exercise: Exercise(
          id: 20,
          name: 'Гантели',
          type: ExerciseType.strength,
          perSide: true,
          createdAt: startTime,
          updatedAt: startTime,
        ),
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
      final controller = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
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

  test('rest: пересчёт по wall-clock завершает отдых после «сна»', () {
    fakeAsync((async) {
      var now = startTime;
      final controller = WorkoutController(clock: () => now);
      controller.start([strengthExercise(sets: 2, rest: 60)]);
      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.rest);
      expect(controller.restRemainingSeconds.value, 60);

      // Имитация сна: прошло 5 минут, но таймер отдыха не тикал.
      now = startTime.add(const Duration(minutes: 5));
      async.elapse(const Duration(seconds: 1));

      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.restRemainingSeconds.value, isNull);
      expect(controller.currentSet.value, 2);
      controller.dispose();
    });
  });

  test(
    'plank: без «Начать» счётчик не запускается, после — растёт от нуля',
    () {
      fakeAsync((async) {
        final controller = WorkoutController(
          clock: () => startTime.add(async.elapsed),
        );
        controller.start([plankExercise(duration: 45)]);

        expect(controller.holdTargetSeconds.value, 45);
        expect(controller.holdRunning.value, isFalse);
        expect(controller.holdElapsedSeconds.value, 0);

        // Авто-старта нет: время не идёт, пока не нажата кнопка «Начать».
        async.elapse(const Duration(seconds: 10));
        expect(controller.holdRunning.value, isFalse);
        expect(controller.holdElapsedSeconds.value, 0);

        controller.startHoldTimer();
        expect(controller.holdRunning.value, isTrue);
        expect(controller.holdElapsedSeconds.value, 0);

        async.elapse(const Duration(seconds: 5));
        expect(controller.holdElapsedSeconds.value, 5);
        // Счёт продолжается и после достижения цели: пользователь может держать
        // планку дольше, и фактическое время попадёт в результат (задача 13.5).
        async.elapse(const Duration(seconds: 60));
        expect(controller.holdElapsedSeconds.value, 65);

        // Повторный запуск — не сбрасывает счётчик.
        controller.startHoldTimer();
        async.elapse(const Duration(seconds: 2));
        expect(controller.holdElapsedSeconds.value, 67);

        controller.dispose();
      });
    },
  );

  test('plank: фиксация подхода останавливает счётчик удержания', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([plankExercise(duration: 45)]);
      controller.startHoldTimer();

      controller.setResult(const WorkoutSetInput(durationSeconds: 40));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.finished);
      expect(controller.holdRunning.value, isFalse);
      expect(controller.holdTargetSeconds.value, isNull);
      expect(controller.holdElapsedSeconds.value, 0);
      expect(controller.results.value.single.durationSeconds, 40);
      expect(controller.results.value.single.exerciseName, 'Планка');
      expect(controller.results.value.single.setIndex, 1);

      async.elapse(const Duration(seconds: 100));
      expect(controller.holdTargetSeconds.value, isNull);
      expect(controller.holdElapsedSeconds.value, 0);
      controller.dispose();
    });
  });

  test('для не-планки счётчик и цель удержания не задаются', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([strengthExercise(sets: 1)]);

      expect(controller.holdTargetSeconds.value, isNull);
      expect(controller.holdElapsedSeconds.value, 0);
      expect(controller.holdRunning.value, isFalse);

      // Запуск для не-планки — без эффекта.
      controller.startHoldTimer();
      expect(controller.holdRunning.value, isFalse);

      async.elapse(const Duration(seconds: 5));
      expect(controller.holdElapsedSeconds.value, 0);
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

  test('bodyweight: фиксация повторов без веса', () {
    final controller = WorkoutController(clock: () => startTime);
    controller.start([bodyweightExercise(sets: 1)]);

    controller.setResult(const WorkoutSetInput(reps: 15));
    controller.confirmSet();

    expect(controller.phase.value, WorkoutPhase.finished);
    final result = controller.results.value.single;
    expect(result.exerciseType, ExerciseType.bodyweight);
    expect(result.reps, 15);
    expect(result.weightKg, isNull);
    expect(result.durationSeconds, isNull);
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

  test('отдых между упражнениями: по завершении переходит к следующему', () {
    fakeAsync((async) {
      final controller = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      controller.start(
        [strengthExercise(sets: 1), runningExercise()],
        context: const WorkoutSessionContext(
          programId: 5,
          programName: 'База',
          programDayId: 7,
          dayIndex: 2,
          exerciseRestSeconds: 90,
        ),
      );

      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.rest);
      expect(controller.restRemainingSeconds.value, 90);
      expect(controller.currentExerciseIndex.value, 0);

      async.elapse(const Duration(seconds: 90));
      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.restRemainingSeconds.value, isNull);
      expect(controller.currentExerciseIndex.value, 1);
      expect(controller.currentExercise!.name, 'Бег');
      expect(controller.currentSet.value, 1);
      controller.dispose();
    });
  });

  test('отдых между упражнениями: skipRest переходит к следующему', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start(
        [strengthExercise(sets: 1), runningExercise()],
        context: const WorkoutSessionContext(
          programId: 5,
          programName: 'База',
          programDayId: 7,
          dayIndex: 2,
          exerciseRestSeconds: 90,
        ),
      );

      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();
      expect(controller.phase.value, WorkoutPhase.rest);

      controller.skipRest();
      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.currentExerciseIndex.value, 1);
      expect(controller.currentExercise!.name, 'Бег');
      expect(controller.restRemainingSeconds.value, isNull);

      async.elapse(const Duration(seconds: 10));
      expect(controller.restRemainingSeconds.value, isNull);
      expect(controller.currentExerciseIndex.value, 1);
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

  test(
    'finishEarly из фазы exercise завершает тренировку с частичными результатами',
    () {
      fakeAsync((async) {
        final controller = WorkoutController(
          clock: () => startTime.add(async.elapsed),
        );
        controller.start([strengthExercise(sets: 3, rest: 0)]);

        controller.setResult(const WorkoutSetInput(reps: 8));
        controller.confirmSet();
        expect(controller.phase.value, WorkoutPhase.exercise);
        expect(controller.results.value, hasLength(1));

        controller.finishEarly();
        expect(controller.phase.value, WorkoutPhase.finished);

        final outcome = controller.completeWorkout();
        expect(outcome.results, hasLength(1));
        expect(outcome.results.first.reps, 8);
        expect(outcome.session.startedAt, startTime);
        controller.dispose();
      });
    },
  );

  test(
    'finishEarly из фазы rest завершает тренировку с частичными результатами',
    () {
      fakeAsync((async) {
        final controller = WorkoutController(
          clock: () => startTime.add(async.elapsed),
        );
        controller.start([strengthExercise(sets: 2, rest: 60)]);

        controller.setResult(const WorkoutSetInput(reps: 8));
        controller.confirmSet();
        expect(controller.phase.value, WorkoutPhase.rest);
        expect(controller.results.value, hasLength(1));

        controller.finishEarly();
        expect(controller.phase.value, WorkoutPhase.finished);

        final outcome = controller.completeWorkout();
        expect(outcome.results, hasLength(1));
        expect(outcome.results.first.reps, 8);
        controller.dispose();
      });
    },
  );

  test('finishEarly без результатов сохраняет пустую сессию', () {
    fakeAsync((async) {
      final controller = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      controller.start([strengthExercise(sets: 2, rest: 60)]);

      controller.finishEarly();
      expect(controller.phase.value, WorkoutPhase.finished);

      final outcome = controller.completeWorkout();
      expect(outcome.results, isEmpty);
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
    var now = startTime;
    final timers = <_FakeTimer>[];
    final controller = WorkoutController(
      clock: () => now,
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

    // Остаток пересчитывается от времени окончания, а не декрементируется.
    now = startTime.add(const Duration(seconds: 59));
    timers[0].fire();
    expect(controller.restRemainingSeconds.value, 1);

    now = startTime.add(const Duration(seconds: 60));
    timers[0].fire();
    expect(controller.restRemainingSeconds.value, isNull);
    expect(controller.phase.value, WorkoutPhase.exercise);
    controller.dispose();
  });

  test('при завершении отдыха играет звуковой сигнал', () {
    var now = startTime;
    final sound = StubSoundService();
    final timers = <_FakeTimer>[];
    final controller = WorkoutController(
      clock: () => now,
      soundService: sound,
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

    now = startTime.add(const Duration(seconds: 60));
    timers[0].fire();
    expect(sound.completionCalls, 1);
    controller.dispose();
  });

  test('stale-таймер после повторного start не срабатывает', () {
    final sound = StubSoundService();
    final timers = <_FakeTimer>[];
    final controller = WorkoutController(
      clock: () => startTime,
      soundService: sound,
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
    expect(controller.phase.value, WorkoutPhase.rest);
    expect(timers, hasLength(1));
    final staleTimer = timers[0];

    // Перезапуск сессии: старый тикер отменён, поколение сменено.
    controller.start([strengthExercise(sets: 2, rest: 60)]);
    expect(controller.phase.value, WorkoutPhase.exercise);

    // Запоздалое срабатывание старого тикера должно быть no-op.
    final completionCallsBefore = sound.completionCalls;
    staleTimer.fire();
    expect(controller.phase.value, WorkoutPhase.exercise);
    expect(sound.completionCalls, completionCallsBefore);
    controller.dispose();
  });

  test('инжектируемый timerFactory управляет удержанием планки', () {
    var now = startTime;
    final timers = <_FakeTimer>[];
    final controller = WorkoutController(
      clock: () => now,
      timerFactory: (duration, callback) {
        late final _FakeTimer timer;
        timer = _FakeTimer(() => callback(timer));
        timers.add(timer);
        return timer;
      },
    );
    controller.start([plankExercise(duration: 45)]);

    // Авто-старта нет — таймер создаётся только после «Начать».
    expect(timers, isEmpty);
    expect(controller.holdTargetSeconds.value, 45);
    expect(controller.holdElapsedSeconds.value, 0);
    expect(controller.holdRunning.value, isFalse);

    controller.startHoldTimer();
    expect(timers, hasLength(1));
    expect(controller.holdRunning.value, isTrue);

    now = startTime.add(const Duration(seconds: 50));
    timers[0].fire();
    expect(controller.holdElapsedSeconds.value, 50);
    controller.dispose();
  });

  test(
    'plank: удержание считается по wall-clock и не замирает после «сна»',
    () {
      fakeAsync((async) {
        var now = startTime;
        final controller = WorkoutController(clock: () => now);
        controller.start([plankExercise(duration: 45)]);
        controller.startHoldTimer();

        now = startTime.add(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 1));
        expect(controller.holdElapsedSeconds.value, 10);

        // Имитация сна: прошло ещё 2 минуты, тик не срабатывал.
        now = startTime.add(const Duration(seconds: 130));
        async.elapse(const Duration(seconds: 1));
        expect(controller.holdElapsedSeconds.value, 130);
        controller.dispose();
      });
    },
  );

  test('по сторонам: левая → отдых между сторонами → правая', () {
    fakeAsync((async) {
      final controller = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      controller.start([perSideExercise(sets: 1, rest: 60)]);

      controller.setResult(const WorkoutSetInput(reps: 8, weightKg: 20));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.rest);
      expect(controller.sideRest.value, 60);
      expect(controller.restRemainingSeconds.value, isNull);
      expect(controller.currentSide.value, 'right');
      expect(controller.completedSets.value, 0);
      expect(controller.results.value.single.side, 'left');

      async.elapse(const Duration(seconds: 60));
      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.sideRest.value, isNull);
      expect(controller.currentSide.value, 'right');

      controller.setResult(const WorkoutSetInput(reps: 6, weightKg: 22));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.finished);
      expect(controller.completedSets.value, 1);
      expect(controller.results.value, hasLength(2));
      expect(controller.results.value[0].side, 'left');
      expect(controller.results.value[1].side, 'right');
      expect(controller.results.value[1].weightKg, 22);
      expect(controller.currentSide.value, isNull);
      controller.dispose();
    });
  });

  test('по сторонам: skipRest переводит к правой стороне без завершения', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([perSideExercise(sets: 1, rest: 60)]);
      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.rest);
      controller.skipRest();

      expect(controller.phase.value, WorkoutPhase.exercise);
      expect(controller.sideRest.value, isNull);
      expect(controller.currentSide.value, 'right');

      controller.setResult(const WorkoutSetInput(reps: 6));
      controller.confirmSet();
      expect(controller.phase.value, WorkoutPhase.finished);
      expect(controller.results.value.map((r) => r.side), ['left', 'right']);
      controller.dispose();
    });
  });

  test('обычное упражнение не записывает сторону', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([strengthExercise(sets: 1, rest: 60)]);
      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();

      expect(controller.phase.value, WorkoutPhase.finished);
      expect(controller.results.value.single.side, isNull);
      expect(controller.currentSide.value, isNull);
      controller.dispose();
    });
  });

  test('по сторонам: 2 подхода — два цикла левая/правая', () {
    fakeAsync((async) {
      final controller = WorkoutController(clock: () => startTime);
      controller.start([perSideExercise(sets: 2, rest: 60)]);

      for (var set = 1; set <= 2; set++) {
        controller.setResult(const WorkoutSetInput(reps: 8));
        controller.confirmSet();
        expect(controller.currentSide.value, 'right');
        expect(controller.sideRest.value, 60);
        controller.skipRest();

        controller.setResult(const WorkoutSetInput(reps: 6));
        controller.confirmSet();
        if (set < 2) {
          expect(controller.phase.value, WorkoutPhase.rest);
          expect(controller.restRemainingSeconds.value, 60);
          expect(controller.currentSet.value, set + 1);
          controller.skipRest();
        } else {
          expect(controller.phase.value, WorkoutPhase.finished);
        }
      }
      expect(controller.results.value, hasLength(4));
      expect(controller.results.value.map((r) => r.side), [
        'left',
        'right',
        'left',
        'right',
      ]);
      expect(controller.results.value.map((r) => r.setIndex), [1, 1, 2, 2]);
      controller.dispose();
    });
  });

  test('checkpoint round-trip: toCheckpoint → restoreFromCheckpoint', () {
    fakeAsync((async) {
      final controller = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      controller.start(
        [strengthExercise(sets: 2, rest: 60), runningExercise()],
        context: const WorkoutSessionContext(
          programId: 5,
          programName: 'База',
          programDayId: 7,
          dayIndex: 2,
        ),
      );

      controller.setResult(const WorkoutSetInput(reps: 8, weightKg: 20));
      controller.confirmSet();
      async.elapse(const Duration(seconds: 60));
      controller.setResult(const WorkoutSetInput(reps: 6, weightKg: 25));
      controller.confirmSet();
      expect(controller.currentExerciseIndex.value, 1);
      expect(controller.currentSet.value, 1);
      expect(controller.completedSets.value, 2);

      final checkpoint = controller.toCheckpoint(
        programDayId: 7,
        programId: 5,
        programName: 'База',
        dayIndex: 2,
      );

      final restored = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      final exercises = [
        strengthExercise(sets: 2, rest: 60),
        runningExercise(),
      ];
      restored.restoreFromCheckpoint(checkpoint, exercises);

      expect(restored.phase.value, WorkoutPhase.exercise);
      expect(restored.currentExerciseIndex.value, 1);
      expect(restored.currentSet.value, 1);
      expect(restored.completedSets.value, 2);
      expect(restored.results.value, hasLength(2));
      expect(restored.results.value[0].reps, 8);
      expect(restored.results.value[0].weightKg, 20);
      expect(restored.results.value[1].reps, 6);
      expect(restored.results.value[1].weightKg, 25);
      expect(restored.currentExercise!.name, 'Бег');

      controller.dispose();
      restored.dispose();
    });
  });

  test('checkpoint round-trip: mid-set в одном упражнении', () {
    fakeAsync((async) {
      final controller = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      controller.start(
        [strengthExercise(sets: 3, rest: 60)],
        context: const WorkoutSessionContext(programName: 'Тест', dayIndex: 0),
      );

      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();
      async.elapse(const Duration(seconds: 60));
      expect(controller.currentSet.value, 2);

      final checkpoint = controller.toCheckpoint(
        programDayId: 1,
        programName: 'Тест',
        dayIndex: 0,
      );

      final restored = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      restored.restoreFromCheckpoint(checkpoint, [
        strengthExercise(sets: 3, rest: 60),
      ]);

      expect(restored.currentExerciseIndex.value, 0);
      expect(restored.currentSet.value, 2);
      expect(restored.completedSets.value, 1);
      expect(restored.results.value, hasLength(1));

      controller.dispose();
      restored.dispose();
    });
  });

  test(
    'checkpoint round-trip: отдых восстанавливается с остатком по wall-clock',
    () {
      fakeAsync((async) {
        var now = startTime;
        final controller = WorkoutController(clock: () => now);
        controller.start(
          [strengthExercise(sets: 2, rest: 60)],
          context: const WorkoutSessionContext(
            programName: 'База',
            dayIndex: 0,
          ),
        );
        controller.setResult(const WorkoutSetInput(reps: 8));
        controller.confirmSet();
        expect(controller.phase.value, WorkoutPhase.rest);
        expect(controller.restRemainingSeconds.value, 60);

        now = startTime.add(const Duration(seconds: 10));
        final checkpoint = controller.toCheckpoint(
          programDayId: 1,
          programName: 'База',
          dayIndex: 0,
        );
        expect(checkpoint.phase, 'rest');
        expect(checkpoint.restEndsAt, isNotNull);
        expect(checkpoint.restBetweenExercises, isFalse);

        now = startTime.add(const Duration(seconds: 30));
        final restored = WorkoutController(clock: () => now);
        restored.restoreFromCheckpoint(checkpoint, [
          strengthExercise(sets: 2, rest: 60),
        ]);
        expect(restored.phase.value, WorkoutPhase.rest);
        expect(restored.restRemainingSeconds.value, 30);

        now = startTime.add(const Duration(seconds: 60));
        async.elapse(const Duration(seconds: 1));
        expect(restored.phase.value, WorkoutPhase.exercise);
        expect(restored.restRemainingSeconds.value, isNull);
        expect(restored.currentSet.value, 2);

        controller.dispose();
        restored.dispose();
      });
    },
  );

  test('checkpoint round-trip: отдых между упражнениями восстанавливается', () {
    fakeAsync((async) {
      var now = startTime;
      final controller = WorkoutController(clock: () => now);
      controller.start(
        [strengthExercise(sets: 1), runningExercise()],
        context: const WorkoutSessionContext(
          programId: 5,
          programName: 'База',
          programDayId: 7,
          dayIndex: 2,
          exerciseRestSeconds: 90,
        ),
      );
      controller.setResult(const WorkoutSetInput(reps: 8));
      controller.confirmSet();
      expect(controller.phase.value, WorkoutPhase.rest);
      expect(controller.restRemainingSeconds.value, 90);

      now = startTime.add(const Duration(seconds: 20));
      final checkpoint = controller.toCheckpoint(
        programDayId: 7,
        programId: 5,
        programName: 'База',
        dayIndex: 2,
      );
      expect(checkpoint.restBetweenExercises, isTrue);

      now = startTime.add(const Duration(seconds: 50));
      final restored = WorkoutController(clock: () => now);
      restored.restoreFromCheckpoint(checkpoint, [
        strengthExercise(sets: 1),
        runningExercise(),
      ]);
      expect(restored.phase.value, WorkoutPhase.rest);
      expect(restored.restRemainingSeconds.value, 40);

      now = startTime.add(const Duration(seconds: 90));
      async.elapse(const Duration(seconds: 1));
      expect(restored.phase.value, WorkoutPhase.exercise);
      expect(restored.currentExerciseIndex.value, 1);
      expect(restored.currentExercise!.name, 'Бег');

      controller.dispose();
      restored.dispose();
    });
  });

  test('checkpoint round-trip: отдых между сторонами восстанавливается', () {
    fakeAsync((async) {
      var now = startTime;
      final controller = WorkoutController(clock: () => now);
      controller.start([perSideExercise(sets: 1, rest: 60)]);
      controller.setResult(const WorkoutSetInput(reps: 8, weightKg: 20));
      controller.confirmSet();
      expect(controller.phase.value, WorkoutPhase.rest);
      expect(controller.sideRest.value, 60);
      expect(controller.currentSide.value, 'right');

      now = startTime.add(const Duration(seconds: 15));
      final checkpoint = controller.toCheckpoint(
        programDayId: 1,
        programName: 'База',
        dayIndex: 0,
      );
      expect(checkpoint.sideRest, isTrue);

      now = startTime.add(const Duration(seconds: 40));
      final restored = WorkoutController(clock: () => now);
      restored.restoreFromCheckpoint(checkpoint, [
        perSideExercise(sets: 1, rest: 60),
      ]);
      expect(restored.phase.value, WorkoutPhase.rest);
      expect(restored.sideRest.value, 20);
      expect(restored.currentSide.value, 'right');

      now = startTime.add(const Duration(seconds: 60));
      async.elapse(const Duration(seconds: 1));
      expect(restored.phase.value, WorkoutPhase.exercise);
      expect(restored.sideRest.value, isNull);
      expect(restored.currentSide.value, 'right');

      restored.setResult(const WorkoutSetInput(reps: 6));
      restored.confirmSet();
      expect(restored.phase.value, WorkoutPhase.finished);

      controller.dispose();
      restored.dispose();
    });
  });

  test('checkpoint round-trip: удержание планки восстанавливается', () {
    fakeAsync((async) {
      final controller = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      controller.start([plankExercise(duration: 45)]);
      controller.startHoldTimer();
      async.elapse(const Duration(seconds: 12));
      expect(controller.holdElapsedSeconds.value, 12);

      final checkpoint = controller.toCheckpoint(
        programDayId: 1,
        programName: 'Планка',
        dayIndex: 0,
      );
      expect(checkpoint.holdRunning, isTrue);
      expect(checkpoint.holdElapsedSeconds, 12);

      final restored = WorkoutController(
        clock: () => startTime.add(async.elapsed),
      );
      restored.restoreFromCheckpoint(checkpoint, [plankExercise(duration: 45)]);
      expect(restored.holdRunning.value, isTrue);
      expect(restored.holdElapsedSeconds.value, 12);
      expect(restored.holdTargetSeconds.value, 45);

      async.elapse(const Duration(seconds: 5));
      expect(restored.holdElapsedSeconds.value, 17);

      controller.dispose();
      restored.dispose();
    });
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
