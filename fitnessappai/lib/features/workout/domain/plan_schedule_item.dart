/// Запись ручного назначения тренировочного дня на конкретную дату.
class PlanScheduleItem {
  const PlanScheduleItem({
    required this.id,
    required this.programDayId,
    required this.scheduledDate,
  });

  final int id;
  final int programDayId;
  final DateTime scheduledDate;
}
