import 'package:flutter/material.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Экран 404.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      body: Center(
        child: AppEmptyState(
          icon: Icons.search_off,
          title: '404',
          hint: l10n.errorNotFound,
        ),
      ),
    );
  }
}
