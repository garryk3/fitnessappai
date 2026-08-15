import 'package:flutter/material.dart';

import 'package:fitnessappai/app/bootstrap.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/main.dart';

/// Стартовый экран: показывает анимированный логотип, пока идёт
/// инициализация, затем плавно переходит в [FitnessAppAi].
///
/// [bootstrap] и [homeBuilder] инъектируемы для тестов.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, this.bootstrap, this.homeBuilder});

  /// Инициализация перед показом приложения. По умолчанию — [bootstrap].
  final Future<void> Function()? bootstrap;

  /// Строит основное приложение после заставки.
  final Widget Function()? homeBuilder;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(_fade);
    _controller.forward();
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    await (widget.bootstrap ?? bootstrap)();
    if (!mounted) {
      return;
    }
    await _controller.reverse();
    if (!mounted) {
      return;
    }
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return (widget.homeBuilder ?? () => const FitnessAppAi())();
    }
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 72,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Личный тренер',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
