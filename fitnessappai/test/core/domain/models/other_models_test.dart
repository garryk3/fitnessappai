import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/user_profile.dart';
import 'package:fitnessappai/core/domain/models/workout_reminder.dart';

void main() {
  test('BodyMeasurement: все поля кроме даты опциональны', () {
    final m = BodyMeasurement(date: DateTime(2026, 8, 9));
    expect(m.weightKg, isNull);
    expect(m.copyWith(weightKg: 80.5).weightKg, 80.5);
    expect(m.copyWith(clearId: true).id, isNull);
  });

  test('ScheduleMark: копия и равенство', () {
    final mark = ScheduleMark(
      id: 1,
      programDayId: 3,
      weekStart: DateTime(2026, 8, 3),
    );
    expect(mark.status, ScheduleMarkStatus.skipped);
    expect(mark.copyWith(programDayId: 4).programDayId, 4);
    expect(
      mark,
      ScheduleMark(id: 1, programDayId: 3, weekStart: DateTime(2026, 8, 3)),
    );
  });

  test('UserProfile: все поля nullable', () {
    final p = UserProfile(id: 1);
    expect(p.name, isNull);
    expect(p.copyWith(name: 'Иван').name, 'Иван');
    expect(p.copyWith(clearName: true).name, isNull);
  });

  test('WorkoutReminder: время и копия', () {
    final r = WorkoutReminder(id: 1, programDayId: 2, hour: 7, minute: 30);
    expect(r.enabled, isTrue);
    expect(r.copyWith(enabled: false).enabled, isFalse);
    expect(r.toString(), contains('07:30'));
  });
}
