import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
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

/// Черновик дня с уникальным стабильным ключом для реордера.
class _DayDraft {
  _DayDraft(this.key, {this.dayOfWeek});

  final int key;
  int? dayOfWeek;
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  late final ProgramRepository _repository;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_DayDraft> _days = [];
  int _nextDayKey = -1;
  bool _loading = true;
  bool _saving = false;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ProgramRepository>();
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
    final selected = await showDialog<int?>(
      context: context,
      builder: (context) => _DaySettingsDialog(dayOfWeek: day.dayOfWeek),
    );
    if (selected != null && mounted) {
      setState(() => day.dayOfWeek = selected);
    }
  }

  /// Сохраняет черновик программы и открывает экран наполнения дня.
  Future<void> _openDayFill(int dayIndex) async {
    var programId = widget.programId;
    if (programId == null) {
      final saved = await _persist();
      programId = saved?.id;
    }
    if (programId != null && mounted) {
      context.push('/programs/$programId/day/$dayIndex');
    }
  }

  /// Создаёт или обновляет черновик программы. Возвращает `null` при
  /// невалидной форме.
  Future<Program?> _persist() async {
    if (!_formKey.currentState!.validate()) {
      return null;
    }
    final now = DateTime.now();
    final program = Program(
      id: widget.programId,
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
    if (widget.programId == null) {
      return _repository.create(program, days);
    }
    return _repository.update(program, days: days);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await _persist();
      if (saved != null && mounted) {
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
    final isEditing = widget.programId != null;
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
                    const SizedBox(height: 12),
                    _descriptionField(l10n),
                    const SizedBox(height: 16),
                    _daysCountField(l10n),
                    const SizedBox(height: 8),
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
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.programBuilderSave),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _openDaySettings(day),
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
  const _DaySettingsDialog({this.dayOfWeek});

  final int? dayOfWeek;

  @override
  State<_DaySettingsDialog> createState() => _DaySettingsDialogState();
}

class _DaySettingsDialogState extends State<_DaySettingsDialog> {
  late int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.dayOfWeek;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.programBuilderDaySettings),
      content: DropdownButtonFormField<int?>(
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
            DropdownMenuItem(value: day, child: Text(_weekdayLabel(l10n, day))),
        ],
        onChanged: (value) => setState(() => _selected = value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
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
