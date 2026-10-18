import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';

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
    this.rescheduleWeekStart,
    this.soundService,
  });

  final int programDayId;
  final int warmupSeconds;
  final WorkoutVariant variant;

  /// Понедельник недели-источника, если тренировка запущена как перенос
  /// (задача 48.4) — пробрасывается на экран выполнения.
  final DateTime? rescheduleWeekStart;
  final SoundService? soundService;

  @override
  State<WorkoutWarmupScreen> createState() => _WorkoutWarmupScreenState();
}

class _WorkoutWarmupScreenState extends State<WorkoutWarmupScreen> {
  late final SoundService _soundService;
  late final WakelockService _wakelock;
  late int _remaining;
  Timer? _timer;
  bool _done = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _soundService = widget.soundService ?? locator.get<SoundService>();
    _wakelock = locator.get<WakelockService>();
    _remaining = widget.warmupSeconds;
    _wakelock.enable();
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
    _wakelock.disable();
    super.dispose();
  }

  void _goToRun() {
    if (_navigated) {
      return;
    }
    _navigated = true;
    _soundService.stop();
    final weekStart = widget.rescheduleWeekStart;
    context.push(
      '/workout/run?programDayId=${widget.programDayId}'
      '&variant=${widget.variant.name}'
      '${weekStart == null ? '' : '&rescheduleWeekStart=${weekStart.millisecondsSinceEpoch}'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppScaffold(
      appBar: AppTopBar(title: l10n.workoutWarmup),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Таймер-карточка в стиле таймера планки run-экрана (54.6).
              AppContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Column(
                  children: [
                    AppIcon(
                      _done ? Icons.check_circle : Icons.timer,
                      size: 48,
                      color: _done
                          ? colorScheme.primary
                          : colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      _done ? l10n.workoutWarmupDone : _format(_remaining),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_done) ...[
                      const SizedBox(height: 8),
                      AppText(
                        l10n.workoutWarmupSecondsLeft(_remaining),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (!_done)
                AppOutlinedButton(
                  label: l10n.workoutWarmupSkip,
                  onPressed: _goToRun,
                )
              else
                AppGradientButton(
                  onPressed: _goToRun,
                  icon: Icons.play_arrow,
                  pill: true,
                  label: l10n.workoutWarmupStartWorkout,
                ),
            ],
          ),
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
