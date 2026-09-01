import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
    final sets = type == ExerciseType.running
        ? 1
        : int.parse(_setsController.text);
    final reps =
        type == ExerciseType.strength || type == ExerciseType.bodyweight
        ? int.parse(_repsController.text)
        : null;
    final weightKg = type == ExerciseType.strength
        ? _parseDouble(_weightController.text)
        : null;
    final durationSeconds = switch (type) {
      ExerciseType.strength || ExerciseType.bodyweight => null,
      ExerciseType.plank => _parseInt(_durationController.text),
      ExerciseType.running => _parseInt(_durationController.text)! * 60,
    };
    final distanceMeters = type == ExerciseType.running
        ? _kmToMeters(_distanceController.text)
        : null;
    final restSeconds = _parseInt(_restController.text);

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exerciseParams)),
      body: _buildBody(),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _start,
                  child: Text(l10n.exerciseListStartWorkout),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final exercise = _exercise;
    final type = _type;
    if (exercise == null || type == null) {
      return Center(child: Text(l10n.exerciseDetailNotFound));
    }
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (type != ExerciseType.running)
            _buildNumberField(
              controller: _setsController,
              label: l10n.exerciseParamsSets,
              validator: _validateRequiredPositive,
            ),
          if (type == ExerciseType.strength ||
              type == ExerciseType.bodyweight) ...[
            _buildNumberField(
              controller: _repsController,
              label: l10n.exerciseParamsReps,
              validator: _validateRequiredPositive,
            ),
            if (type == ExerciseType.strength)
              _buildNumberField(
                controller: _weightController,
                label: l10n.exerciseParamsWeightKg,
                validator: _validateOptionalNotNegative,
                decimals: true,
              ),
          ],
          if (type == ExerciseType.plank)
            _buildNumberField(
              controller: _durationController,
              label: l10n.exerciseParamsDurationSeconds,
              validator: _validateOptionalNotNegative,
              helperText: l10n.exerciseParamsHoldHint,
            ),
          if (type == ExerciseType.running) ...[
            _buildNumberField(
              controller: _durationController,
              label: l10n.exerciseParamsDurationMinutes,
              validator: _validateRequiredPositive,
            ),
            _buildNumberField(
              controller: _distanceController,
              label: l10n.exerciseParamsDistanceKm,
              validator: _validateOptionalNotNegative,
              decimals: true,
            ),
          ],
          _buildNumberField(
            controller: _restController,
            label: l10n.exerciseParamsRestSeconds,
            validator: _validateOptionalNotNegative,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool decimals = false,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimals),
        inputFormatters: [
          if (decimals)
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
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
