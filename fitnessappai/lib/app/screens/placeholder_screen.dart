import 'package:flutter/material.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';

/// Заглушка экрана в разработке.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(AppLocalizations.of(context).placeholderTab(title)),
      ),
    );
  }
}
