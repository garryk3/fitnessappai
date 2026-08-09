import 'package:flutter/material.dart';

import 'package:fitnessappai/app/screens/placeholder_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: AppLocalizations.of(context).navPrograms);
  }
}
