// ignore_for_file: type=lint
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
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
    'навигация плана: вперёд до следующей, назад только на текущую (47.10, 51.2)',
    () async {
      await controller.refresh();
      // Сегодня — понедельник 10.08.2026, отображается текущая неделя.
      expect(controller.weekStart.value, DateTime(2026, 8, 10));
      expect(controller.canGoNextWeek, isTrue);
      // Назад нельзя: текущая неделя — нижняя граница навигации.
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

  test(
    'прошлые недели недоступны даже при старой программе и сессии (51.2)',
    () async {
      // Программа активирована 01.01.2024, плюс разовая сессия 06.07.2026: в 48.3
      // это были границы, до которых открывался просмотр прошлого. Теперь нижняя
      // граница — всегда текущая неделя.
      await createLinkedDay(DateTime.monday);
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

      // Сегодня — текущая неделя: назад нельзя.
      expect(controller.weekStart.value, DateTime(2026, 8, 10));
      expect(controller.canGoPrevWeek, isFalse);

      // Из следующей недели возврат возможен только на текущую.
      controller.shiftWeek(1);
      expect(controller.canGoPrevWeek, isTrue);
      controller.shiftWeek(-1);
      expect(controller.weekStart.value, DateTime(2026, 8, 10));
      expect(controller.canGoPrevWeek, isFalse);
    },
  );

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

  test('вид «Месяц»: месяц целиком, возврат к неделе (54.5)', () async {
    await createLinkedDay(DateTime.monday);
    await controller.refresh();

    expect(controller.view.value, WeekPlanView.week);
    expect(controller.items.value.map((i) => i.scheduledDate.day), [10]);

    controller.setView(WeekPlanView.month);
    await pumpEventQueue();

    expect(controller.view.value, WeekPlanView.month);
    // Август целиком: понедельники 3, 10, 17, 24 и 31.
    expect(controller.items.value.map((i) => i.scheduledDate.day).toList(), [
      3,
      10,
      17,
      24,
      31,
    ]);
    // Текущий месяц — нижняя граница: назад некуда, вперёд тоже — конец
    // следующей недели (23.08) раньше 01.09.
    expect(controller.canGoPrevMonth, isFalse);
    expect(controller.canGoNextMonth, isFalse);

    controller.setView(WeekPlanView.week);
    await pumpEventQueue();
    expect(controller.items.value.map((i) => i.scheduledDate.day), [10]);
  });

  test(
    'смена вида/месяца синхронно сбрасывает items (без pop-in, design-review)',
    () async {
      await createLinkedDay(DateTime.monday);
      await controller.refresh();
      expect(controller.items.value, isNotEmpty);

      // setView: старые item'ы очищаются синхронно до завершения загрузки —
      // спиннер включается сразу, сетка не рисуется по данным чужого периода.
      controller.setView(WeekPlanView.month);
      expect(controller.items.value, isEmpty);
      expect(controller.view.value, WeekPlanView.month);
      await pumpEventQueue();
      expect(controller.items.value, isNotEmpty);

      // shiftMonth: то же при переходе на соседний месяц.
      controller.shiftMonth(1);
      expect(controller.items.value, isEmpty);
      await pumpEventQueue();

      // refresh() item'ы не трогает — без мигания на авто-перезагрузках.
      final before = controller.items.value;
      await controller.refresh();
      expect(controller.items.value, isNotEmpty);
      expect(identical(controller.items.value, before), isFalse);
      expect(
        controller.items.value.map((i) => i.scheduledDate.day),
        before.map((i) => i.scheduledDate.day),
      );
    },
  );

  test('навигация месяцами в границах данных (54.5)', () async {
    await createLinkedDay(DateTime.monday);
    final late = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: WorkoutRepository(db),
      planScheduleRepository: scheduleRepo,
      clock: () => DateTime(2026, 8, 25),
    );
    addTearDown(() async {
      await pumpEventQueue();
      late.dispose();
    });
    late.setView(WeekPlanView.month);
    await pumpEventQueue();

    expect(late.monthStart.value, DateTime(2026, 8, 1));
    expect(late.canGoPrevMonth, isFalse);
    // Конец следующей недели — 06.09: сентябрь в границах, октябрь нет.
    expect(late.canGoNextMonth, isTrue);

    late.shiftMonth(1);
    await pumpEventQueue();
    expect(late.monthStart.value, DateTime(2026, 9, 1));
    expect(late.canGoPrevMonth, isTrue);
    expect(late.canGoNextMonth, isFalse);

    late.shiftMonth(-1);
    await pumpEventQueue();
    expect(late.monthStart.value, DateTime(2026, 8, 1));
    expect(late.canGoPrevMonth, isFalse);
  });

  test(
    'выбор дня месяца: по умолчанию «сегодня», смена месяца сбрасывает',
    () async {
      controller.setView(WeekPlanView.month);
      await pumpEventQueue();

      expect(controller.effectiveMonthDate, DateTime(2026, 8, 10));

      // Тап по ячейке выбирает день (время суток отбрасывается).
      controller.selectMonthDate(DateTime(2026, 8, 17, 15));
      expect(controller.effectiveMonthDate, DateTime(2026, 8, 17));

      // В другом месяце «сегодня» (10.08) вне его — fallback на 1-е число,
      // карточка дня остаётся видимой (54.5).
      controller.shiftMonth(1);
      await pumpEventQueue();
      expect(controller.monthSelectedDate.value, isNull);
      expect(controller.effectiveMonthDate, DateTime(2026, 9, 1));

      controller.shiftMonth(-1);
      await pumpEventQueue();
      expect(controller.effectiveMonthDate, DateTime(2026, 8, 10));
    },
  );

  test(
    'muscleKeys дня — группы основных упражнений без дублей (54.5)',
    () async {
      final dayId = await createLinkedDay(DateTime.monday);
      final chest = await (db.select(
        db.muscleGroups,
      )..where((t) => t.key.equals('chest'))).getSingle();
      final exerciseId = await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: 'Жим лёжа',
              type: ExerciseType.strength,
              createdAt: DateTime(2024, 1, 1),
              updatedAt: DateTime(2024, 1, 1),
            ),
          );
      await db
          .into(db.exerciseMuscles)
          .insert(
            ExerciseMusclesCompanion.insert(
              exerciseId: exerciseId,
              muscleGroupId: chest.id,
              intensity: MuscleIntensity.primary,
            ),
          );
      await programRepo.addExerciseToDay(dayId, exerciseId);

      final withMuscles = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: WorkoutRepository(db),
        planScheduleRepository: scheduleRepo,
        exerciseRepository: ExerciseRepository(db, MediaStore()),
        clock: fixedNow,
      );
      addTearDown(() async {
        await pumpEventQueue();
        withMuscles.dispose();
      });
      await pumpEventQueue();

      final item = withMuscles.items.value.firstWhere(
        (i) => i.programDayId == dayId,
      );
      expect(item.muscleKeys, ['chest']);

      // Без репозитория ключей нет — иконки скрываются («без данных — без
      // элементов»), сам item при этом остаётся.
      final bare = controller.items.value.firstWhere(
        (i) => i.programDayId == dayId,
      );
      expect(bare.muscleKeys, isEmpty);
    },
  );
}
