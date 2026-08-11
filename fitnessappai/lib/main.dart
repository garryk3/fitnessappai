import 'package:flutter/material.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/app/router.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCoreServices(locator);
  try {
    await locator.get<ReminderService>().initialize();
  } on Exception {
    // Напоминания не должны блокировать запуск приложения.
  }
  runApp(const FitnessAppAi());
}

class FitnessAppAi extends StatelessWidget {
  const FitnessAppAi({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appRestartTick,
      builder: (context, tick, _) => MaterialApp.router(
        key: ValueKey<int>(tick),
        title: 'FitnessAppAI',
        themeMode: ThemeMode.dark,
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        routerConfig: AppRouter.create(),
      ),
    );
  }
}
