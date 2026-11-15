import 'package:material_ui/material_ui.dart';

import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/progress/ui/day_sessions_sheet.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Экран деталей дня из прогресса: сессии в диапазоне `[start, end)`.
///
/// Остался для deep-link `/progress/day`: в UI тап по дню (история,
/// график прогресса) с 59.2 открывает нижний дравер [showDaySessionsSheet]
/// с тем же контентом [DaySessionsContent].
class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({
    super.key,
    required this.start,
    required this.end,
    this.workoutRepository,
    this.programRepository,
  });

  final DateTime start;
  final DateTime end;
  final WorkoutRepository? workoutRepository;
  final ProgramRepository? programRepository;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppTopBar(title: dayDetailTitle(start, end)),
      body: DaySessionsContent(
        start: start,
        end: end,
        workoutRepository: workoutRepository,
        programRepository: programRepository,
      ),
    );
  }
}
