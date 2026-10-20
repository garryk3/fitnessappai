import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/sound/sound_settings_controller.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Секция настроек звука: переключатель, выбор файла, предпрослушивание.
///
/// Используется дважды: для сигналов таймеров и для звука напоминаний
/// (задача 47.5) — отличаются только [title] и обработчик изменений.
class SoundSettingsSection extends StatefulWidget {
  const SoundSettingsSection({
    super.key,
    required this.controller,
    required this.title,
  });

  final SoundSettingsController controller;

  /// Подпись переключателя (например, «Звук таймеров»).
  final String title;

  @override
  State<SoundSettingsSection> createState() => _SoundSettingsSectionState();
}

class _SoundSettingsSectionState extends State<SoundSettingsSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SignalBuilder(
      builder: (_) {
        final controller = widget.controller;
        if (controller.isLoading.value) {
          return const SizedBox.shrink();
        }
        final file = controller.soundFilePath.value;
        final soundStatus = controller.status.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: AppText(widget.title),
              value: controller.enabled.value,
              onChanged: (value) => controller.setEnabled(value),
            ),
            const SizedBox(height: 4),
            // Строка выбора звука (54.9, образец «Настройки»): бейдж-иконка,
            // подпись/имя файла, play и chevron. Весь тайл тапается — выбор
            // файла (дизайн-ревью 54.9: chevron был вне зоны тапа; IconButtons
            // внутри сохраняют собственные жесты). Бывшая AppOutlinedButton:
            // unit-контракт адаптирован, тексты и тултипы сброса/прослушивания
            // сохранены — e2e «Звук таймеров»/play_arrow не тронуты.
            AppInkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: controller.enabled.value
                  ? () => controller.pickSoundFile()
                  : null,
              child: AppContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Row(
                  children: [
                    AppContainer(
                      width: 36,
                      height: 36,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Center(
                        child: AppIcon(
                          Icons.music_note_outlined,
                          size: 20,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            l10n.soundPickFile,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppText(
                            file ?? l10n.soundDefaultLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (file != null) ...[
                      IconButton(
                        tooltip: l10n.soundReset,
                        icon: const AppIcon(Icons.restart_alt),
                        onPressed: () => controller.resetSoundFile(),
                      ),
                    ],
                    IconButton(
                      tooltip: controller.isPlaying.value
                          ? l10n.soundStop
                          : l10n.soundPreview,
                      icon: AppIcon(
                        controller.isPlaying.value
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      onPressed: controller.enabled.value
                          ? () => controller.togglePreview()
                          : null,
                    ),
                    AppIcon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (soundStatus != null) ...[
              const SizedBox(height: 8),
              AppText(
                soundStatusMessage(l10n, soundStatus),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: controller.hasError.value
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
