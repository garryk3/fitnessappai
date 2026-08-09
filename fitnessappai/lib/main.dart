import 'package:flutter/material.dart';

import 'package:fitnessappai/app/router.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  runApp(const FitnessAppAi());
}

class FitnessAppAi extends StatelessWidget {
  const FitnessAppAi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FitnessAppAI',
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      routerConfig: AppRouter.create(),
    );
  }
}
