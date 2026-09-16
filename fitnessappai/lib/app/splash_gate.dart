import 'package:flutter/material.dart';

import 'package:fitnessappai/app/bootstrap.dart';
import 'package:fitnessappai/app/splash_video.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/main.dart';

/// Стартовый экран: показывает видео-заставку, пока идёт инициализация,
/// затем плавно переходит в [FitnessAppAi].
///
/// [bootstrap], [homeBuilder] и [splashBody] инъектируемы для тестов.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    this.bootstrap,
    this.homeBuilder,
    this.splashBody = const SplashVideo(),
  });

  /// Инициализация перед показом приложения. По умолчанию — [bootstrap].
  final Future<void> Function()? bootstrap;

  /// Строит основное приложение после заставки.
  final Widget Function()? homeBuilder;

  /// Содержимое заставки. По умолчанию — полноэкранное видео.
  final Widget splashBody;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _ready = false;

  /// Минимальное время показа заставки до начала исчезновения.
  static const Duration _minVisible = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    final started = DateTime.now();
    await (widget.bootstrap ?? bootstrap)();
    final elapsed = DateTime.now().difference(started);
    final remaining = _minVisible - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
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
        body: FadeTransition(opacity: _fade, child: widget.splashBody),
      ),
    );
  }
}
