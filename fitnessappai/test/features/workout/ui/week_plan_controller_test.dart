import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_cleanup.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';

void main() {
  late AppDatabase db;
  late WeekPlanController controller;
  late ProgramRepository programRepo;
  late PlanScheduleRepository scheduleRepo;

  DateTime fixedNow() => DateTime(2026, 8, 10);

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    scheduleRepo = PlanScheduleRepository(db);
    controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: WorkoutRepository(db),
      planScheduleRepository: scheduleRepo,
      clock: fixedNow,
    );
  });

  tearDown(() async {
    // Конструктор контроллера запускает загрузку без await — дожидаемся её
    // перед закрытием БД, иначе запросы падают на закрытом соединении.
    await pumpEventQueue();
    controller.dispose();
    await db.close();
  });

  /// Ставит отметку переноса так, как это теперь делает экран выполнения
  /// (задача 48.4): напрямую в репозитории, а не из плана, — и перечитывает
  /// план, потому что вне `WeekPlanController` уведомления об изменении данных
  /// никто не ждёт.
  Future<void> markRescheduled(WeekPlanItem item) async {
    await WorkoutRepository(
      db,
    ).markRescheduled(item.programDayId, mondayOf(item.scheduledDate));
    await controller.refresh();
  }

  Future<int> createUnlinkedDay({String? title}) async {
    final program = await programRepo.create(
      Program(
        name: 'Без привязки',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, title: title)],
    );
    final days = await programRepo.getDays(program.id!);
    return days.first.id!;
  }

  Future<int> createLinkedDay(int dayOfWeek, {String? title}) async {
    final program = await programRepo.create(
      Program(
        name: 'По расписанию',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [
        ProgramDay(
          programId: 0,
          dayIndex: 0,
          dayOfWeek: dayOfWeek,
          title: title,
        ),
      ],
    );
    final days = await programRepo.getDays(program.id!);
    return days.first.id!;
  }

  test(
    'кастомное название дня доходит до items из всех источников (48.12)',
    () async {
      final linked = await createLinkedDay(1, title: 'Грудь');
      final unlinked = await createUnlinkedDay(title: 'Кардио');
      final manual = await createUnlinkedDay(title: 'Ноги');
      // 15 августа 2026 — суббота той же недели, что и fixedNow.
      await scheduleRepo.schedule(manual, DateTime(2026, 8, 15));

      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      String? titleOf(int dayId, int day) {
        final matches = controller.items.value
            .where((i) => i.programDayId == dayId && i.scheduledDate.day == day)
            .toList();
        expect(matches, hasLength(1), reason: 'item дня $dayId на $day');
        return matches.single.dayTitle;
      }

      expect(titleOf(linked, 10), 'Грудь');
      expect(titleOf(unlinked, 10), 'Кардио');
      expect(titleOf(manual, 15), 'Ноги');
    },
  );

  test('manual schedule appears in items', () async {
    final dayId = await createUnlinkedDay();
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 15));

    // 15 августа 2026 — суббота недели 10–16.08 (47.10: месяца больше нет).
    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    final items = controller.items.value;
    final matching = items.where(
      (i) => i.programDayId == dayId && i.scheduledDate.day == 15,
    );
    expect(matching, hasLength(1));
    expect(matching.first.status, WeekPlanStatus.pending);
  });

  test('cancelSchedule removes manual entry', () async {
    final dayId = await createUnlinkedDay();
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 15));

    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();
    expect(controller.items.value, isNotEmpty);

    await controller.cancelSchedule(dayId, DateTime(2026, 8, 15));
    final items = controller.items.value;
    final matching = items.where(
      (i) => i.programDayId == dayId && i.scheduledDate.day == 15,
    );
    expect(matching, isEmpty);
  });

  test('scheduleDay adds to items', () async {
    final dayId = await createUnlinkedDay();

    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    // До назначения четверг 13.08 пуст.
    final beforeItems = controller.items.value
        .where((i) => i.programDayId == dayId && i.scheduledDate.day == 13)
        .toList();
    expect(beforeItems, isEmpty);

    await controller.scheduleDay(dayId, DateTime(2026, 8, 13));
    final items = controller.items.value.where(
      (i) => i.programDayId == dayId && i.scheduledDate.day == 13,
    );
    expect(items, hasLength(1));
  });

  test('manual schedule does not duplicate recurring item', () async {
    // Monday = 1, Aug 10 2026 is a Monday.
    final dayId = await createLinkedDay(1);

    // Manually schedule on the same date as the recurring.
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 10));

    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    final items = controller.items.value.where(
      (i) =>
          i.programDayId == dayId &&
          i.scheduledDate.day == 10 &&
          i.scheduledDate.month == 8,
    );
    expect(items, hasLength(1));
  });

  test(
    'навигация плана: вперёд до следующей, назад — по границе (47.10, 48.3)',
    () async {
      await controller.refresh();
      // Сегодня — понедельник 10.08.2026, отображается текущая неделя.
      expect(controller.weekStart.value, DateTime(2026, 8, 10));
      expect(controller.canGoNextWeek, isTrue);
      // Активных программ и сессий нет — смотреть прошлое нечего.
      expect(controller.canGoPrevWeek, isFalse);

      controller.shiftWeek(1);
      expect(controller.weekStart.value, DateTime(2026, 8, 17));
      expect(controller.canGoNextWeek, isFalse);
      // Даже без истории из будущей недели можно вернуться на текущую.
      expect(controller.canGoPrevWeek, isTrue);

      // Дальше вперёд нельзя: неделя не выходит за пределы текущей+следующей.
      controller.shiftWeek(1);
      expect(controller.weekStart.value, DateTime(2026, 8, 24));
      expect(controller.canGoNextWeek, isFalse);
      expect(controller.canGoPrevWeek, isTrue);
    },
  );

  test('назад — до недели активации программы, дальше нельзя (48.3)', () async {
    // Программа активирована 01.01.2024 (понедельник) — это и есть граница.
    await createLinkedDay(DateTime.monday);
    await controller.refresh();

    expect(controller.canGoPrevWeek, isTrue);
    controller.shiftWeek(-1);
    expect(controller.weekStart.value, DateTime(2026, 8, 3));
    expect(controller.canGoPrevWeek, isTrue);

    // Граница достижима, но перейти за неё нельзя.
    controller.weekStart.value = DateTime(2024, 1, 8);
    await controller.refresh();
    expect(controller.canGoPrevWeek, isTrue);

    controller.weekStart.value = DateTime(2024, 1, 1);
    await controller.refresh();
    expect(controller.canGoPrevWeek, isFalse);
  });

  test('нижняя граница назад учитывает и первую сессию (48.3)', () async {
    // Программ нет, есть одна разовая сессия 06.07.2026 (понедельник).
    await WorkoutRepository(db).saveSession(
      WorkoutSession(
        programName: 'Разовая',
        dayIndex: 0,
        performedDate: DateTime(2026, 7, 6),
        startedAt: DateTime(2026, 7, 6, 18),
        endedAt: DateTime(2026, 7, 6, 18, 40),
      ),
      const [],
    );
    await controller.refresh();

    expect(controller.canGoPrevWeek, isTrue);

    controller.weekStart.value = DateTime(2026, 7, 13);
    await controller.refresh();
    expect(controller.canGoPrevWeek, isTrue);

    controller.weekStart.value = DateTime(2026, 7, 6);
    await controller.refresh();
    expect(controller.canGoPrevWeek, isFalse);
  });

  test(
    'пропуск тренировки сегодня работает при «чужой» сессии в неделе',
    () async {
      // Регресс 43.7: сессия того же programDayId за прошлый день в этой неделе
      // не должна мешать пропуску сегодняшнего вхождения.
      final dayId = await createLinkedDay(DateTime.monday);
      final foreign = await programRepo.getDay(dayId);
      await WorkoutRepository(db).saveSession(
        WorkoutSession(
          programName: 'По расписанию',
          programDayId: foreign!.id,
          dayIndex: foreign.dayIndex,
          performedDate: DateTime(2026, 8, 9),
          startedAt: DateTime(2026, 8, 9),
          endedAt: DateTime(2026, 8, 9, 0, 40),
        ),
        const [],
      );
      await controller.refresh();

      final today10 = controller.items.value.firstWhere(
        (i) => i.scheduledDate.day == 10 && i.scheduledDate.month == 8,
      );
      expect(today10.status, WeekPlanStatus.pending);

      await controller.markSkipped(today10);

      final skipped = controller.items.value.firstWhere(
        (i) => i.scheduledDate.day == 10 && i.scheduledDate.month == 8,
      );
      expect(skipped.status, WeekPlanStatus.skipped);
      expect(dayActionsFor(skipped, fixedNow()), {DayAction.unskip});
    },
  );

  test('ручное назначение помечается isManual, дни программы — нет', () async {
    final linkedId = await createLinkedDay(DateTime.thursday);
    final unlinkedId = await createUnlinkedDay();
    await scheduleRepo.schedule(linkedId, DateTime(2026, 8, 14));
    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    final manual = controller.items.value.firstWhere(
      (i) => i.programDayId == linkedId && i.scheduledDate.day == 14,
    );
    final recurrent = controller.items.value.firstWhere(
      (i) => i.programDayId == linkedId && i.scheduledDate.day == 13,
    );
    final unlinked = controller.items.value.firstWhere(
      (i) => i.programDayId == unlinkedId,
    );

    expect(manual.isManual, isTrue);
    expect(recurrent.isManual, isFalse);
    expect(unlinked.isManual, isFalse);
    expect(unlinked.scheduledDate, DateTime(2026, 8, 10));
  });

  group('окно переноса — только в рамках тренировочной недели (47.2)', () {
    Future<WeekPlanItem> itemOn(DateTime now, int dayOfWeek) async {
      // 10.08.2026 — понедельник.
      final dayId = await createLinkedDay(dayOfWeek);
      controller.dispose();
      controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: WorkoutRepository(db),
        planScheduleRepository: scheduleRepo,
        clock: () => now,
      );
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();
      return controller.items.value.firstWhere(
        (i) =>
            i.programDayId == dayId &&
            i.scheduledDate.day == 10 + dayOfWeek - 1,
      );
    }

    test(
      'прошедший день своей недели ещё можно перенести на сегодня',
      () async {
        // Воскресенье: понедельник той же недели — перенос доступен.
        final item = await itemOn(DateTime(2026, 8, 16), DateTime.monday);

        expect(item.status, WeekPlanStatus.pending);
        expect(dayActionsFor(item, DateTime(2026, 8, 16)), {
          DayAction.reschedule,
        });
      },
    );

    test(
      'в следующий понедельник понедельник прошлой недели — переноса нет',
      () async {
        final item = await itemOn(DateTime(2026, 8, 17), DateTime.monday);

        expect(item.status, WeekPlanStatus.pastSkipped);
        expect(dayActionsFor(item, DateTime(2026, 8, 17)), isEmpty);
      },
    );

    test(
      'последний день недели (воскресенье) в понедельник — уже неделя',
      () async {
        // 16.08 — воскресенье, тренировка «сегодня» (старт + пропуск);
        // 17.08 — понедельник следующей недели: переноса уже нет.
        final sunday = await itemOn(DateTime(2026, 8, 16), DateTime.sunday);
        expect(sunday.status, WeekPlanStatus.pending);
        expect(dayActionsFor(sunday, DateTime(2026, 8, 16)), {
          DayAction.start,
          DayAction.skip,
        });

        controller.dispose();
        controller = WeekPlanController(
          programRepository: programRepo,
          workoutRepository: WorkoutRepository(db),
          planScheduleRepository: scheduleRepo,
          clock: () => DateTime(2026, 8, 17),
        );
        controller.weekStart.value = DateTime(2026, 8, 10);
        await controller.refresh();
        final sundayNextMonday = controller.items.value.firstWhere(
          (i) =>
              i.programName == 'По расписанию' &&
              i.scheduledDate.day == 16 &&
              i.scheduledDate.month == 8,
        );
        expect(sundayNextMonday.status, WeekPlanStatus.pastSkipped);
        expect(dayActionsFor(sundayNextMonday, DateTime(2026, 8, 17)), isEmpty);
      },
    );
  });

  group('перенос очищает день-источник (47.3)', () {
    // Программа из двух дней: понедельник и вторник одной недели.
    Future<List<int>> createTwoDayProgram() async {
      final program = await programRepo.create(
        Program(
          name: 'Два дня',
          daysCount: 2,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isActive: true,
          activatedAt: DateTime(2024, 1, 1),
        ),
        [
          ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: DateTime.monday),
          ProgramDay(programId: 0, dayIndex: 1, dayOfWeek: DateTime.tuesday),
        ],
      );
      final days = await programRepo.getDays(program.id!);
      return days.map((d) => d.id!).toList();
    }

    test('после переноса вторника понедельник остаётся в плане', () async {
      final ids = await createTwoDayProgram();
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final tuesday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[1] && i.scheduledDate.day == 11,
      );
      await markRescheduled(tuesday);

      final visible = controller.items.value
          .where((i) => i.scheduledDate.day == 11)
          .toList();
      expect(visible, isEmpty);
      // Понедельник той же недели не тронут.
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
        ),
        isTrue,
      );
    });

    test('на следующей неделе тренировка снова в плане', () async {
      final ids = await createTwoDayProgram();
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final monday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
      );
      await markRescheduled(monday);
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
        ),
        isFalse,
      );

      controller.weekStart.value = DateTime(2026, 8, 17);
      await controller.refresh();
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 17,
        ),
        isTrue,
      );
    });

    test('перенос скрывает только источник, а не весь день', () async {
      // Два дня программы на вторник: один уходит в перенос, второй остаётся.
      final program = await programRepo.create(
        Program(
          name: 'Два вторника',
          daysCount: 2,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isActive: true,
          activatedAt: DateTime(2024, 1, 1),
        ),
        [
          ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: DateTime.tuesday),
          ProgramDay(programId: 0, dayIndex: 1, dayOfWeek: DateTime.tuesday),
        ],
      );
      final days = await programRepo.getDays(program.id!);
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final tuesdayItems = controller.items.value
          .where((i) => i.scheduledDate.day == 11)
          .toList();
      expect(tuesdayItems, hasLength(2));

      await markRescheduled(tuesdayItems.first);
      final after = controller.items.value
          .where((i) => i.scheduledDate.day == 11)
          .toList();
      expect(after, hasLength(1));
      expect(after.single.programDayId, days.last.id);
    });

    test('маркер переноса не трогает пропуски', () async {
      final ids = await createTwoDayProgram();
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final monday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
      );
      await controller.markSkipped(monday);
      expect(
        controller.items.value
            .firstWhere(
              (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
            )
            .status,
        WeekPlanStatus.skipped,
      );

      final tuesday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[1] && i.scheduledDate.day == 11,
      );
      await markRescheduled(tuesday);
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
        ),
        isTrue,
      );
    });
  });

  test('загрузка плана чистит записи прошлых недель (47.4)', () async {
    final dayId = await createLinkedDay(DateTime.wednesday);
    // Назначение в прошлой неделе — должно исчезнуть при загрузке.
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 5));
    await WorkoutRepository(db).markSkipped(dayId, DateTime(2026, 8, 3));

    expect(await scheduleRepo.isScheduled(dayId, DateTime(2026, 8, 5)), isTrue);

    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    expect(
      await scheduleRepo.isScheduled(dayId, DateTime(2026, 8, 5)),
      isFalse,
    );
    expect(await WorkoutRepository(db).getMarks(DateTime(2026, 8, 3)), isEmpty);
    // План текущей недели собирается и содержит тренировку за среду.
    expect(
      controller.items.value.any(
        (i) => i.programDayId == dayId && i.scheduledDate.day == 12,
      ),
      isTrue,
    );
  });

  test(
    'статус «Перенесено» даёт сессия в другой день и без отметки (47.1, 48.4)',
    () async {
      // Отметку переноса теперь ставит экран выполнения (48.4), поэтому до
      // неё статус источника должен вычисляться из самой сессии, как в 47.1.
      final dayId = await createLinkedDay(DateTime.monday);

      // Четверг13.08: понедельник10.08 той же недели уже прошёл.
      final late = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: WorkoutRepository(db),
        planScheduleRepository: scheduleRepo,
        clock: () => DateTime(2026, 8, 13),
      );
      addTearDown(() async {
        await pumpEventQueue();
        late.dispose();
      });

      await WorkoutRepository(db).saveSession(
        WorkoutSession(
          programName: 'По расписанию',
          programDayId: dayId,
          dayIndex: 0,
          performedDate: DateTime(2026, 8, 13),
          startedAt: DateTime(2026, 8, 13, 18),
          endedAt: DateTime(2026, 8, 13, 18, 40),
        ),
        const [],
      );
      await late.refresh();

      final source = late.items.value.firstWhere(
        (i) => i.programDayId == dayId && i.scheduledDate.day == 10,
      );
      expect(source.status, WeekPlanStatus.rescheduled);
      // Отметки ещё нет — день-источник остаётся в плане, только со статусом.
      expect(
        await WorkoutRepository(db).getMarks(DateTime(2026, 8, 10)),
        isEmpty,
      );
    },
  );
}
