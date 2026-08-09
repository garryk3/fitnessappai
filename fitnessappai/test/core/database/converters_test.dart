import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/converters/date_time_converter.dart';
import 'package:fitnessappai/core/database/converters/enum_converters.dart';
import 'package:fitnessappai/core/database/converters/string_list_converter.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/schedule_mark.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';

void main() {
  group('DateTimeConverter', () {
    const converter = DateTimeConverter();

    test('round-trip сохраняет значение', () {
      final dateTime = DateTime(2026, 8, 9, 18, 30, 45, 123);
      expect(converter.fromSql(converter.toSql(dateTime)), dateTime);
    });

    test('toSql возвращает миллисекунды эпохи', () {
      final dateTime = DateTime.utc(2026, 1, 1);
      expect(converter.toSql(dateTime), dateTime.millisecondsSinceEpoch);
    });
  });

  group('StringListConverter', () {
    const converter = StringListConverter();

    test('round-trip сохраняет список', () {
      expect(converter.fromSql(converter.toSql(['a', 'b'])), ['a', 'b']);
    });

    test('toSql кодирует список в JSON-массив', () {
      expect(converter.toSql(['a']), '["a"]');
    });

    test('fromSql некорректного JSON возвращает пустой список', () {
      expect(converter.fromSql('not-json'), isEmpty);
    });
  });

  group('Enum-конвертеры', () {
    test('ExerciseType', () {
      const converter = ExerciseTypeConverter();
      for (final value in ExerciseType.values) {
        expect(converter.fromSql(converter.toSql(value)), value);
      }
      expect(converter.toSql(ExerciseType.strength), 'strength');
    });

    test('MuscleView', () {
      const converter = MuscleViewConverter();
      for (final value in MuscleView.values) {
        expect(converter.fromSql(converter.toSql(value)), value);
      }
      expect(converter.toSql(MuscleView.front), 'front');
    });

    test('MuscleIntensity', () {
      const converter = MuscleIntensityConverter();
      for (final value in MuscleIntensity.values) {
        expect(converter.fromSql(converter.toSql(value)), value);
      }
      expect(converter.toSql(MuscleIntensity.secondary), 'secondary');
    });

    test('WorkoutVariant', () {
      const converter = WorkoutVariantConverter();
      for (final value in WorkoutVariant.values) {
        expect(converter.fromSql(converter.toSql(value)), value);
      }
      expect(converter.toSql(WorkoutVariant.main), 'main');
    });

    test('ScheduleMarkStatus', () {
      const converter = ScheduleMarkStatusConverter();
      for (final value in ScheduleMarkStatus.values) {
        expect(converter.fromSql(converter.toSql(value)), value);
      }
      expect(converter.toSql(ScheduleMarkStatus.skipped), 'skipped');
    });
  });
}
