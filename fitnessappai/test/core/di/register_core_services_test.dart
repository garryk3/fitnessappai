import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';

/// Пишет имена вызванных методов, чтобы проверить порядок.
class _RecordingReminderService extends ReminderService {
  _RecordingReminderService(
    this.calls, {
    required super.repository,
    this.failOnInitialize = false,
  });

  final List<String> calls;
  final bool failOnInitialize;

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    if (failOnInitialize) {
      throw StateError('канал не создан');
    }
  }

  @override
  Future<void> rescheduleAll() async => calls.add('rescheduleAll');
}

void main() {
  late AppDatabase database;
  late WorkoutReminderRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = WorkoutReminderRepository(database);
  });

  tearDown(() => database.close());

  test(
    'после импорта сначала отменяем, потом создаём канал, потом планируем',
    () async {
      final calls = <String>[];

      await restoreRemindersAfterImport(
        _RecordingReminderService(calls, repository: repository),
      );

      expect(calls, ['cancelAll', 'initialize', 'rescheduleAll']);
    },
  );

  test(
    'сбой на этапе initialize не пробрасывается и не отменяет импорт',
    () async {
      final calls = <String>[];

      await expectLater(
        restoreRemindersAfterImport(
          _RecordingReminderService(
            calls,
            repository: repository,
            failOnInitialize: true,
          ),
        ),
        completes,
      );
      expect(calls, ['cancelAll', 'initialize']);
    },
  );
}
