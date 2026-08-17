import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран разминки перед тренировкой: обратный отсчёт и «Пропустить».
///
/// Показывает [warmupSeconds] секунд и по завершении (или пропуске) переходит
/// на `/workout/run`.
class WorkoutWarmupScreen extends StatefulWidget {
  const WorkoutWarmupScreen({
    super.key,
    required this.programDayId,
    required this.warmupSeconds,
    this.variant = WorkoutVariant.main,
    this.soundService,
  });

  final int programDayId;
  final int warmupSeconds;
  final WorkoutVariant variant;
  final SoundService? soundService;

  @override
  State<WorkoutWarmupScreen> createState() => _WorkoutWarmupScreenState();
}

class _WorkoutWarmupScreenState extends State<WorkoutWarmupScreen> {
  late final SoundService _soundService;
  late int _remaining;
  Timer? _timer;
  bool _done = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _soundService = widget.soundService ?? locator.get<SoundService>();
    _remaining = widget.warmupSeconds;
    if (_remaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining <= 1) {
          _timer?.cancel();
          if (mounted) {
            setState(() => _done = true);
            _soundService.playCompletion();
            _goToRun();
          }
          return;
        }
        setState(() => _remaining -= 1);
      });
    } else {
      _goToRun();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToRun() {
    if (_navigated) {
      return;
    }
    _navigated = true;
    context.push(
      '/workout/run?programDayId=${widget.programDayId}'
      '&variant=${widget.variant.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutWarmup)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _done ? Icons.check_circle : Icons.timer,
              size: 64,
              color: _done
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              _done ? l10n.workoutWarmupDone : _format(_remaining),
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (!_done)
              Text(
                l10n.workoutWarmupSecondsLeft(_remaining),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 32),
            if (!_done)
              OutlinedButton(
                onPressed: _goToRun,
                child: Text(l10n.workoutWarmupSkip),
              )
            else
              FilledButton.icon(
                onPressed: _goToRun,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.workoutWarmupStartWorkout),
              ),
          ],
        ),
      ),
    );
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
