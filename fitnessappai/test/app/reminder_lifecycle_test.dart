import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_day_builder_screen.dart';
import 'package:fitnessappai/main.dart';

import '../helpers/test_services.dart';

/// Считает перепланирования, не трогая плагин уведомлений.
class _CountingReminderService extends ReminderService {
  _CountingReminderService({required super.repository});

  int rescheduleCalls = 0;

  @override
  Future<void> rescheduleAll() async {
    rescheduleCalls++;
  }
}

void main() {
  setUp(registerTestServices);

  testWidgets('при возврате в приложение напоминания перепланируются', (
    tester,
  ) async {
    final reminders = _CountingReminderService(
      repository: WorkoutReminderRepository(locator.get<AppDatabase>()),
    );
    locator.registerInstance<ReminderService>(reminders);

    await tester.pumpWidget(const FitnessAppAi());
    expect(reminders.rescheduleCalls, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(reminders.rescheduleCalls, 0, reason: 'на паузе не перепланируем');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(reminders.rescheduleCalls, 1);
  });

  testWidgets('приложение стартует без зарегистрированных напоминаний', (
    tester,
  ) async {
    // registerTestServices не регистрирует ReminderService — сборка UI не
    // должна падать на этом.
    await tester.pumpWidget(const FitnessAppAi());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('тап по уведомлению открывает день тренировки', (tester) async {
    final repository = WorkoutReminderRepository(locator.get<AppDatabase>());
    locator.registerInstance<WorkoutReminderRepository>(repository);
    final reminders = _CountingReminderService(repository: repository);
    locator.registerInstance<ReminderService>(reminders);

    final program = await locator.get<ProgramRepository>().create(
      Program(
        name: 'Сплит',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 2)],
    );
    final day = (await locator.get<ProgramRepository>().getDays(
      program.id!,
    )).single;

    await tester.pumpWidget(const FitnessAppAi());
    await tester.pumpAndSettle();

    reminders.handleNotificationResponse(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '${day.id}',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProgramDayBuilderScreen), findsOneWidget);
  });

  testWidgets('после перезапуска приложения напоминания переподключены', (
    tester,
  ) async {
    // До импорта БД контейнер пересоздаётся, а вместе с ним и ReminderService.
    final stale = _CountingReminderService(
      repository: WorkoutReminderRepository(locator.get<AppDatabase>()),
    );
    locator.registerInstance<ReminderService>(stale);
    await tester.pumpWidget(const FitnessAppAi());

    // Имитируем импорт: контейнер сброшен, зарегистрирован новый сервис.
    final fresh = _CountingReminderService(
      repository: WorkoutReminderRepository(locator.get<AppDatabase>()),
    );
    locator.registerInstance<ReminderService>(fresh);
    restartApp();
    await tester.pump();
    await tester.pump();

    // Прежний сервис больше не должен получать перепланирование от UI.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(stale.rescheduleCalls, 0, reason: 'старый сервис снят с UI');
    expect(fresh.rescheduleCalls, 1, reason: 'UI работает с новым сервисом');
  });
}
