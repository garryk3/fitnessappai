import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/validators/program_day_exercise_validator.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_validation_dialog.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Второй шаг конструктора программы: наполнение тренировочного дня.
///
/// Позволяет добавлять, удалять и переставлять упражнения основного и
/// альтернативного наборов, а также следить за задействованными мышцами.
class ProgramDayBuilderScreen extends StatefulWidget {
  const ProgramDayBuilderScreen({
    super.key,
    required this.programId,
    required this.dayIndex,
    this.repository,
    this.exerciseRepository,
  });

  final int programId;

  /// Порядковый номер дня программы (0-based).
  final int dayIndex;
  final ProgramRepository? repository;
  final ExerciseRepository? exerciseRepository;

  @override
  State<ProgramDayBuilderScreen> createState() =>
      _ProgramDayBuilderScreenState();
}

/// Позиция дня с уникальным стабильным ключом для реордера.
class _ItemDraft {
  const _ItemDraft({required this.key, required this.item});

  final String key;
  final ProgramDayExercise item;
}

class _ProgramDayBuilderScreenState extends State<ProgramDayBuilderScreen> {
  late final ProgramRepository _repository;
  late final ExerciseRepository _exerciseRepository;

  ProgramDetail? _detail;
  ProgramDayDetail? _currentDay;
  final List<_ItemDraft> _mainItems = [];
  final List<_ItemDraft> _altItems = [];
  bool _isAlternative = false;
  bool _loading = true;
  bool _saving = false;
  int _nextTempKey = 0;

  final Map<int, Exercise> _exercisesById = {};
  final Map<int, MuscleGroup> _muscleGroupsById = {};
  final List<MuscleGroup> _allMuscleGroups = [];
  final Map<int, List<ExerciseMuscle>> _musclesByExercise = {};

