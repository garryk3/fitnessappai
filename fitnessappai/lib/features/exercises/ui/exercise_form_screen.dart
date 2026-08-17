import 'package:flutter/material.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Форма создания и редактирования упражнения.
///
/// [exerciseId] равен `null` при создании нового упражнения.
class ExerciseFormScreen extends StatefulWidget {
  const ExerciseFormScreen({
    super.key,
    this.exerciseId,
    this.repository,
    this.mediaStore,
    this.mediaCache,
  });

  final int? exerciseId;
  final ExerciseRepository? repository;
  final MediaStore? mediaStore;
  final MediaCache? mediaCache;

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  late final ExerciseRepository _repository;
  late final MediaStore _mediaStore;
  late final MediaCache _mediaCache;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final List<TextEditingController> _mistakeControllers = [];
  final Map<int, MuscleIntensity> _muscleSelections = {};
  String? _musclesError;
  final Set<int> _selectedContraindicationIds = {};

  ExerciseType _type = ExerciseType.strength;
  String? _thumbnailPath;
  String? _animationPath;
  bool _saving = false;
  bool _isCustom = true;
  bool _hideOptional = false;
  DateTime? _createdAt;

  List<MuscleGroup> _allMuscles = const [];
  List<ContraindicationTag> _allTags = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ExerciseRepository>();
    _mediaStore = widget.mediaStore ?? locator.get<MediaStore>();
    _mediaCache = widget.mediaCache ?? locator.get<MediaCache>();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    for (final controller in _mistakeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final muscles = await _repository.getAllMuscleGroups();
    final tags = await _repository.getAllContraindicationTags();
    _allMuscles = muscles;
    _allTags = tags;

    final exerciseId = widget.exerciseId;
    if (exerciseId != null) {
      final exercise = await _repository.getById(exerciseId);
      if (exercise != null) {
        _populate(exercise);
      }
      final links = await _repository.getMuscles(exerciseId);
      for (final link in links) {
        _muscleSelections[link.muscleGroupId] = link.intensity;
      }
      final contraindications = await _repository.getContraindications(
        exerciseId,
      );
      for (final tag in contraindications) {
        if (tag.id != null) {
          _selectedContraindicationIds.add(tag.id!);
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _populate(Exercise exercise) {
    _nameController.text = exercise.name;
    _descriptionController.text = exercise.description;
    _instructionsController.text = exercise.instructions;
    _type = exercise.type;
    _thumbnailPath = exercise.thumbnailPath;
    _animationPath = exercise.animationPath;
    _isCustom = exercise.isCustom;
    _hideOptional = exercise.hideOptional;
    _createdAt = exercise.createdAt;
    for (final mistake in exercise.commonMistakes) {
      _mistakeControllers.add(TextEditingController(text: mistake));
    }
  }

  Map<String, double> get _highlights {
    final result = <String, double>{};
    for (final entry in _muscleSelections.entries) {
      final muscle = _muscleById(entry.key);
      if (muscle != null) {
        result[muscle.regionKey] = _intensityValue(entry.value);
      }
    }
    return result;
  }

  MuscleGroup? _muscleById(int id) {
    for (final muscle in _allMuscles) {
      if (muscle.id == id) {
        return muscle;
      }
    }
    return null;
  }

  double _intensityValue(MuscleIntensity intensity) =>
      intensity == MuscleIntensity.primary ? 1.0 : 0.5;

  void _pickAnimation() async {
    try {
      final path = await _mediaStore.importFromPicker(
        fileType: MediaFileType.image,
      );
      if (path != null && mounted) {
        setState(() => _animationPath = path);
      }
    } on MediaImportException {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exerciseFormAnimationError)));
    }
  }

  void _pickThumbnail() async {
    try {
      final path = await _mediaStore.importFromPicker(
        fileType: MediaFileType.image,
      );
      if (path != null && mounted) {
        setState(() => _thumbnailPath = path);
      }
    } on MediaImportException {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exerciseFormAnimationError)));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_muscleSelections.isEmpty) {
      setState(
        () => _musclesError = AppLocalizations.of(
          context,
        ).exerciseFormMusclesRequired,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final exercise = Exercise(
        id: widget.exerciseId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        instructions: _instructionsController.text.trim(),
        commonMistakes: [
          for (final controller in _mistakeControllers)
            if (controller.text.trim().isNotEmpty) controller.text.trim(),
        ],
        type: _type,
        thumbnailPath: _thumbnailPath,
        animationPath: _animationPath,
        isCustom: _isCustom,
        hideOptional: _hideOptional,
        createdAt: _createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final muscles = [
        for (final entry in _muscleSelections.entries)
          ExerciseMuscle(
            exerciseId: 0,
            muscleGroupId: entry.key,
            intensity: entry.value,
          ),
      ];

      final id = widget.exerciseId;
      if (id == null) {
        final created = await _repository.create(exercise, muscles);
        await _repository.setContraindications(
          created.id!,
          _selectedContraindicationIds.toList(),
        );
      } else {
        await _repository.update(exercise, muscles: muscles);
        await _repository.setContraindications(
          id,
          _selectedContraindicationIds.toList(),
        );
      }
      if (mounted) {
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
    final isEditing = widget.exerciseId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.exerciseEdit : l10n.exerciseNew),
      ),
      body: _allMuscles.isEmpty && widget.exerciseId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _nameField(l10n),
                  const SizedBox(height: 16),
                  _typeField(l10n),
                  const SizedBox(height: 16),
                  _descriptionField(l10n),
                  const SizedBox(height: 16),
                  _instructionsField(l10n),
                  const SizedBox(height: 16),
                  _mistakesEditor(l10n),
                  const SizedBox(height: 16),
                  _musclesEditor(l10n),
                  const SizedBox(height: 16),
                  _contraindicationsEditor(l10n),
                  const SizedBox(height: 16),
                  _thumbnailEditor(l10n),
                  const SizedBox(height: 16),
                  _animationEditor(l10n),
                  const SizedBox(height: 16),
                  _hideOptionalField(l10n),
                ],
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
                : Text(l10n.exerciseFormSave),
          ),
        ),
      ),
    );
  }

  Widget _nameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        label: Text.rich(
          TextSpan(
            text: l10n.exerciseFormName,
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? l10n.exerciseFormNameRequired
          : null,
    );
  }

  Widget _typeField(AppLocalizations l10n) {
    return DropdownButtonFormField<ExerciseType>(
      initialValue: _type,
      decoration: InputDecoration(
        labelText: l10n.exerciseFormType,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final type in ExerciseType.values)
          DropdownMenuItem(value: type, child: Text(_typeLabel(l10n, type))),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _type = value);
        }
      },
    );
  }

  Widget _descriptionField(AppLocalizations l10n) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: l10n.exerciseFormDescription,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _instructionsField(AppLocalizations l10n) {
    return TextFormField(
      controller: _instructionsController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: l10n.exerciseFormTechnique,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _mistakesEditor(AppLocalizations l10n) {
    return _Section(
      title: l10n.exerciseFormMistakes,
      child: Column(
        children: [
          for (var i = 0; i < _mistakeControllers.length; i++)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mistakeControllers[i],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.commonDelete,
                  onPressed: () => setState(() {
                    _mistakeControllers.removeAt(i).dispose();
                  }),
                ),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(
                () => _mistakeControllers.add(TextEditingController()),
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.exerciseFormMistakeAdd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _musclesEditor(AppLocalizations l10n) {
    return _Section(
      title: l10n.exerciseFormMuscles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MuscleDiagram(
                view: MuscleView.front,
                highlights: _highlights,
                size: const Size(120, 240),
              ),
              MuscleDiagram(
                view: MuscleView.back,
                highlights: _highlights,
                size: const Size(120, 240),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final group in _groupedMuscles) ..._muscleGroupRows(l10n, group),
          if (_musclesError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _musclesError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Мышечные группы, сгруппированные по [MuscleGroup.parentKey]: первым идёт
  /// родитель, за ним — его подгруппы.
  List<List<MuscleGroup>> get _groupedMuscles {
    final parents = _allMuscles
        .where((m) => m.parentKey == null)
        .toList(growable: false);
    final children = _allMuscles
        .where((m) => m.parentKey != null)
        .toList(growable: false);
    return [
      for (final parent in parents)
        [parent, ...children.where((c) => c.parentKey == parent.key)],
    ];
  }

  /// Строки выбора интенсивности для группы мышц. Подгруппы выводятся
  /// с отступом под родительской строкой.
  List<Widget> _muscleGroupRows(
    AppLocalizations l10n,
    List<MuscleGroup> group,
  ) {
    return [
      for (var i = 0; i < group.length; i++)
        Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 16, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group[i].labelRu,
                  style: i == 0
                      ? null
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _intensityChip(
                        l10n.exerciseFormMusclePrimary,
                        MuscleIntensity.primary,
                        group[i].id!,
                      ),
                      const SizedBox(width: 4),
                      _intensityChip(
                        l10n.exerciseFormMuscleSecondary,
                        MuscleIntensity.secondary,
                        group[i].id!,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _intensityChip(String label, MuscleIntensity intensity, int muscleId) {
    final selected = _muscleSelections[muscleId] == intensity;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        if (selected) {
          _muscleSelections.remove(muscleId);
        } else {
          _muscleSelections[muscleId] = intensity;
        }
        _musclesError = null;
      }),
    );
  }

  Widget _contraindicationsEditor(AppLocalizations l10n) {
    return _Section(
      title: l10n.exerciseFormContraindications,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in _allTags)
            FilterChip(
              label: Text(tag.labelRu),
              selected: _selectedContraindicationIds.contains(tag.id),
              onSelected: (selected) => setState(() {
                if (selected) {
                  _selectedContraindicationIds.add(tag.id!);
                } else {
                  _selectedContraindicationIds.remove(tag.id);
                }
              }),
            ),
        ],
      ),
    );
  }

  Widget _thumbnailEditor(AppLocalizations l10n) {
    return _Section(
      title: l10n.exerciseFormThumbnail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_thumbnailPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: _mediaCache.imageFor(_thumbnailPath!),
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickThumbnail,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    l10n.exerciseFormThumbnailPick,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_thumbnailPath != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.exerciseFormThumbnailRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _thumbnailPath = null),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _animationEditor(AppLocalizations l10n) {
    return _Section(
      title: l10n.exerciseFormAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_animationPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: _mediaCache.imageFor(_animationPath!),
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 160,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAnimation,
                  icon: const Icon(Icons.video_file_outlined),
                  label: Text(
                    l10n.exerciseFormAnimationPick,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_animationPath != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.exerciseFormAnimationRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _animationPath = null),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _hideOptionalField(AppLocalizations l10n) {
    return CheckboxListTile(
      value: _hideOptional,
      onChanged: (value) => setState(() => _hideOptional = value ?? false),
      title: Text(l10n.exerciseFormHideOptional),
      subtitle: Text(l10n.exerciseFormHideOptionalHelp),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

String _typeLabel(AppLocalizations l10n, ExerciseType type) => switch (type) {
  ExerciseType.strength => l10n.exerciseTypeStrength,
  ExerciseType.bodyweight => l10n.exerciseTypeBodyweight,
  ExerciseType.plank => l10n.exerciseTypePlank,
  ExerciseType.running => l10n.exerciseTypeRunning,
};

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
