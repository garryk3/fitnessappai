import 'package:flutter/material.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Показывает список ошибок структуры программы при сохранении.
///
/// Возвращает `true`, если пользователь выбрал «Выйти», `false` — если
/// «Продолжить редактирование».
Future<bool?> showProgramValidationDialog(
  BuildContext context, {
  required List<String> errors,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppDialog<bool>(
    context: context,
    builder: (context) => AppDialog(
      title: AppText(l10n.programValidationTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(l10n.programValidationMessage),
            const SizedBox(height: 8),
            for (final error in errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText('• '),
                    Expanded(child: AppText(error)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        AppTextButton(
          label: l10n.programValidationContinue,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          onPressed: () => Navigator.of(context).pop(true),
          label: l10n.programValidationExit,
        ),
      ],
    ),
  );
}
