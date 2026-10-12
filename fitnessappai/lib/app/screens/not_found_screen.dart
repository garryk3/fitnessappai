import 'package:flutter/material.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Экран 404.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 16),
            AppText('404', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            AppText(l10n.errorNotFound),
          ],
        ),
      ),
    );
  }
}
