import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/app/router.dart';
import 'package:fitnessappai/app/splash_gate.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashGate());
}

class FitnessAppAi extends StatefulWidget {
  const FitnessAppAi({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<FitnessAppAi> createState() => _FitnessAppAiState();
}

class _FitnessAppAiState extends State<FitnessAppAi> {
  /// Роутер создаётся один раз и живёт в состоянии: пересоздание при смене
  /// темы сбросило бы навигацию на главный экран.
  late GoRouter _router = AppRouter.create();

  @override
  void initState() {
    super.initState();
    appRestartTick.addListener(_handleRestart);
  }

  @override
  void dispose() {
    appRestartTick.removeListener(_handleRestart);
    super.dispose();
  }

  /// Полный перезапуск после импорта БД: новый роутер + новый ключ,
  /// чтобы дерево виджетов перемонтировалось с нуля.
  void _handleRestart() {
    setState(() {
      _router = AppRouter.create();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController =
        widget.themeController ?? locator.get<ThemeController>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) => MaterialApp.router(
        key: ValueKey<int>(appRestartTick.value),
        title: 'Личный тренер',
        themeMode: mode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        routerConfig: _router,
      ),
    );
  }
}
