import 'package:flutter/material.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';

/// Показывает список ошибок структуры программы при сохранении.
///
/// Возвращает `true`, если пользователь выбрал «Выйти», `false` — если
/// «Продолжить редактирование».
Future<bool?> showProgramValidationDialog(
  BuildContext context, {
  required List<String> errors,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.programValidationTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.programValidationMessage),
            const SizedBox(height: 8),
            for (final error in errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(error)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.programValidationContinue),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.programValidationExit),
        ),
      ],
    ),
  );
}