  List<_ItemDraft> get _currentItems => _isAlternative ? _altItems : _mainItems;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ProgramRepository>();
    _exerciseRepository =
        widget.exerciseRepository ?? locator.get<ExerciseRepository>();
    _load();
  }

  Future<void> _load() async {
    final detail = await _repository.getProgram(widget.programId);
    if (detail == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    final current = detail.days.firstWhereOrNull(
      (d) => d.day.dayIndex == widget.dayIndex,
    );
    final exercises = await _exerciseRepository.getAll();
    final groups = await _exerciseRepository.getAllMuscleGroups();

    if (!mounted) {
      return;
    }
    setState(() {
      _detail = detail;
      _currentDay = current;
      _mainItems
        ..clear()
        ..addAll([
          for (final item
              in current?.mainExercises ?? const <ProgramDayExercise>[])
            _ItemDraft(key: 'saved-${item.id}', item: item),
        ]);
      _altItems
        ..clear()
        ..addAll([
          for (final item
              in current?.alternativeExercises ?? const <ProgramDayExercise>[])
            _ItemDraft(key: 'saved-${item.id}', item: item),
        ]);
      _exercisesById
        ..clear()
        ..addEntries(exercises.map((e) => MapEntry(e.id!, e)));
      _muscleGroupsById
        ..clear()
        ..addEntries(groups.map((g) => MapEntry(g.id!, g)));
      _allMuscleGroups
        ..clear()
        ..addAll(groups);
      _loading = false;
    });

    for (final item in [..._mainItems, ..._altItems]) {
      final exerciseId = item.item.exerciseId;
      if (exerciseId != null) {
        await _loadMusclesFor(exerciseId);
      }
    }
  }

  Future<void> _loadMusclesFor(int exerciseId) async {
    if (_musclesByExercise.containsKey(exerciseId)) {
      return;
    }
    final muscles = await _exerciseRepository.getMuscles(exerciseId);
    if (mounted) {
      setState(() => _musclesByExercise[exerciseId] = muscles);
    }
  }

  Map<String, double> get _highlights {
    final highlights = <String, double>{};
    for (final draft in _currentItems) {
      final exerciseId = draft.item.exerciseId;
      if (exerciseId == null) {
        continue;
      }
      for (final link in _musclesByExercise[exerciseId] ?? const []) {
        final group = _muscleGroupsById[link.muscleGroupId];
        if (group == null) {
          continue;
        }
        final intensity = link.intensity == MuscleIntensity.primary ? 1.0 : 0.5;
        final current = highlights[group.regionKey] ?? 0.0;
        highlights[group.regionKey] = current > intensity ? current : intensity;
      }
    }
    return highlights;
  }

  Future<void> _addExercise() async {
    final musclesByExercise = await _exerciseRepository
        .muscleGroupsByExercise();
    if (!mounted) {
      return;
    }
    final selected = await showDialog<Exercise>(
      context: context,
      builder: (context) => _ExercisePickerDialog(
        exercises: _exercisesById.values.toList(),
        muscleGroups: _allMuscleGroups,
        musclesByExercise: musclesByExercise,
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    final draft = _ItemDraft(
      key: 'new-${_nextTempKey++}',
      item: ProgramDayExercise(
        dayId: _currentDay?.day.id ?? 0,
        exerciseId: selected.id,
        orderIndex: _currentItems.length,
        isAlternative: _isAlternative,
      ),
    );
    setState(() {
      _currentItems.add(draft);
    });
    await _loadMusclesFor(selected.id!);
    if (mounted) {
      await _openExerciseParams(draft);
    }
  }

  void _removeItem(_ItemDraft draft) {
    setState(() {
      _currentItems.removeWhere((d) => identical(d, draft));
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _currentItems.removeAt(oldIndex);
      _currentItems.insert(newIndex, item);
    });
  }

  Future<void> _openExerciseParams(_ItemDraft draft) async {
    var item = draft.item;
    if (item.id == null) {
      final exerciseId = item.exerciseId;
      if (exerciseId == null) {
        return;
      }
      final persisted = await _repository.addExerciseToDay(
        item.dayId,
        exerciseId,
        isAlternative: item.isAlternative,
      );
      if (!mounted) {
        return;
      }
      setState(() => _replaceDraft(draft, persisted));
      item = persisted;
    }
    final updated = await context.push<ProgramDayExercise>(
      '/program-day/${item.id}/exercise-params',
    );
    if (updated != null && mounted) {
      setState(() => _replaceItem(item.id!, updated));
    }
  }

  void _replaceDraft(_ItemDraft draft, ProgramDayExercise item) {
    void replaceIn(List<_ItemDraft> list) {
      final index = list.indexWhere((d) => identical(d, draft));
      if (index != -1) {
        list[index] = _ItemDraft(key: list[index].key, item: item);
      }
    }

    replaceIn(_mainItems);
    replaceIn(_altItems);
  }

  void _replaceItem(int id, ProgramDayExercise updated) {
    void replaceIn(List<_ItemDraft> list) {
      final index = list.indexWhere((d) => d.item.id == id);
      if (index != -1) {
        list[index] = _ItemDraft(key: list[index].key, item: updated);
      }
    }

    replaceIn(_mainItems);
    replaceIn(_altItems);
  }

  int _filledDaysCount() {
    var filled = 0;
    for (final day in _detail?.days ?? const <ProgramDayDetail>[]) {
      final items = day.day.dayIndex == widget.dayIndex
          ? _mainItems.map((d) => d.item).toList()
          : day.mainExercises;
      if (items.any((e) => !e.isAlternative)) {
        filled++;
      }
    }
    return filled;
  }

  Future<void> _save() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }
    final items = [..._mainItems, ..._altItems].map((d) => d.item).toList();
    for (final item in items) {
      final exercise = _exercisesById[item.exerciseId];
      final result = exercise == null
          ? null
          : ProgramDayExerciseValidator().validate(item, exercise.type);
      if (result == null || !result.isValid) {
        _showMessage(l10n.programBuilderMetricsInvalid);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final exercisesByDayIndex = <int, List<ProgramDayExercise>>{};
      for (final day in detail.days) {
        final index = day.day.dayIndex;
        exercisesByDayIndex[index] = index == widget.dayIndex
            ? items
            : [...day.mainExercises, ...day.alternativeExercises];
      }
      await _repository.update(
        detail.program.copyWith(updatedAt: DateTime.now()),
        exercisesByDayIndex: exercisesByDayIndex,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ProgramValidationException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        final exit = await showProgramValidationDialog(
          context,
          errors: e.errors,
        );
        if (exit == true && mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.programBuilderDay(widget.dayIndex + 1))),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton(
              heroTag: 'program-day-builder-fab',
              tooltip: l10n.programBuilderAddExercise,
              onPressed: _addExercise,
              child: const Icon(Icons.add),
            ),
      body: _buildBody(),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final detail = _detail;
    final currentDay = _currentDay;
    if (detail == null || currentDay == null) {
      return Center(child: Text(l10n.programBuilderEmptyDay));
    }
    return Column(
      children: [
        _buildProgress(detail),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(l10n.programBuilderMainSet),
              ),
              ButtonSegment(
                value: true,
                label: Text(l10n.programBuilderAlternativeSet),
              ),
            ],
            selected: {_isAlternative},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _isAlternative = selection.first),
          ),
        ),
        Expanded(child: _buildItemsList()),
        _MusclePanel(
          highlights: _highlights,
          title: l10n.programBuilderMuscles,
        ),
      ],
    );
  }

  Widget _buildProgress(ProgramDetail detail) {
    final total = detail.days.length;
    final filled = _filledDaysCount();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.programBuilderDayProgress(filled, total),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: total == 0 ? 0 : filled / total),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_currentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(l10n.programBuilderEmptyDay, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      buildDefaultDragHandles: false,
      itemCount: _currentItems.length,
      onReorderItem: _onReorder,
      itemBuilder: (context, index) =>
          _buildItemTile(index, _currentItems[index]),
    );
  }

  Widget _buildItemTile(int index, _ItemDraft draft) {
    final item = draft.item;
    final exercise = _exercisesById[item.exerciseId];
    final type = exercise?.type;
    return Padding(
      key: ValueKey(draft.key),
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _openExerciseParams(draft),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator),
          ),
          title: Text(exercise?.name ?? ''),
          subtitle: Text(
            _metricsSummary(item, type),
            style: type == null ? Theme.of(context).textTheme.bodySmall : null,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.programBuilderPickExercise,
                icon: const Icon(Icons.tune),
                onPressed: () => _openExerciseParams(draft),
              ),
              IconButton(
                tooltip: l10n.commonDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeItem(draft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _metricsSummary(ProgramDayExercise item, ExerciseType? type) {
    final parts = <String>[];
    switch (type) {
      case ExerciseType.strength:
        if (item.sets != null) {
          parts.add('${item.sets} × ${item.reps ?? '?'}');
        }
        if (item.weightKg != null) {
          parts.add('${_trimNumber(item.weightKg!)} кг');
        }
      case ExerciseType.bodyweight:
        if (item.sets != null) {
          parts.add('${item.sets} × ${item.reps ?? '?'}');
        }
      case ExerciseType.plank:
        if (item.sets != null) {
          parts.add('${item.sets} × ${item.durationSeconds ?? '?'} с');
        }
      case ExerciseType.running:
        if (item.distanceMeters != null) {
          parts.add('${_trimNumber(item.distanceMeters! / 1000)} км');
        }
        if (item.durationSeconds != null) {
          parts.add('${(item.durationSeconds! / 60).round()} мин');
        }
      case null:
        break;
    }
    if (item.restSeconds != null) {
      parts.add('отдых ${item.restSeconds} с');
    }
    return parts.isEmpty ? l10n.programBuilderNoMetrics : parts.join(' · ');
  }

  String _trimNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

/// Диалог выбора упражнения из каталога для добавления в день.
///
/// Позволяет отфильтровать список по мышечной группе.
class _ExercisePickerDialog extends StatefulWidget {
  const _ExercisePickerDialog({
    required this.exercises,
    required this.muscleGroups,
    required this.musclesByExercise,
  });

  final List<Exercise> exercises;
  final List<MuscleGroup> muscleGroups;

  /// Карта «id упражнения → его мышечные группы».
  final Map<int, List<MuscleGroup>> musclesByExercise;

  @override
  State<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<_ExercisePickerDialog> {
  MuscleGroup? _selectedGroup;

  List<Exercise> get _filtered {
    final group = _selectedGroup;
    if (group == null) {
      return widget.exercises;
    }
    return [
      for (final exercise in widget.exercises)
        if (widget.musclesByExercise[exercise.id]?.any(
              (g) => g.id == group.id,
            ) ??
            false)
          exercise,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.programBuilderPickExercise),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            DropdownButtonFormField<MuscleGroup?>(
              initialValue: _selectedGroup,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.programBuilderMuscleFilter,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem<MuscleGroup?>(
                  value: null,
                  child: Text(l10n.commonAll),
                ),
                for (final group in widget.muscleGroups)
                  DropdownMenuItem<MuscleGroup?>(
                    value: group,
                    child: Text(group.labelRu),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedGroup = value),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(child: Text(l10n.exerciseListEmpty))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = _filtered[index];
                        return ListTile(
                          title: Text(exercise.name),
                          subtitle: Text(_typeLabel(l10n, exercise.type)),
                          onTap: () => Navigator.of(context).pop(exercise),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

/// Панель схемы мускулатуры: спереди и сзади.
class _MusclePanel extends StatelessWidget {
  const _MusclePanel({required this.highlights, required this.title});

  final Map<String, double> highlights;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MuscleDiagram(
              view: MuscleView.front,
              highlights: highlights,
              size: const Size(80, 160),
            ),
            const SizedBox(width: 16),
            MuscleDiagram(
              view: MuscleView.back,
              highlights: highlights,
              size: const Size(80, 160),
            ),
          ],
        ),
      ],
    );
  }
}

String _typeLabel(AppLocalizations l10n, ExerciseType type) => switch (type) {
  ExerciseType.strength => l10n.exerciseTypeStrength,
  ExerciseType.bodyweight => l10n.exerciseTypeBodyweight,
  ExerciseType.plank => l10n.exerciseTypePlank,
  ExerciseType.running => l10n.exerciseTypeRunning,
};
