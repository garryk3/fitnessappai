import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_reminder.dart';
import 'package:fitnessappai/core/domain/validators/program_validator.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_validation_dialog.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Конструктор программы: параметры и тренировочные дни.
///
/// [programId] равен `null` при создании новой программы.
class ProgramBuilderScreen extends StatefulWidget {
  const ProgramBuilderScreen({super.key, this.programId, this.repository});

  final int? programId;
  final ProgramRepository? repository;

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

/// Результат диалога настроек дня.
class DaySettings {
  const DaySettings({required this.dayOfWeek, required this.reminder});

  final int? dayOfWeek;
  final WorkoutReminder? reminder;
}

/// Черновик дня с уникальным стабильным ключом для реордера.
class _DayDraft {
  _DayDraft(this.key, {this.dayOfWeek});

  final int key;
  int? dayOfWeek;
  WorkoutReminder? reminder;
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  late final ProgramRepository _repository;
  late final WorkoutReminderRepository _reminderRepository;
  late final ReminderService _reminderService;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_DayDraft> _days = [];
  final Set<int> _filledDayIndexes = {};
  int _nextDayKey = -1;
  bool _loading = true;
  bool _saving = false;
  DateTime? _createdAt;
  int? _programId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ProgramRepository>();
    _reminderRepository = locator.get<WorkoutReminderRepository>();
    _reminderService = locator.get<ReminderService>();
    _programId = widget.programId;
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final programId = widget.programId;
    if (programId != null) {
      final detail = await _repository.getProgram(programId);
      if (detail != null && mounted) {
        _nameController.text = detail.program.name;
        _descriptionController.text = detail.program.description;
        _createdAt = detail.program.createdAt;
        _days
          ..clear()
          ..addAll([
            for (final day in detail.days)
              _DayDraft(
                day.day.id ?? _nextDayKey--,
                dayOfWeek: day.day.dayOfWeek,
              ),
          ]);
        _filledDayIndexes
          ..clear()
          ..addAll({
            for (final day in detail.days)
              if (day.mainExercises.any((e) => !e.isAlternative))
                day.day.dayIndex,
          });
        await _loadReminders();
        if (_days.isEmpty) {
          _addDay();
        }
      }
    }
    if (_days.isEmpty) {
      _addDay();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _addDay() {
    _days.add(_DayDraft(_nextDayKey--));
  }

  void _setDaysCount(int count) {
    if (count == _days.length) {
      return;
    }
    while (_days.length < count) {
      _addDay();
    }
    if (_days.length > count) {
      _days.removeRange(count, _days.length);
    }
    setState(() {});
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final day = _days.removeAt(oldIndex);
      _days.insert(newIndex, day);
    });
  }

  Future<void> _openDaySettings(_DayDraft day) async {
    final selected = await showDialog<DaySettings>(
      context: context,
      builder: (context) =>
          _DaySettingsDialog(dayOfWeek: day.dayOfWeek, reminder: day.reminder),
    );
    if (selected != null && mounted) {
      setState(() {
        day.dayOfWeek = selected.dayOfWeek;
        day.reminder = selected.reminder;
      });
    }
  }

  /// Загружает сохранённые напоминания дней редактируемой программы.
  Future<void> _loadReminders() async {
    for (final day in _days) {
      if (day.key >= 0) {
        day.reminder = await _reminderRepository.getForDay(day.key);
      }
    }
  }

  /// Захватывает напоминания текущих (до сохранения) дней программы.
  Future<Map<int, WorkoutReminder>> _previousReminders() async {
    final result = <int, WorkoutReminder>{};
    for (final day in _days) {
      if (day.key < 0) {
        continue;
      }
      final reminder = await _reminderRepository.getForDay(day.key);
      if (reminder != null) {
        result[day.key] = reminder;
      }
    }
    return result;
  }

