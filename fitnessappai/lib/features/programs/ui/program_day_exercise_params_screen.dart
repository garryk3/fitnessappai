import 'package:flutter/material.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_params_form.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Экран параметров упражнения в тренировочном дне.
///
/// Набор полей зависит от типа упражнения. Сохраняет метрики через
/// [ProgramRepository.updateExercise].
class ProgramDayExerciseParamsScreen extends StatefulWidget {
  const ProgramDayExerciseParamsScreen({
    super.key,
    required this.positionId,
    this.repository,
    this.exerciseRepository,
  });

  /// Идентификатор позиции [ProgramDayExercise].
  final int positionId;
  final ProgramRepository? repository;
  final ExerciseRepository? exerciseRepository;

  @override
  State<ProgramDayExerciseParamsScreen> createState() =>
      _ProgramDayExerciseParamsScreenState();
}

class _ProgramDayExerciseParamsScreenState
    extends State<ProgramDayExerciseParamsScreen> {
  late final ProgramRepository _repository;
  late final ExerciseRepository _exerciseRepository;

  final _formKey = GlobalKey<FormState>();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _restController = TextEditingController();

  ProgramDayExercise? _item;
  Exercise? _exercise;
  ExerciseType? _type;
  bool _loading = true;
  bool _saving = false;

  /// Позиция дня в плане программы для футера (1-based); null — данных нет.
  int? _planDayNumber;
  int? _planTotalDays;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? locator.get<ProgramRepository>();
    _exerciseRepository =
        widget.exerciseRepository ?? locator.get<ExerciseRepository>();
    _load();
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _restController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final item = await _repository.getExercise(widget.positionId);
    Exercise? exercise;
    if (item?.exerciseId != null) {
      exercise = await _exerciseRepository.getById(item!.exerciseId!);
    }
    // Позиция дня в плане программы — для футера «Прогресс плана».
    int? planDayNumber;
    int? planTotalDays;
    if (item != null) {
      final day = await _repository.getDay(item.dayId);
      if (day != null) {
        final program = await _repository.getById(day.programId);
        if (program != null) {
          planDayNumber = day.dayIndex + 1;
          planTotalDays = program.daysCount;
        }
      }
    }
    if (!mounted) {
      return;
    }
    final type = exercise?.type;
    setState(() {
      _item = item;
      _exercise = exercise;
      _type = type;
      _planDayNumber = planDayNumber;
      _planTotalDays = planTotalDays;
      _loading = false;
      _setsController.text = _formatInt(item?.sets);
      _repsController.text = _formatInt(item?.reps);
      _weightController.text = _formatDouble(item?.weightKg);
      if (type == ExerciseType.distance) {
        final minutes = item?.durationSeconds;
        _durationController.text = minutes == null
            ? ''
            : '${(minutes / 60).round()}';
        _distanceController.text = _formatDouble(item?.distanceMeters);
      } else {
        _durationController.text = _formatInt(item?.durationSeconds);
      }
      _restController.text = _formatInt(item?.restSeconds);
    });
  }

  /// Обновлённая позиция; null — обязательное поле не распарсилось
  /// (ленивый список + крупный шрифт: поле могло размонтироваться до
  /// validate() — 55.4).
  ProgramDayExercise? _buildUpdated() {
    final item = _item!;
    final type = _type!;
    final rest = _parseInt(_restController.text);
    // 55.4: tryParse вместо int.parse — размонтированное поле не роняет тап.
    final sets = type == ExerciseType.distance
        ? 1
        : int.tryParse(_setsController.text.trim());
    final needsReps =
        type == ExerciseType.strength || type == ExerciseType.bodyweight;
    final reps = needsReps ? int.tryParse(_repsController.text.trim()) : null;
    final plankSeconds = type == ExerciseType.plank
        ? int.tryParse(_durationController.text.trim())
        : null;
    if (sets == null ||
        (needsReps && reps == null) ||
        (type == ExerciseType.plank && plankSeconds == null)) {
      return null;
    }
    return ProgramDayExercise(
      id: item.id,
      dayId: item.dayId,
      exerciseId: item.exerciseId,
      orderIndex: item.orderIndex,
      isAlternative: item.isAlternative,
      sets: sets,
      reps: reps,
      weightKg: type == ExerciseType.strength
          ? _parseDouble(_weightController.text)
          : null,
      durationSeconds: switch (type) {
        ExerciseType.strength || ExerciseType.bodyweight => null,
        ExerciseType.plank => plankSeconds,
        ExerciseType.distance => _minutesToSeconds(_durationController.text),
      },
      distanceMeters: switch (type) {
        ExerciseType.distance => _kmToMeters(_distanceController.text),
        ExerciseType.strength ||
        ExerciseType.bodyweight ||
        ExerciseType.plank => null,
      },
      restSeconds: rest,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final updated = _buildUpdated();
    if (updated == null) {
      // Обязательное поле размонтировано ленивым списком и ушло от
      // validate() (55.4) — показываем ошибки видимых полей, без сохранения.
      _formKey.currentState?.validate();
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await _repository.updateExercise(updated);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } on ProgramValidationException catch (e) {
      if (mounted) {
        showAppSnackBar(ScaffoldMessenger.of(context), e.errors.first);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  String? _validateRequiredPositive(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return l10n.exerciseParamsRequired;
    }
    final number = int.tryParse(text);
    if (number == null || number < 1) {
      return l10n.exerciseParamsPositive;
    }
    return null;
  }

  String? _validateOptionalNotNegative(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final number = _parseDouble(text);
    if (number == null || number < 0) {
      return l10n.exerciseParamsNotNegative;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppTopBar(title: l10n.exerciseParams),
      body: _buildBody(),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppGradientButton(
                  pill: true,
                  icon: Icons.save,
                  busy: _saving,
                  onPressed: _save,
                  label: l10n.commonSave,
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: AppSpinner());
    }
    final item = _item;
    final type = _type;
    if (item == null || type == null) {
      return Center(child: AppText(l10n.exerciseDetailNotFound));
    }
    return Form(
      key: _formKey,
      child: AppListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Шапка: миниатюра + название (образец «Параметры упражнения»;
          // общий компонент 55.4).
          ExerciseParamsHeaderCard(
            exercise: _exercise,
            mediaCache: locator.isRegistered<MediaCache>()
                ? locator.get<MediaCache>()
                : null,
          ),
          const SizedBox(height: 16),
          if (type != ExerciseType.distance)
            ExerciseParamsStepperField(
              controller: _setsController,
              label: l10n.exerciseParamsSets,
              validator: _validateRequiredPositive,
              icon: Icons.format_list_numbered,
            ),
          if (type == ExerciseType.strength ||
              type == ExerciseType.bodyweight) ...[
            ExerciseParamsStepperField(
              controller: _repsController,
              label: l10n.exerciseParamsReps,
              validator: _validateRequiredPositive,
              icon: Icons.repeat,
            ),
            if (type == ExerciseType.strength)
              ExerciseParamsStepperField(
                controller: _weightController,
                label: l10n.exerciseParamsWeightKg,
                validator: _validateOptionalNotNegative,
                icon: Icons.fitness_center,
                step: 0.5,
                decimals: true,
              ),
          ],
          if (type == ExerciseType.plank)
            ExerciseParamsStepperField(
              controller: _durationController,
              label: l10n.exerciseParamsDurationSeconds,
              validator: _validateRequiredPositive,
              icon: Icons.timer,
            ),
          if (type == ExerciseType.distance) ...[
            ExerciseParamsStepperField(
              controller: _durationController,
              label: l10n.exerciseParamsDurationMinutes,
              validator: _validateRequiredPositive,
              icon: Icons.timer,
            ),
            ExerciseParamsStepperField(
              controller: _distanceController,
              label: l10n.exerciseParamsDistanceKm,
              validator: _validateOptionalNotNegative,
              icon: Icons.directions_run,
              step: 0.5,
              decimals: true,
            ),
          ],
          ExerciseParamsStepperField(
            controller: _restController,
            label: l10n.exerciseParamsRestSeconds,
            validator: _validateOptionalNotNegative,
            icon: Icons.hourglass_bottom,
          ),
          if (_planDayNumber != null && _planTotalDays != null) ...[
            const SizedBox(height: 8),
            _buildPlanProgressCard(l10n),
          ],
        ],
      ),
    );
  }

  /// Футер-карточка: позиция дня в плане программы + шкала (54.4).
  Widget _buildPlanProgressCard(AppLocalizations l10n) {
    final day = _planDayNumber!;
    final total = _planTotalDays!;
    if (total <= 0) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            l10n.exerciseParamsPlanProgress(day, total),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          AppLinearProgress(value: day / total),
        ],
      ),
    );
  }

  double? _kmToMeters(String? text) {
    final km = _parseDouble(text);
    return km == null ? null : km * 1000;
  }

  int? _minutesToSeconds(String? text) {
    final minutes = _parseInt(text);
    return minutes == null ? null : minutes * 60;
  }

  static int? _parseInt(String? text) {
    final trimmed = text?.trim() ?? '';
    return trimmed.isEmpty ? null : int.tryParse(trimmed);
  }

  static double? _parseDouble(String? text) {
    final trimmed = (text?.trim().replaceAll(',', '.') ?? '');
    return trimmed.isEmpty ? null : double.tryParse(trimmed);
  }

  static String _formatInt(int? value) => value == null ? '' : '$value';

  static String _formatDouble(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble() ? value.toInt().toString() : '$value';
  }
}
