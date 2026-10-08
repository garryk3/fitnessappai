import 'package:flutter/material.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';

/// Результат редактирования времени тренировки (48.10).
class ReminderTimeResult {
  const ReminderTimeResult({
    required this.hour,
    required this.minute,
    required this.reminderEnabled,
  });

  /// Время убрано («Убрать время»): час и минута обнуляются, напоминание
  /// выключается — без времени уведомление запланировать нечего.
  const ReminderTimeResult.clear()
    : hour = null,
      minute = null,
      reminderEnabled = false;

  /// Час тренировки; `null` — времени нет.
  final int? hour;

  /// Минута тренировки; `null` — времени нет.
  final int? minute;

  /// Показывать ли одноразовое напоминание (имеет смысл только со временем).
  final bool reminderEnabled;
}

/// Диалог «Время и напоминание» для уже назначенного дня (48.10).
///
/// Возвращает выбранное время и состояние напоминания; `null` — отмену.
/// Открывается тапом по строке времени на карточке дня и пунктом
/// «Время и напоминание» в листе действий дня.
Future<ReminderTimeResult?> showReminderTimeDialog(
  BuildContext context, {
  int? hour,
  int? minute,
  bool reminderEnabled = false,
}) {
  return showDialog<ReminderTimeResult>(
    context: context,
    builder: (dialogContext) => _ReminderTimeDialog(
      hour: hour,
      minute: minute,
      reminderEnabled: reminderEnabled,
    ),
  );
}

class _ReminderTimeDialog extends StatefulWidget {
  const _ReminderTimeDialog({
    required this.hour,
    required this.minute,
    required this.reminderEnabled,
  });

  final int? hour;
  final int? minute;
  final bool reminderEnabled;

  @override
  State<_ReminderTimeDialog> createState() => _ReminderTimeDialogState();
}

class _ReminderTimeDialogState extends State<_ReminderTimeDialog> {
  TimeOfDay? _time;
  late bool _reminderOn;

  @override
  void initState() {
    super.initState();
    final hour = widget.hour;
    final minute = widget.minute;
    _time = hour == null || minute == null
        ? null
        : TimeOfDay(hour: hour, minute: minute);
    // Напоминание без времени не показываем включённым: оно не запланировано.
    _reminderOn = _time != null && widget.reminderEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = _time;
    return AlertDialog(
      title: Text(l10n.weekPlanTimeAction),
      content: ReminderTimeFields(
        time: time,
        reminderEnabled: _reminderOn,
        onTimeChanged: (value) => setState(() {
          _time = value;
        }),
        onReminderChanged: (value) => setState(() {
          _reminderOn = value;
        }),
      ),
      actions: [
        if (time != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const ReminderTimeResult.clear()),
            child: Text(l10n.weekPlanClearTime),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            ReminderTimeResult(
              hour: time?.hour,
              minute: time?.minute,
              reminderEnabled: _reminderOn,
            ),
          ),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Строка выбора времени и переключатель напоминания (48.10).
///
/// Без состояния: значения держит вызывающая сторона — лист планирования
/// перед назначением или [_ReminderTimeDialog] при правке. Напоминание
/// выключено и недоступно, пока время не задано: планировать нечего.
class ReminderTimeFields extends StatelessWidget {
  const ReminderTimeFields({
    super.key,
    required this.time,
    required this.reminderEnabled,
    required this.onTimeChanged,
    required this.onReminderChanged,
  });

  /// Выбранное время; `null` — время не задано.
  final TimeOfDay? time;

  /// Состояние переключателя напоминания.
  final bool reminderEnabled;

  /// Пользователь выбрал время (или новое — в диалоге).
  final ValueChanged<TimeOfDay> onTimeChanged;

  /// Пользователь включил/выключил напоминание.
  final ValueChanged<bool> onReminderChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = this.time;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time),
          title: Text(l10n.weekPlanTime),
          subtitle: Text(
            time == null ? l10n.weekPlanNoTime : _formatTime(time),
          ),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
            );
            if (picked == null || !context.mounted) {
              return;
            }
            onTimeChanged(picked);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.reminderToggle),
          value: reminderEnabled && time != null,
          onChanged: time == null ? null : onReminderChanged,
        ),
      ],
    );
  }
}

/// Время в формате `HH:mm` — ровно так же, как оно показывается в плане.
///
/// `MaterialLocalizations.formatTimeOfDay` для русской локали часы не
/// дополняет нулём («9:00»), тогда как карточка дня показывает «09:00» из
/// `PlanScheduleItem.timeLabel`: одно и то же время в двух видах читалось бы
/// как расхождение.
String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
