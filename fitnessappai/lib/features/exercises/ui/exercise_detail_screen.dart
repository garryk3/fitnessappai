import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
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
    this.statsAggregator,
  });

  final int exerciseId;
  final ExerciseRepository? repository;
  final MediaCache? mediaCache;
  final UserProfileRepository? profileRepository;
  final StatsAggregator? statsAggregator;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final ExerciseDetailController _controller;
  late final ExerciseRepository _repository;
  late final MediaCache _mediaCache;
  late final StatsAggregator _statsAggregator;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ExerciseRepository>();
    _mediaCache = widget.mediaCache ?? locator.get<MediaCache>();
    _statsAggregator = widget.statsAggregator ?? locator.get<StatsAggregator>();
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final data = _controller.data.value;
    if (data == null) {
      return;
    }
    final referencedPrograms = await _repository.referencedPrograms(
      widget.exerciseId,
    );
    if (!mounted) {
      return;
    }
    if (referencedPrograms.isNotEmpty) {
      await _showReferencedDialog(data.exercise.name, referencedPrograms);
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

  Future<void> _showReferencedDialog(
    String exerciseName,
    List<String> programNames,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exerciseDetailDeleteBlocked(exerciseName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.exerciseDetailDeleteBlockedHint),
            const SizedBox(height: 8),
            for (final name in programNames) Text('• $name'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
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
              if (canEdit)
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
        if (!exercise.hideOptional && exercise.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: l10n.exerciseDetailDescription,
            child: Text(exercise.description),
          ),
        ],
        if (!exercise.hideOptional && exercise.instructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: l10n.exerciseDetailTechnique,
            child: Text(exercise.instructions),
          ),
        ],
        if (!exercise.hideOptional && exercise.commonMistakes.isNotEmpty) ...[
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
        if (exercise.id != null) ...[
          const SizedBox(height: 16),
          _RecentHistorySection(
            exercise: exercise,
            statsAggregator: _statsAggregator,
          ),
        ],
      ],
    );
  }
}

/// Секция истории выполнения упражнения за последние 3 дня.
class _RecentHistorySection extends StatefulWidget {
  const _RecentHistorySection({
    required this.exercise,
    required this.statsAggregator,
  });

  final Exercise exercise;
  final StatsAggregator statsAggregator;

  @override
  State<_RecentHistorySection> createState() => _RecentHistorySectionState();
}

class _RecentHistorySectionState extends State<_RecentHistorySection> {
  late final Future<List<ProgressionPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.statsAggregator.exerciseHistoryLastDays(
      widget.exercise.id!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<ProgressionPoint>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final points = snapshot.data;
        if (points == null) {
          return const SizedBox.shrink();
        }
        if (points.isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return _Section(
          title: l10n.exerciseDetailHistoryRecent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final point in points)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('d MMMM yyyy', 'ru').format(point.date),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        _formatMetric(l10n, widget.exercise.type, point.metric),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatMetric(AppLocalizations l10n, ExerciseType type, double value) {
    return switch (type) {
      ExerciseType.strength => '${_fmt(value)} ${l10n.workoutUnitKg}',
      ExerciseType.bodyweight => '${value.round()} ${l10n.workoutUnitReps}',
      ExerciseType.running => '${_fmt(value / 1000)} ${l10n.workoutUnitKm}',
      ExerciseType.plank => '${_fmt(value / 60)} ${l10n.workoutUnitMinutes}',
    };
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

class _ExercisePreview extends StatelessWidget {
  const _ExercisePreview({required this.exercise, required this.mediaCache});

  final Exercise exercise;
  final MediaCache mediaCache;

  @override
  Widget build(BuildContext context) {
    const height = 220.0;
    final provider = mediaCache.imageFor(
      exercise.animationPath ?? exercise.thumbnailPath,
      blob: exercise.animationBlob ?? exercise.thumbnailBlob,
    );
    if (provider == null) {
      return _placeholder(context, height);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image(
        image: provider,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
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
      ExerciseType.bodyweight => l10n.exerciseTypeBodyweight,
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
