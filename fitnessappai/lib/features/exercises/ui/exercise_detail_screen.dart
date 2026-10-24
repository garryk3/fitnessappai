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
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_detail_controller.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

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
    this.workoutRepository,
  });

  final int exerciseId;
  final ExerciseRepository? repository;
  final MediaCache? mediaCache;
  final UserProfileRepository? profileRepository;
  final StatsAggregator? statsAggregator;
  final WorkoutRepository? workoutRepository;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final ExerciseDetailController _controller;
  late final ExerciseRepository _repository;
  late final MediaCache _mediaCache;
  late final StatsAggregator _statsAggregator;
  late final WorkoutRepository _workoutRepository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ExerciseRepository>();
    _mediaCache = widget.mediaCache ?? locator.get<MediaCache>();
    _statsAggregator = widget.statsAggregator ?? locator.get<StatsAggregator>();
    _workoutRepository =
        widget.workoutRepository ?? locator.get<WorkoutRepository>();
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
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText(l10n.exerciseDetailDeleteConfirm(data.exercise.name)),
        actions: [
          AppTextButton(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: l10n.commonDelete,
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
    Map<String, List<int>> referencedByProgram,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText(l10n.exerciseDetailDeleteBlocked(exerciseName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(l10n.exerciseDetailDeleteBlockedHint),
            const SizedBox(height: 8),
            for (final entry in referencedByProgram.entries)
              AppText(
                '• ${entry.key} → '
                '${entry.value.map((d) => l10n.programBuilderDay(d + 1)).join(', ')}',
              ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.of(context).pop(),
            label: l10n.commonOk,
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
        return AppScaffold(
          appBar: AppTopBar(
            title: l10n.exerciseDetail,
            actions: [
              if (canEdit)
                AppIconButton(
                  icon: const AppIcon(Icons.edit_outlined),
                  tooltip: l10n.commonEdit,
                  onPressed: () =>
                      context.push('/exercises/${widget.exerciseId}/edit'),
                ),
              if (canEdit)
                AppIconButton(
                  icon: const AppIcon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
                  onPressed: _confirmDelete,
                ),
            ],
          ),
          body: SignalBuilder(
            builder: (context) {
              if (_controller.isLoading.value) {
                return const Center(child: AppSpinner());
              }
              if (data == null) {
                return Center(child: AppText(l10n.exerciseDetailNotFound));
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
    return AppListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: AppCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: _ExercisePreview(
              exercise: exercise,
              mediaCache: _mediaCache,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: AppText(
            exercise.name,
            // Доминанта экрана (design-review 54.7): имя крупнее служебного
            // заголовка тулбара и набрано жирным.
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(child: _TypeBadge(type: exercise.type)),
        if (!exercise.hideOptional && exercise.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppSection(
            title: l10n.exerciseDetailDescription,
            child: AppText(exercise.description),
          ),
        ],
        if (!exercise.hideOptional && exercise.instructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppSection(
            title: l10n.exerciseDetailTechnique,
            child: AppText(exercise.instructions),
          ),
        ],
        if (!exercise.hideOptional && exercise.commonMistakes.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppSection(
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
                        const AppText('• '),
                        Expanded(child: AppText(mistake)),
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
            workoutRepository: _workoutRepository,
          ),
        ],
      ],
    );
  }
}

/// Секция истории выполнения упражнения: последние выполнения с подходами.
class _RecentHistorySection extends StatefulWidget {
  const _RecentHistorySection({
    required this.exercise,
    required this.statsAggregator,
    required this.workoutRepository,
  });

  final Exercise exercise;
  final StatsAggregator statsAggregator;
  final WorkoutRepository workoutRepository;

  @override
  State<_RecentHistorySection> createState() => _RecentHistorySectionState();
}

class _RecentHistorySectionState extends State<_RecentHistorySection> {
  late final Future<List<WorkoutSetResult>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.workoutRepository.lastResultsForExercise(
      widget.exercise.id!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<WorkoutSetResult>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final results = snapshot.data;
        if (results == null || results.isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final date = results.first.completedAt;
        return AppSection(
          title: l10n.exerciseDetailHistoryRecent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AppText(
                  DateFormat('d MMMM yyyy', 'ru').format(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final result in results)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: AppText(
                    '${_sideLabel(result.setIndex, result.side)} '
                    '${_formatResult(l10n, result)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _sideLabel(int setIndex, String? side) {
    final suffix = switch (side) {
      'left' => 'л',
      'right' => 'п',
      _ => '',
    };
    return '$setIndex$suffix.';
  }

  String _formatResult(AppLocalizations l10n, WorkoutSetResult result) {
    return switch (result.exerciseType) {
      ExerciseType.strength when result.weightKg != null =>
        '${result.reps ?? 0} × ${_fmt(result.weightKg!)} ${l10n.workoutUnitKg}',
      ExerciseType.strength ||
      ExerciseType.bodyweight => '${result.reps ?? 0} ${l10n.workoutUnitReps}',
      ExerciseType.plank =>
        '${result.durationSeconds ?? 0} ${l10n.workoutUnitSeconds}',
      ExerciseType.distance =>
        '${_fmt((result.distanceMeters ?? 0) / 1000)} ${l10n.workoutUnitKm} × '
            '${(result.durationSeconds ?? 0) ~/ 60} ${l10n.workoutUnitMinutes}',
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
      // Радиус AppCard (xl), а не lg — без «ступеньки» по углам (54.7).
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: AppImage(
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
    return AppContainer(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: AppIcon(
        // Иконка по типу (54.7): та же логика, что в `ExerciseThumbnail`.
        switch (exercise.type) {
          ExerciseType.bodyweight => Icons.accessibility_new,
          ExerciseType.plank => Icons.self_improvement,
          ExerciseType.distance => Icons.directions_run,
          ExerciseType.strength => Icons.fitness_center,
        },
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
      ExerciseType.distance => l10n.exerciseTypeDistance,
    };
    final colorScheme = Theme.of(context).colorScheme;
    return AppContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        // Пилюля (54.7): бейдж типа — как в списке и статус-чипи 54.4–54.6.
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: AppText(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
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
    return AppSection(
      title: l10n.exerciseDetailMuscles,
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
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
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final muscle in muscles)
                AppChip(
                  avatar: MuscleGroupIcon(muscleKey: muscle.key, size: 18),
                  label: AppText(muscle.labelRu),
                  // Пилюля (54.7): чипы мышц — в стиле карточек редизайна.
                  shape: const StadiumBorder(),
                ),
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
    return AppSection(
      title: l10n.contraindications,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warnings.isNotEmpty) ...[
            Row(
              children: [
                AppIcon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText(
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
                AppChip(
                  label: AppText(tag.labelRu),
                  avatar: AppIcon(
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
                  // Пилюля (54.7): как чипы мышц выше.
                  shape: const StadiumBorder(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
