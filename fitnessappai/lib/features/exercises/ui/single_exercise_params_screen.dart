import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_params_form.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Экран параметров одиночного упражнения перед стартом.
///
/// Набор полей зависит от типа упражнения. По нажатию «Начать тренировку»
/// переходит на `/workout/run` с параметрами в query-строке.
class SingleExerciseParamsScreen extends StatefulWidget {
  const SingleExerciseParamsScreen({
    super.key,
    required this.exerciseId,
    this.exerciseRepository,
  });

  final int exerciseId;
  final ExerciseRepository? exerciseRepository;

  @override
  State<SingleExerciseParamsScreen> createState() =>
      _SingleExerciseParamsScreenState();
}

class _SingleExerciseParamsScreenState
    extends State<SingleExerciseParamsScreen> {
  late final ExerciseRepository _exerciseRepository;

  final _formKey = GlobalKey<FormState>();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _restController = TextEditingController();

  Exercise? _exercise;
  ExerciseType? _type;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
    final exercise = await _exerciseRepository.getById(widget.exerciseId);
    if (!mounted) {
      return;
    }
    setState(() {
      _exercise = exercise;
      _type = exercise?.type;
      _loading = false;
    });
  }

  void _start() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final type = _type!;
    // 55.4: ленивый список + крупный шрифт — поле могло быть размонтировано
    // до validate(), поэтому парсим через tryParse, а не int.parse.
    final sets = type == ExerciseType.distance
        ? 1
        : int.tryParse(_setsController.text.trim());
    final reps =
        type == ExerciseType.strength || type == ExerciseType.bodyweight
        ? int.tryParse(_repsController.text.trim())
        : null;
    final weightKg = type == ExerciseType.strength
        ? _parseDouble(_weightController.text)
        : null;
    final durationMinutes = type == ExerciseType.distance
        ? _parseInt(_durationController.text)
        : null;
    final durationSeconds = switch (type) {
      ExerciseType.strength || ExerciseType.bodyweight => null,
      ExerciseType.plank => _parseInt(_durationController.text),
      ExerciseType.distance =>
        durationMinutes == null ? null : durationMinutes * 60,
    };
    final distanceMeters = type == ExerciseType.distance
        ? _kmToMeters(_distanceController.text)
        : null;
    final restSeconds = _parseInt(_restController.text);

    // Обязательное поле не распарсилось (размонтировано ленивым списком) —
    // повторная валидация видимых полей вместо навигации с пустыми данными.
    // Plank-время на этом экране опционально (счётчик удержания) — не гвардим.
    if (sets == null ||
        ((type == ExerciseType.strength || type == ExerciseType.bodyweight) &&
            reps == null) ||
        (type == ExerciseType.distance && durationMinutes == null)) {
      _formKey.currentState?.validate();
      return;
    }

    final query = <String, String>{
      'exerciseId': '${widget.exerciseId}',
      'sets': '$sets',
      if (reps != null) 'reps': '$reps',
      if (weightKg != null) 'weightKg': '$weightKg',
      if (durationSeconds != null) 'durationSeconds': '$durationSeconds',
      if (distanceMeters != null) 'distanceMeters': '$distanceMeters',
      if (restSeconds != null) 'restSeconds': '$restSeconds',
    };
    final uri = Uri(path: '/workout/run', queryParameters: query);
    context.push(uri.toString());
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
                  icon: Icons.play_arrow,
                  onPressed: _start,
                  label: l10n.exerciseListStartWorkout,
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: AppSpinner());
    }
    final exercise = _exercise;
    final type = _type;
    if (exercise == null || type == null) {
      return Center(child: AppText(l10n.exerciseDetailNotFound));
    }
    return Form(
      key: _formKey,
      child: AppListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Шапка: миниатюра + название (паттерн «Параметры упражнения», 54.4;
          // общий компонент 55.4).
          ExerciseParamsHeaderCard(
            exercise: exercise,
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
              validator: _validateOptionalNotNegative,
              icon: Icons.timer,
              helperText: l10n.exerciseParamsHoldHint,
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
        ],
      ),
    );
  }

  double? _kmToMeters(String? text) {
    final km = _parseDouble(text);
    return km == null ? null : km * 1000;
  }

  static int? _parseInt(String? text) {
    final trimmed = text?.trim() ?? '';
    return trimmed.isEmpty ? null : int.tryParse(trimmed);
  }

  static double? _parseDouble(String? text) {
    final trimmed = (text?.trim().replaceAll(',', '.') ?? '');
    return trimmed.isEmpty ? null : double.tryParse(trimmed);
  }
}
