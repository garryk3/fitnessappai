import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = ProgramRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Program program({
    int? id,
    String name = 'Программа',
    int daysCount = 1,
    int? exerciseRestSeconds,
  }) => Program(
    id: id,
    name: name,
    description: 'Описание',
    daysCount: daysCount,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
    exerciseRestSeconds: exerciseRestSeconds,
  );

  ProgramDay day({
    int? id,
    int programId = 0,
    int dayIndex = 0,
    int? dayOfWeek,
    int? warmupMinutes,
  }) => ProgramDay(
    id: id,
    programId: programId,
    dayIndex: dayIndex,
    dayOfWeek: dayOfWeek,
    warmupMinutes: warmupMinutes,
  );

  ProgramDayExercise item({
    int? id,
    int dayId = 0,
    int? exerciseId,
    int orderIndex = 0,
    bool isAlternative = false,
    int? sets = 3,
    int? reps = 10,
    int? durationSeconds,
    int? restSeconds,
    double? weightKg,
    double? distanceMeters,
  }) => ProgramDayExercise(
    id: id,
    dayId: dayId,
    exerciseId: exerciseId,
    orderIndex: orderIndex,
    isAlternative: isAlternative,
    sets: sets,
    reps: reps,
    durationSeconds: durationSeconds,
    restSeconds: restSeconds,
    weightKg: weightKg,
    distanceMeters: distanceMeters,
  );

  Future<int> insertExercise({
    String name = 'Жим штанги',
    ExerciseType type = ExerciseType.strength,
  }) async {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: name,
            type: type,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
  }

  Future<Program> createProgram({int daysCount = 1}) async {
    return repo.create(program(daysCount: daysCount), [
      for (var i = 0; i < daysCount; i++) day(dayIndex: i),
    ]);
  }

  group('CRUD', () {
    test('create сохраняет программу с днями атомарно', () async {
      final created = await repo.create(program(daysCount: 2), [
        day(dayIndex: 0, dayOfWeek: 1),
        day(dayIndex: 1, dayOfWeek: 4),
      ]);
      expect(created.id, isNotNull);
      expect(created.daysCount, 2);

      final fromDb = await repo.getById(created.id!);
      expect(fromDb, created);

      final days = await repo.getDays(created.id!);
      expect(days, hasLength(2));
      expect(days[0].dayIndex, 0);
      expect(days[0].dayOfWeek, 1);
      expect(days[1].dayIndex, 1);
      expect(days[1].dayOfWeek, 4);
    });

    test('getById возвращает null для отсутствующего id', () async {
      expect(await repo.getById(999), isNull);
    });

    test('getProgram возвращает null для отсутствующего id', () async {
      expect(await repo.getProgram(999), isNull);
    });

    test('create/update сохраняет exerciseRestSeconds', () async {
      final created = await repo.create(
        program(daysCount: 1, exerciseRestSeconds: 90),
        [day(dayIndex: 0)],
      );
      expect(created.exerciseRestSeconds, 90);
      expect((await repo.getById(created.id!))!.exerciseRestSeconds, 90);

      final updated = await repo.update(
        created.copyWith(exerciseRestSeconds: 45),
      );
      expect(updated.exerciseRestSeconds, 45);
      expect((await repo.getById(created.id!))!.exerciseRestSeconds, 45);
    });

    test('getPrograms сортирует по названию и считает упражнения', () async {
      final p1 = await repo.create(program(name: 'Альфа'), [day(dayIndex: 0)]);
      await repo.create(program(name: 'Бета', daysCount: 1), [
        day(dayIndex: 0),
      ]);
      final exId = await insertExercise();
      final dayRow = (await repo.getDays(p1.id!)).single;
      await repo.addExerciseToDay(dayRow.id!, exId);

      final summaries = await repo.getPrograms();
      expect(summaries.map((s) => s.program.name), ['Альфа', 'Бета']);
      expect(summaries.first.exercisesCount, 1);
      expect(summaries.last.exercisesCount, 0);
    });

    test('update изменяет поля программы', () async {
      final created = await createProgram();
      final updated = await repo.update(
        created.copyWith(name: 'Новое имя', description: 'Новое описание'),
      );
      expect(updated.name, 'Новое имя');
      expect(updated.description, 'Новое описание');
      expect((await repo.getById(created.id!))!.name, 'Новое имя');
    });

    test('update с isActive: true сохраняет активность программы', () async {
      final created = await repo.create(program(daysCount: 1), [day()]);
      await repo.setActive(created.id!);
      expect((await repo.getActiveProgram())!.id, created.id);

      final updated = await repo.update(
        created.copyWith(name: 'Новое имя', isActive: true),
      );
      expect(updated.isActive, isTrue);
      expect((await repo.getActiveProgram())!.id, created.id);
    });

    test('update с днями заменяет дни', () async {
      final created = await repo.create(program(daysCount: 2), [
        day(dayIndex: 0),
        day(dayIndex: 1),
      ]);
      await repo.update(
        created.copyWith(daysCount: 1),
        days: [day(dayIndex: 0, dayOfWeek: 2)],
      );
      final days = await repo.getDays(created.id!);
      expect(days, hasLength(1));
      expect(days.single.dayOfWeek, 2);
    });

    test(
      'update с днями сохраняет id существующих дней и их упражнения',
      () async {
        final created = await repo.create(program(daysCount: 2), [
          day(dayIndex: 0, dayOfWeek: 1),
          day(dayIndex: 1),
        ]);
        final originalDays = await repo.getDays(created.id!);
        final exId = await insertExercise();
        await repo.addExerciseToDay(originalDays[0].id!, exId);

        await repo.update(
          created,
          days: [
            day(dayIndex: 0, dayOfWeek: 3),
            day(dayIndex: 1, dayOfWeek: 5),
          ],
        );

        final days = await repo.getDays(created.id!);
        expect(days.map((d) => d.id), originalDays.map((d) => d.id));
        expect(days[0].dayOfWeek, 3);
        expect(days[1].dayOfWeek, 5);

        final exercises = await repo.getExercises(originalDays[0].id!);
        expect(exercises, hasLength(1));
        expect(exercises.single.exerciseId, exId);
      },
    );

    test('update с днями сохраняет warmupMinutes', () async {
      final created = await repo.create(program(daysCount: 1), [day()]);
      await repo.update(
        created.copyWith(daysCount: 1),
        days: [day(dayIndex: 0, warmupMinutes: 5)],
      );
      final days = await repo.getDays(created.id!);
      expect(days.single.warmupMinutes, 5);
    });

    test('updateDay сохраняет warmupMinutes', () async {
      final created = await repo.create(program(daysCount: 1), [
        day(dayIndex: 0),
      ]);
      final original = (await repo.getDays(created.id!)).single;
      final updated = await repo.updateDay(
        original.copyWith(warmupMinutes: 10),
      );
      expect(updated.warmupMinutes, 10);
      expect((await repo.getDays(created.id!)).single.warmupMinutes, 10);
    });

    test('update с днями вставляет новые и удаляет отсутствующие', () async {
      final created = await repo.create(program(daysCount: 2), [
        day(dayIndex: 0),
        day(dayIndex: 1),
      ]);
      final originalDays = await repo.getDays(created.id!);

      await repo.update(
        created.copyWith(daysCount: 2),
        days: [day(dayIndex: 0), day(dayIndex: 2, dayOfWeek: 6)],
      );

      final days = await repo.getDays(created.id!);
      expect(days, hasLength(2));
      expect(days[0].id, originalDays[0].id);
      expect(days[1].dayIndex, 2);
      expect(days[1].dayOfWeek, 6);
      expect(days[1].id, isNot(originalDays[1].id));
    });

    test('delete удаляет программу с днями и упражнениями (cascade)', () async {
      final created = await createProgram();
      final exId = await insertExercise();
      final dayRow = (await repo.getDays(created.id!)).single;
      await repo.addExerciseToDay(dayRow.id!, exId);

      await repo.delete(created.id!);

      expect(await repo.getById(created.id!), isNull);
      expect(await repo.getDays(created.id!), isEmpty);
      expect(await db.select(db.programDayExercises).get(), isEmpty);
    });
  });

  group('дни', () {
    test('addDay вставляет на позицию и сдвигает следующие', () async {
      final created = await repo.create(program(daysCount: 2), [
        day(dayIndex: 0),
        day(dayIndex: 1),
      ]);
      final added = await repo.addDay(created.id!, dayIndex: 1, dayOfWeek: 3);
      expect(added.dayIndex, 1);
      expect(added.dayOfWeek, 3);
      expect(added.id, isNotNull);

      final days = await repo.getDays(created.id!);
      expect(days.map((d) => d.dayIndex), [0, 1, 2]);
      expect((await repo.getById(created.id!))!.daysCount, 3);
    });

    test('updateDay изменяет день недели и индекс', () async {
      final created = await createProgram();
      final dayRow = (await repo.getDays(created.id!)).single;
      final updated = await repo.updateDay(
        dayRow.copyWith(dayIndex: 5, dayOfWeek: 7),
      );
      expect(updated.dayIndex, 5);
      expect(updated.dayOfWeek, 7);
    });

    test('removeDay удаляет день и переиндексирует остальные', () async {
      final created = await repo.create(program(daysCount: 3), [
        day(dayIndex: 0, dayOfWeek: 1),
        day(dayIndex: 1, dayOfWeek: 2),
        day(dayIndex: 2, dayOfWeek: 3),
      ]);
      final days = await repo.getDays(created.id!);
      await repo.removeDay(days[1].id!);

      final remaining = await repo.getDays(created.id!);
      expect(remaining.map((d) => d.dayIndex), [0, 1]);
      expect(remaining.map((d) => d.dayOfWeek), [1, 3]);
      expect((await repo.getById(created.id!))!.daysCount, 2);
    });

    test('reorderDays переиндексирует дни в заданном порядке', () async {
      final created = await repo.create(program(daysCount: 3), [
        day(dayIndex: 0),
        day(dayIndex: 1),
        day(dayIndex: 2),
      ]);
      var days = await repo.getDays(created.id!);
      await repo.reorderDays(created.id!, [
        days[2].id!,
        days[0].id!,
        days[1].id!,
      ]);

      days = await repo.getDays(created.id!);
      expect(days.map((d) => d.dayIndex), [0, 1, 2]);
    });
  });

  group('упражнения', () {
    test('addExerciseToDay добавляет в конец основного набора', () async {
      final created = await createProgram();
      final dayRow = (await repo.getDays(created.id!)).single;
      final ex1 = await insertExercise(name: 'Жим');
      final ex2 = await insertExercise(name: 'Разводка');

      final first = await repo.addExerciseToDay(dayRow.id!, ex1);
      final second = await repo.addExerciseToDay(dayRow.id!, ex2);
      expect(first.orderIndex, 0);
      expect(second.orderIndex, 1);

      final items = await repo.getExercises(dayRow.id!);
      expect(items.map((e) => e.exerciseId), [ex1, ex2]);
    });

    test(
      'addExerciseToDay с isAlternative кладёт в альтернативный набор',
      () async {
        final created = await createProgram();
        final dayRow = (await repo.getDays(created.id!)).single;
        final exId = await insertExercise();

        await repo.addExerciseToDay(dayRow.id!, exId);
        final alt = await repo.addExerciseToDay(
          dayRow.id!,
          exId,
          isAlternative: true,
        );
        expect(alt.isAlternative, isTrue);

        final detail = await repo.getProgram(created.id!);
        final dayDetail = detail!.days.single;
        expect(dayDetail.mainExercises, hasLength(1));
        expect(dayDetail.alternativeExercises, hasLength(1));
        expect(dayDetail.alternativeExercises.single.isAlternative, isTrue);
      },
    );

    test('updateExercise сохраняет метрики', () async {
      final created = await createProgram();
      final dayRow = (await repo.getDays(created.id!)).single;
      final exId = await insertExercise();
      final item = await repo.addExerciseToDay(dayRow.id!, exId);

      final updated = await repo.updateExercise(
        item.copyWith(sets: 5, reps: 8, weightKg: 60, restSeconds: 90),
      );
      expect(updated.sets, 5);
      expect(updated.reps, 8);
      expect(updated.weightKg, 60);
      expect(updated.restSeconds, 90);
    });

    test('updateExercise отклоняет невалидные метрики по типу', () async {
      final created = await createProgram();
      final dayRow = (await repo.getDays(created.id!)).single;
      final exId = await insertExercise();
      final item = await repo.addExerciseToDay(dayRow.id!, exId);

      await expectLater(
        repo.updateExercise(item.copyWith(reps: 0)),
        throwsA(isA<ProgramValidationException>()),
      );
    });

    test('updateExercise валидирует планку по времени', () async {
      final created = await createProgram();
      final dayRow = (await repo.getDays(created.id!)).single;
      final exId = await insertExercise(
        name: 'Планка',
        type: ExerciseType.plank,
      );
      final item = await repo.addExerciseToDay(dayRow.id!, exId);

      await expectLater(
        repo.updateExercise(
          item.copyWith(sets: 1, durationSeconds: null, weightKg: null),
        ),
        throwsA(isA<ProgramValidationException>()),
      );
      final updated = await repo.updateExercise(
        item.copyWith(sets: 1, durationSeconds: 30, weightKg: null),
      );
      expect(updated.durationSeconds, 30);
    });

    test('removeExercise удаляет позицию', () async {
      final created = await createProgram();
      final dayRow = (await repo.getDays(created.id!)).single;
      final exId = await insertExercise();
      final item = await repo.addExerciseToDay(dayRow.id!, exId);

      await repo.removeExercise(item.id!);

      expect(await repo.getExercises(dayRow.id!), isEmpty);
    });

    test('reorderExercises переиндексирует позиции', () async {
      final created = await createProgram();
      final dayRow = (await repo.getDays(created.id!)).single;
      final ex1 = await insertExercise(name: 'Жим');
      final ex2 = await insertExercise(name: 'Разводка');
      final ex3 = await insertExercise(name: 'Отжимания');
      final a = await repo.addExerciseToDay(dayRow.id!, ex1);
      final b = await repo.addExerciseToDay(dayRow.id!, ex2);
      final c = await repo.addExerciseToDay(dayRow.id!, ex3);

      await repo.reorderExercises(dayRow.id!, [c.id!, a.id!, b.id!]);

      final items = await repo.getExercises(dayRow.id!);
      expect(items.map((e) => e.orderIndex), [0, 1, 2]);
      expect(items.map((e) => e.id), [c.id, a.id, b.id]);
    });
  });

  group('обновление упражнений по индексам дней', () {
    test('update с exercisesByDayIndex заменяет упражнения', () async {
      final created = await repo.create(program(daysCount: 1), [
        day(dayIndex: 0),
      ]);
      final dayRow = (await repo.getDays(created.id!)).single;
      final exId = await insertExercise();
      await repo.addExerciseToDay(dayRow.id!, exId);

      final updated = await repo.update(
        created,
        exercisesByDayIndex: {
          0: [item(orderIndex: 0, exerciseId: exId, sets: 4, reps: 6)],
        },
      );
      expect(updated.id, created.id);
      final items = await repo.getExercises(dayRow.id!);
      expect(items, hasLength(1));
      expect(items.single.sets, 4);
      expect(items.single.reps, 6);
    });

    test('update отклоняет структуру без основного упражнения', () async {
      final created = await createProgram();
      await expectLater(
        repo.update(
          created,
          exercisesByDayIndex: {
            0: [item(orderIndex: 0, isAlternative: true)],
          },
        ),
        throwsA(isA<ProgramValidationException>()),
      );
    });
  });

  group('валидация структуры', () {
    test('create отклоняет пустое название', () async {
      await expectLater(
        repo.create(program(name: '   '), [day(dayIndex: 0)]),
        throwsA(isA<ProgramValidationException>()),
      );
    });

    test('create отклоняет несовпадение daysCount', () async {
      await expectLater(
        repo.create(program(daysCount: 2), [day(dayIndex: 0)]),
        throwsA(isA<ProgramValidationException>()),
      );
    });

    test('create отклоняет дублирующиеся индексы дней', () async {
      await expectLater(
        repo.create(program(daysCount: 2), [
          day(dayIndex: 0),
          day(dayIndex: 0),
        ]),
        throwsA(isA<ProgramValidationException>()),
      );
    });

    test('create отклоняет количество дней вне 1–7', () async {
      await expectLater(
        repo.create(program(daysCount: 8), [
          for (var i = 0; i < 8; i++) day(dayIndex: i),
        ]),
        throwsA(isA<ProgramValidationException>()),
      );
    });
  });

  group('предупреждения о противопоказаниях', () {
    test('isWarningDismissed без отметки false, после dismiss true', () async {
      final created = await repo.create(program(), [day(dayIndex: 0)]);

      expect(await repo.isWarningDismissed(created.id!), isFalse);

      await repo.dismissWarnings(created.id!);

      expect(await repo.isWarningDismissed(created.id!), isTrue);
    });

    test('повторный dismiss не ломает отметку', () async {
      final created = await repo.create(program(), [day(dayIndex: 0)]);

      await repo.dismissWarnings(created.id!);
      await repo.dismissWarnings(created.id!);

      expect(await repo.isWarningDismissed(created.id!), isTrue);
    });

    test('отметки разных программ независимы', () async {
      final first = await repo.create(program(), [day(dayIndex: 0)]);
      final second = await repo.create(program(name: 'Вторая'), [
        day(dayIndex: 0),
      ]);

      await repo.dismissWarnings(first.id!);

      expect(await repo.isWarningDismissed(first.id!), isTrue);
      expect(await repo.isWarningDismissed(second.id!), isFalse);
    });

    test('отметка каскадно удаляется при удалении программы', () async {
      final created = await repo.create(program(), [day(dayIndex: 0)]);
      await repo.dismissWarnings(created.id!);

      await repo.delete(created.id!);

      expect(await repo.isWarningDismissed(created.id!), isFalse);
    });
  });

  group('активная программа', () {
    test('getActiveProgram возвращает null, пока ни одна не активна', () async {
      await repo.create(program(), [day(dayIndex: 0)]);

      expect(await repo.getActiveProgram(), isNull);
    });

    test('setActive помечает программу, не снимая остальные', () async {
      final first = await repo.create(program(), [day(dayIndex: 0)]);
      final second = await repo.create(program(name: 'Вторая'), [
        day(dayIndex: 0),
      ]);

      await repo.setActive(first.id!);
      expect((await repo.getById(first.id!))!.isActive, isTrue);
      expect((await repo.getById(second.id!))!.isActive, isFalse);

      await repo.setActive(second.id!);
      expect((await repo.getById(first.id!))!.isActive, isTrue);
      expect((await repo.getById(second.id!))!.isActive, isTrue);

      final active = await repo.getActivePrograms();
      expect(active, hasLength(2));
    });

    test('setActive уведомляет подписчиков', () async {
      final changes = DataChangeNotifier();
      final notifyingRepo = ProgramRepository(db, changes: changes);
      final created = await notifyingRepo.create(program(), [day(dayIndex: 0)]);
      var notifications = 0;
      void onChanged() => notifications++;
      changes.addListener(onChanged);

      await notifyingRepo.setActive(created.id!);

      expect(notifications, greaterThan(0));
      changes.removeListener(onChanged);
    });

    test('setActive фиксирует активацию, deactivate закрывает период', () async {
      final created = await repo.create(program(), [day(dayIndex: 0)]);
      final now = DateTime.now();

      await repo.setActive(created.id!);
      final activated = (await repo.getById(created.id!))!;
      expect(activated.isActive, isTrue);
      expect(activated.activatedAt, isNotNull);
      expect(
        activated.activatedAt!.isAfter(
          now.subtract(const Duration(minutes: 2)),
        ),
        isTrue,
      );
      expect(activated.deactivatedAt, isNull);

      await repo.deactivate(created.id!);
      final deactivated = (await repo.getById(created.id!))!;
      expect(deactivated.isActive, isFalse);
      expect(deactivated.deactivatedAt, isNotNull);
      expect(
        deactivated.deactivatedAt!.isBefore(
          DateTime.now().add(const Duration(minutes: 2)),
        ),
        isTrue,
      );

      // Повторная активация сбрасывает период деактивации и ставит новую дату.
      await repo.setActive(created.id!);
      final reactivated = (await repo.getById(created.id!))!;
      expect(reactivated.isActive, isTrue);
      expect(reactivated.deactivatedAt, isNull);
      expect(
        reactivated.activatedAt!.isAfter(
          now.subtract(const Duration(minutes: 2)),
        ),
        isTrue,
      );
    });

    test('reorderDaysByDayOfWeek сортирует дни по порядку недели', () async {
      final created = await repo.create(program(daysCount: 3), [
        day(dayIndex: 0, dayOfWeek: 5),
        day(dayIndex: 1, dayOfWeek: 3),
        day(dayIndex: 2, dayOfWeek: 1),
      ]);

      await repo.reorderDaysByDayOfWeek(created.id!);

      final days = await repo.getDays(created.id!);
      expect(days, hasLength(3));
      expect(days[0].dayOfWeek, 1);
      expect(days[0].dayIndex, 0);
      expect(days[1].dayOfWeek, 3);
      expect(days[1].dayIndex, 1);
      expect(days[2].dayOfWeek, 5);
      expect(days[2].dayIndex, 2);
    });

    test(
      'reorderDaysByDayOfWeek: непривязанные дни остаются в конце',
      () async {
        final created = await repo.create(program(daysCount: 3), [
          day(dayIndex: 0, dayOfWeek: null),
          day(dayIndex: 1, dayOfWeek: 5),
          day(dayIndex: 2, dayOfWeek: 1),
        ]);

        await repo.reorderDaysByDayOfWeek(created.id!);

        final days = await repo.getDays(created.id!);
        expect(days[0].dayOfWeek, 1);
        expect(days[0].dayIndex, 0);
        expect(days[1].dayOfWeek, 5);
        expect(days[1].dayIndex, 1);
        expect(days[2].dayOfWeek, isNull);
        expect(days[2].dayIndex, 2);
      },
    );
  });
}
