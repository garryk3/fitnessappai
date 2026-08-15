import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
    if (!mounted) {
      return;
    }
    final type = exercise?.type;
    setState(() {
      _item = item;
      _exercise = exercise;
      _type = type;
      _loading = false;
      _setsController.text = _formatInt(item?.sets);
      _repsController.text = _formatInt(item?.reps);
      _weightController.text = _formatDouble(item?.weightKg);
      if (type == ExerciseType.running) {
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

  ProgramDayExercise _buildUpdated() {
    final item = _item!;
    final type = _type!;
    final rest = _parseInt(_restController.text);
    return ProgramDayExercise(
      id: item.id,
      dayId: item.dayId,
      exerciseId: item.exerciseId,
      orderIndex: item.orderIndex,
      isAlternative: item.isAlternative,
      sets: type == ExerciseType.running ? 1 : int.parse(_setsController.text),
      reps: type == ExerciseType.strength || type == ExerciseType.bodyweight
          ? int.parse(_repsController.text)
          : null,
      weightKg: type == ExerciseType.strength
          ? _parseDouble(_weightController.text)
          : null,
      durationSeconds: switch (type) {
        ExerciseType.strength || ExerciseType.bodyweight => null,
        ExerciseType.plank => int.parse(_durationController.text),
        ExerciseType.running => int.parse(_durationController.text) * 60,
      },
      distanceMeters: type == ExerciseType.running
          ? _kmToMeters(_distanceController.text)
          : null,
      restSeconds: rest,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await _repository.updateExercise(_buildUpdated());
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } on ProgramValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.errors.first)));
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exerciseParams)),
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
                      : Text(l10n.commonSave),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final item = _item;
    final type = _type;
    if (item == null || type == null) {
      return Center(child: Text(l10n.exerciseDetailNotFound));
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _exercise?.name ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
              validator: _validateRequiredPositive,
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

  static String _formatInt(int? value) => value == null ? '' : '$value';

  static String _formatDouble(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble() ? value.toInt().toString() : '$value';
  }
}
