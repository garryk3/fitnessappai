/// Напоминание о тренировочном дне.
class WorkoutReminder {
  const WorkoutReminder({
    this.id,
    required this.programDayId,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final int? id;
  final int programDayId;
  final int hour;
  final int minute;
  final bool enabled;

  WorkoutReminder copyWith({
    int? id,
    int? programDayId,
    int? hour,
    int? minute,
    bool? enabled,
    bool clearId = false,
  }) {
    return WorkoutReminder(
      id: clearId ? null : id ?? this.id,
      programDayId: programDayId ?? this.programDayId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkoutReminder &&
            other.id == id &&
            other.programDayId == programDayId &&
            other.hour == hour &&
            other.minute == minute &&
            other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(id, programDayId, hour, minute, enabled);

  @override
  String toString() =>
      'WorkoutReminder(id: $id, programDayId: $programDayId, time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}, enabled: $enabled)';
}
