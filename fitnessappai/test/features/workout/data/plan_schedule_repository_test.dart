import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';

void main() {
  late AppDatabase db;
  late PlanScheduleRepository repo;
  late ProgramRepository programRepo;
  late int programId;
  late int dayId;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = PlanScheduleRepository(db);
    programRepo = ProgramRepository(db);
    final program = await programRepo.create(
      Program(
        name: 'Тестовая',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [const ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 1)],
    );
    programId = program.id!;
    final days = await programRepo.getDays(programId);
    dayId = days.first.id!;
  });

  tearDown(() async {
    await db.close();
  });

  test('schedule + getForRange', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date);

    final items = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(items, hasLength(1));
    expect(items.first.programDayId, equals(dayId));
    expect(items.first.scheduledDate, equals(date));
  });

  test('schedule is idempotent', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date);
    await repo.schedule(dayId, date);

    final items = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(items, hasLength(1));
  });

  test('cancel removes assignment', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date);
    await repo.cancel(dayId, date);

    final items = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(items, isEmpty);
  });

  test('isScheduled', () async {
    final date = DateTime(2026, 8, 15);
    expect(await repo.isScheduled(dayId, date), isFalse);
    await repo.schedule(dayId, date);
    expect(await repo.isScheduled(dayId, date), isTrue);
  });

  test('getForRange filters by date', () async {
    await repo.schedule(dayId, DateTime(2026, 8, 10));
    await repo.schedule(dayId, DateTime(2026, 9, 5));

    final augustItems = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(augustItems, hasLength(1));

    final allItems = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 9, 30),
    );
    expect(allItems, hasLength(2));
  });

  test('deleteBefore удаляет только прошлые записи (47.4)', () async {
    // Понедельник недели — граница очистки.
    await repo.schedule(dayId, DateTime(2026, 8, 3)); // прошлая неделя
    await repo.schedule(dayId, DateTime(2026, 8, 9)); // прошлая неделя
    await repo.schedule(dayId, DateTime(2026, 8, 10)); // граница
    await repo.schedule(dayId, DateTime(2026, 8, 16)); // конец текущей недели
    await repo.schedule(dayId, DateTime(2026, 8, 20)); // будущая неделя

    final removed = await repo.deleteBefore(DateTime(2026, 8, 10));

    expect(removed, 2);
    final left = await repo.getForRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 12, 31),
    );
    expect(left.map((i) => i.scheduledDate.day), [10, 16, 20]);
  });

  test('deleteBefore не трогает ничего, если прошлых записей нет', () async {
    await repo.schedule(dayId, DateTime(2026, 8, 10));

    expect(await repo.deleteBefore(DateTime(2026, 8, 10)), 0);
    expect(await repo.isScheduled(dayId, DateTime(2026, 8, 10)), isTrue);
  });

  test('schedule сохраняет время и напоминание (48.10)', () async {
    final item = await repo.schedule(
      dayId,
      DateTime(2026, 8, 15),
      hour: 18,
      minute: 30,
      reminderEnabled: true,
    );

    expect(item.hasTime, isTrue);
    expect(item.timeLabel, '18:30');
    expect(item.reminderEnabled, isTrue);
  });

  test('повторное schedule не затирает заданное время (48.10)', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(
      dayId,
      date,
      hour: 18,
      minute: 30,
      reminderEnabled: true,
    );

    final item = await repo.schedule(dayId, date);

    expect(item.timeLabel, '18:30');
    expect(item.reminderEnabled, isTrue);
  });

  test('напоминание включается только вместе со временем (48.10)', () async {
    final item = await repo.schedule(
      dayId,
      DateTime(2026, 8, 15),
      reminderEnabled: true,
    );

    expect(item.hasTime, isFalse);
    expect(item.reminderEnabled, isFalse);
  });

  test('setReminder создаёт строку дня по привязке (48.10)', () async {
    final date = DateTime(2026, 8, 15);
    expect(await repo.getFor(dayId, date), isNull);

    final created = await repo.setReminder(
      dayId,
      date,
      hour: 7,
      minute: 5,
      reminderEnabled: true,
    );

    expect(created.timeLabel, '07:05');
    expect(created.reminderEnabled, isTrue);
    expect(await repo.isScheduled(dayId, date), isTrue);
  });

  test('setReminder убирает время и гасит напоминание (48.10)', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(
      dayId,
      date,
      hour: 18,
      minute: 30,
      reminderEnabled: true,
    );

    final item = await repo.setReminder(
      dayId,
      date,
      hour: null,
      minute: null,
      reminderEnabled: false,
    );

    expect(item.hasTime, isFalse);
    expect(item.reminderEnabled, isFalse);
    // Назначение не удаляется: меняются только время и уведомление.
    expect(await repo.isScheduled(dayId, date), isTrue);
  });

  test('remindersBetween возвращает активные программы (48.10)', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date, hour: 9, minute: 0, reminderEnabled: true);

    final active = await repo.remindersBetween(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );

    expect(active, hasLength(1));
    expect(active.single.programName, 'Тестовая');
    expect(active.single.dayNumber, 1);
    expect(active.single.hour, 9);
    expect(active.single.minute, 0);
    expect(active.single.scheduledDate, date);
  });

  test('deactivate прячет напоминание из remindersBetween (48.10)', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date, hour: 9, minute: 0, reminderEnabled: true);
    await programRepo.deactivate(programId);

    expect(
      await repo.remindersBetween(DateTime(2026, 8, 1), DateTime(2026, 8, 31)),
      isEmpty,
    );
    // Выборка по явно указанным дням активности не читает: деактивация
    // должна уметь снять уведомления с программы.
    expect(await repo.remindersForDays([dayId]), hasLength(1));
  });

  test('remindersBetween пропускает дни без напоминания (48.10)', () async {
    // Время задано, но уведомление выключено — показывать его в плане
    // не мешает, перепланировать нечего.
    await repo.schedule(dayId, DateTime(2026, 8, 15), hour: 9, minute: 0);
    // Время не задано вовсе.
    await repo.schedule(dayId, DateTime(2026, 8, 16));
    // Включённое напоминание — единственный кандидат.
    await repo.schedule(
      dayId,
      DateTime(2026, 8, 17),
      hour: 20,
      minute: 15,
      reminderEnabled: true,
    );

    final reminders = await repo.remindersBetween(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.scheduledDate.day, 17);
    expect(reminders.single.hour, 20);
  });

  test('remindersForDays без дней не ходит в базу (48.10)', () async {
    expect(await repo.remindersForDays(const []), isEmpty);
  });
}
