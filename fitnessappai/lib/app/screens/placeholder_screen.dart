import 'package:flutter/material.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Заглушка экрана в разработке.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppTopBar(title: title),
      body: Center(
        child: AppText(AppLocalizations.of(context).placeholderTab(title)),
      ),
    );
  }
}
