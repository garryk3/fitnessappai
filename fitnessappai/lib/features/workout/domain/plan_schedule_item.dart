/// Запись ручного назначения тренировочного дня на конкретную дату.
class PlanScheduleItem {
  const PlanScheduleItem({
    required this.id,
    required this.programDayId,
    required this.scheduledDate,
    this.reminderHour,
    this.reminderMinute,
    this.reminderEnabled = false,
  });

  final int id;
  final int programDayId;
  final DateTime scheduledDate;

  /// Время тренировки (48.10); `null` — время не задано.
  ///
  /// Час и минута существуют только вместе: пара nullable-полей в схеме,
  /// частичного состояния («час есть, минуты нет») не бывает.
  final int? reminderHour;
  final int? reminderMinute;

  /// Включено ли одноразовое напоминание.
  ///
  /// Управляет исключительно уведомлением: время показывается в плане
  /// всегда, независимо от флага (решение владельца 48.10).
  final bool reminderEnabled;

  /// Есть ли заданное время.
  bool get hasTime => reminderHour != null && reminderMinute != null;

  /// Время в формате `HH:mm`; `null`, если времени нет.
  String? get timeLabel {
    final hour = reminderHour;
    final minute = reminderMinute;
    if (hour == null || minute == null) {
      return null;
    }
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'PlanScheduleItem(id: $id, day: $programDayId, '
      'date: $scheduledDate, time: $timeLabel, '
      'reminder: $reminderEnabled)';
}

/// Назначение с включённым напоминанием и данными для показа уведомления.
///
/// Возвращает репозиторий ручных назначений: `ReminderService` перепланирует
/// одноразовые уведомления после возврата в приложение и после импорта базы
/// (задача 48.10) и для этого должен получить программу и номер дня вместе с
/// датой и временем.
class PlanScheduleReminder {
  const PlanScheduleReminder({
    required this.scheduleId,
    required this.programDayId,
    required this.scheduledDate,
    required this.hour,
    required this.minute,
    required this.programName,
    required this.dayNumber,
  });

  /// id строки в `plan_schedule` — из него считается id уведомления.
  final int scheduleId;
  final int programDayId;

  /// Дата тренировки (без времени суток).
  final DateTime scheduledDate;
  final int hour;
  final int minute;

  /// Название программы и номер дня (с единицы) — текст уведомления.
  final String programName;
  final int dayNumber;

  @override
  String toString() =>
      'PlanScheduleReminder(schedule: $scheduleId, day: $programDayId, '
      'date: $scheduledDate, $hour:$minute)';
}