  /// Планирует или отменяет уведомления по черновикам дней.
  ///
  /// [previousByDayKey] — напоминания старых дней (до сохранения). При
  /// редактировании `update` заменяет дни и их id, поэтому старые уведомления
  /// отменяются по прежним id.
  Future<void> _applyReminders(
    int programId,
    Map<int, WorkoutReminder> previousByDayKey,
  ) async {
    final program = await _repository.getById(programId);
    final days = await _repository.getDays(programId);
    for (var i = 0; i < _days.length && i < days.length; i++) {
      final draft = _days[i];
      final day = days[i];
      final wantReminder = draft.dayOfWeek != null && draft.reminder != null;
      final hadReminder = previousByDayKey.containsKey(draft.key);
      try {
        if (wantReminder) {
          if (hadReminder) {
            await _reminderRepository.deleteForDay(draft.key);
            await _reminderService.cancel(draft.key);
          }
          final saved = await _reminderRepository.saveForDay(
            day.id!,
            hour: draft.reminder!.hour,
            minute: draft.reminder!.minute,
            enabled: true,
          );
          await _reminderService.schedule(
            saved,
            dayOfWeek: draft.dayOfWeek!,
            programName: program?.name ?? '',
            dayNumber: day.dayIndex + 1,
          );
        } else if (hadReminder) {
          await _reminderRepository.deleteForDay(draft.key);
          await _reminderService.cancel(draft.key);
        }
      } on Exception catch (e, st) {
        log(
          'Не удалось обновить напоминание дня ${day.id}',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Сохраняет черновик программы и открывает экран наполнения дня.
  Future<void> _openDayFill(int dayIndex) async {
    final saved = await _persist();
    final programId = saved?.id;
    if (programId != null && mounted) {
      await context.push('/programs/$programId/day/$dayIndex');
      if (mounted) {
        await _refreshFilledDays();
      }
    }
  }

  /// Пересчитывает, какие дни заполнены, после возврата из наполнения дня.
  Future<void> _refreshFilledDays() async {
    final programId = _programId;
    if (programId == null) {
      if (mounted) {
        setState(_filledDayIndexes.clear);
      }
      return;
    }
    final detail = await _repository.getProgram(programId);
    if (!mounted) {
      return;
    }
    setState(() {
      _filledDayIndexes
        ..clear()
        ..addAll({
          for (final day in detail?.days ?? const <ProgramDayDetail>[])
            if (day.mainExercises.any((e) => !e.isAlternative))
              day.day.dayIndex,
        });
    });
  }

  /// Индекс первого дня без основного упражнения или `null`, если все заполнены.
  int? _firstUnfilledDayIndex() {
    for (var i = 0; i < _days.length; i++) {
      if (!_filledDayIndexes.contains(i)) {
        return i;
      }
    }
    return null;
  }

  /// Создаёт или обновляет черновик программы. Возвращает `null` при
  /// невалидной форме.
  Future<Program?> _persist() async {
    if (!_formKey.currentState!.validate()) {
      return null;
    }
    final now = DateTime.now();
    final program = Program(
      id: _programId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      daysCount: _days.length,
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );
    final days = [
      for (var i = 0; i < _days.length; i++)
        ProgramDay(programId: 0, dayIndex: i, dayOfWeek: _days[i].dayOfWeek),
    ];
    final saved = _programId == null
        ? await _repository.create(program, days)
        : await _repository.update(program, days: days);
    _programId = saved.id;
    return saved;
  }

  /// Проверяет полную структуру черновика (дни + упражнения).
  ///
  /// Возвращает список ошибок или `null`, если структура валидна.
  Future<List<String>?> _structureErrors() async {
    final now = DateTime.now();
    final program = Program(
      id: _programId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      daysCount: _days.length,
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );
    final days = [
      for (var i = 0; i < _days.length; i++)
        ProgramDay(programId: 0, dayIndex: i, dayOfWeek: _days[i].dayOfWeek),
    ];
    final exercisesByDayIndex = await _loadExercisesByDayIndex();
    final result = ProgramValidator().validate(
      program: program,
      days: days,
      exercisesByDayIndex: exercisesByDayIndex,
    );
    return result.isValid ? null : result.errors;
  }

  /// Загружает сохранённые упражнения программы по индексу дня.
  Future<Map<int, List<ProgramDayExercise>>> _loadExercisesByDayIndex() async {
    final programId = _programId;
    if (programId == null) {
      return {};
    }
    final detail = await _repository.getProgram(programId);
    if (detail == null) {
      return {};
    }
    return {
      for (final day in detail.days)
        day.day.dayIndex: [...day.mainExercises, ...day.alternativeExercises],
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final errors = await _structureErrors();
    if (errors != null) {
      if (!mounted) {
        return;
      }
      final exit = await showProgramValidationDialog(context, errors: errors);
      if (exit == true) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final previousReminders = await _previousReminders();
      final saved = await _persist();
      if (saved != null && mounted) {
        await _applyReminders(saved.id!, previousReminders);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = _programId != null;
    final nextDay = _firstUnfilledDayIndex();
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.programEdit : l10n.programNew),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                buildDefaultDragHandles: false,
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _nameField(l10n),
                    const SizedBox(height: 16),
                    _descriptionField(l10n),
                    const SizedBox(height: 16),
                    _daysCountField(l10n),
                    const SizedBox(height: 16),
                  ],
                ),
                itemCount: _days.length,
                onReorderItem: _onReorder,
                itemBuilder: (context, index) => _buildDayTile(l10n, index),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving
                ? null
                : nextDay == null
                ? _save
                : () => _openDayFill(nextDay),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    nextDay == null
                        ? l10n.programBuilderSave
                        : l10n.programBuilderFillNextDay(nextDay + 1),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _nameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.programBuilderName,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? l10n.programBuilderNameRequired
          : null,
    );
  }

  Widget _descriptionField(AppLocalizations l10n) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: l10n.programBuilderDescription,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _daysCountField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.programBuilderDaysCount,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (var count = 1; count <= 7; count++)
              ButtonSegment(value: count, label: Text('$count')),
          ],
          selected: {_days.length},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => _setDaysCount(selection.first),
        ),
      ],
    );
  }

  Widget _buildDayTile(AppLocalizations l10n, int index) {
    final day = _days[index];
    return Padding(
      key: ValueKey('day-${day.key}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _openDayFill(index),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator),
          ),
          title: Text(l10n.programBuilderDay(index + 1)),
          subtitle: Text(_weekdayLabel(l10n, day.dayOfWeek)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.programBuilderAddExercise,
                icon: const Icon(Icons.playlist_add),
                onPressed: () => _openDayFill(index),
              ),
              IconButton(
                tooltip: l10n.programBuilderDaySettings,
                icon: const Icon(Icons.tune),
                onPressed: () => _openDaySettings(day),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySettingsDialog extends StatefulWidget {
  const _DaySettingsDialog({this.dayOfWeek, this.reminder});

  final int? dayOfWeek;
  final WorkoutReminder? reminder;

  @override
  State<_DaySettingsDialog> createState() => _DaySettingsDialogState();
}

class _DaySettingsDialogState extends State<_DaySettingsDialog> {
  late int? _selected;
  late bool _remindEnabled;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _selected = widget.dayOfWeek;
    final reminder = widget.reminder;
    _remindEnabled = reminder != null;
    _time = reminder != null
        ? TimeOfDay(hour: reminder.hour, minute: reminder.minute)
        : const TimeOfDay(hour: 9, minute: 0);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasWeekday = _selected != null;
    return AlertDialog(
      title: Text(l10n.programBuilderDaySettings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int?>(
            initialValue: _selected,
            decoration: InputDecoration(
              labelText: l10n.programBuilderDayWeekday,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.programBuilderDayNoWeekday),
              ),
              for (var day = 1; day <= 7; day++)
                DropdownMenuItem(
                  value: day,
                  child: Text(_weekdayLabel(l10n, day)),
                ),
            ],
            onChanged: (value) => setState(() {
              _selected = value;
              if (value == null) {
                _remindEnabled = false;
              }
            }),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reminderToggle),
            value: _remindEnabled,
            onChanged: hasWeekday
                ? (value) => setState(() => _remindEnabled = value)
                : null,
          ),
          ListTile(
            enabled: _remindEnabled,
            leading: const Icon(Icons.access_time),
            title: Text(l10n.reminderTime),
            subtitle: Text(
              MaterialLocalizations.of(
                context,
              ).formatTimeOfDay(_time, alwaysUse24HourFormat: true),
            ),
            onTap: _remindEnabled ? _pickTime : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            DaySettings(
              dayOfWeek: _selected,
              reminder: _remindEnabled && hasWeekday
                  ? WorkoutReminder(
                      programDayId: 0,
                      hour: _time.hour,
                      minute: _time.minute,
                      enabled: true,
                    )
                  : null,
            ),
          ),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

String _weekdayLabel(AppLocalizations l10n, int? dayOfWeek) =>
    switch (dayOfWeek) {
      1 => l10n.weekdayMon,
      2 => l10n.weekdayTue,
      3 => l10n.weekdayWed,
      4 => l10n.weekdayThu,
      5 => l10n.weekdayFri,
      6 => l10n.weekdaySat,
      7 => l10n.weekdaySun,
      _ => l10n.programBuilderDayNoWeekday,
    };
