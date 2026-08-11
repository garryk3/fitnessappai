import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_detail_controller.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран деталей упражнения: анимация, описание, техника, мышцы,
/// противопоказания; редактирование и удаление для кастомных упражнений.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.repository,
    this.mediaCache,
    this.profileRepository,
  });

  final int exerciseId;
  final ExerciseRepository? repository;
  final MediaCache? mediaCache;
  final UserProfileRepository? profileRepository;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final ExerciseDetailController _controller;
  late final ExerciseRepository _repository;
  late final MediaCache _mediaCache;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ExerciseRepository>();
    _mediaCache = widget.mediaCache ?? locator.get<MediaCache>();
    _controller = ExerciseDetailController(
      _repository,
      widget.exerciseId,
      profileRepository:
          widget.profileRepository ?? locator.get<UserProfileRepository>(),
    );
    _controller.load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final data = _controller.data.value;
    if (data == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exerciseDetailDeleteConfirm(data.exercise.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _repository.delete(widget.exerciseId);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final data = _controller.data.value;
        final canEdit = data?.exercise.isCustom ?? false;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.exerciseDetail),
            actions: [
              if (canEdit) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.commonEdit,
                  onPressed: () =>
                      context.push('/exercises/${widget.exerciseId}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
          body: SignalBuilder(
            builder: (context) {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (data == null) {
                return Center(child: Text(l10n.exerciseDetailNotFound));
              }
              return _buildContent(context, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ExerciseDetailData data) {
    final l10n = AppLocalizations.of(context);
    final exercise = data.exercise;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: _ExercisePreview(exercise: exercise, mediaCache: _mediaCache),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            exercise.name,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(child: _TypeBadge(type: exercise.type)),
        if (exercise.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: l10n.exerciseDetailDescription,
            child: Text(exercise.description),
          ),
        ],
        if (exercise.instructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: l10n.exerciseDetailTechnique,
            child: Text(exercise.instructions),
          ),
        ],
        if (exercise.commonMistakes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: l10n.exerciseDetailMistakes,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final mistake in exercise.commonMistakes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(mistake)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (data.hasMuscles) ...[
          const SizedBox(height: 16),
          _MusclesSection(highlights: data.highlights, muscles: data.muscles),
        ],
        if (data.hasContraindications) ...[
          const SizedBox(height: 16),
          _ContraindicationsSection(
            tags: data.contraindications,
            warnings: data.userWarnings,
          ),
        ],
      ],
    );
  }
}

class _ExercisePreview extends StatelessWidget {
  const _ExercisePreview({required this.exercise, required this.mediaCache});

  final Exercise exercise;
  final MediaCache mediaCache;

  @override
  Widget build(BuildContext context) {
    const height = 220.0;
    final path = exercise.animationPath ?? exercise.thumbnailPath;
    if (path == null) {
      return _placeholder(context, height);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image(
        image: mediaCache.imageFor(path),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _placeholder(context, height),
      ),
    );
  }

  Widget _placeholder(BuildContext context, double height) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.fitness_center,
        size: 56,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final ExerciseType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (type) {
      ExerciseType.strength => l10n.exerciseTypeStrength,
      ExerciseType.plank => l10n.exerciseTypePlank,
      ExerciseType.running => l10n.exerciseTypeRunning,
    };
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

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
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MusclesSection extends StatelessWidget {
  const _MusclesSection({required this.highlights, required this.muscles});

  final Map<String, double> highlights;
  final List<MuscleGroup> muscles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.exerciseDetailMuscles,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MuscleDiagram(
                view: MuscleView.front,
                highlights: highlights,
                size: const Size(130, 260),
              ),
              MuscleDiagram(
                view: MuscleView.back,
                highlights: highlights,
                size: const Size(130, 260),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final muscle in muscles) Chip(label: Text(muscle.labelRu)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContraindicationsSection extends StatelessWidget {
  const _ContraindicationsSection({required this.tags, required this.warnings});

  final List<ContraindicationTag> tags;
  final List<ContraindicationTag> warnings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final warningKeys = {for (final tag in warnings) tag.key};
    return _Section(
      title: l10n.contraindications,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warnings.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.contraindicationWarningForYou,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                Chip(
                  label: Text(tag.labelRu),
                  avatar: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: warningKeys.contains(tag.key)
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  backgroundColor: warningKeys.contains(tag.key)
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: warningKeys.contains(tag.key)
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
