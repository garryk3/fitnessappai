import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/sound/sound_settings_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
    return SignalBuilder(
      builder: (_) {
        final controller = widget.controller;
        if (controller.isLoading.value) {
          return const SizedBox.shrink();
        }
        final file = controller.soundFilePath.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(widget.title),
              value: controller.enabled.value,
              onChanged: (value) => controller.setEnabled(value),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.enabled.value
                        ? () => controller.pickSoundFile()
                        : null,
                    icon: const Icon(Icons.audio_file_outlined),
                    label: Text(l10n.soundPickFile),
                  ),
                ),
                if (file != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.soundReset,
                    icon: const Icon(Icons.restart_alt),
                    onPressed: () => controller.resetSoundFile(),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  tooltip: controller.isPlaying.value
                      ? l10n.soundStop
                      : l10n.soundPreview,
                  icon: Icon(
                    controller.isPlaying.value ? Icons.stop : Icons.play_arrow,
                  ),
                  onPressed: controller.enabled.value
                      ? () => controller.togglePreview()
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              file ?? l10n.soundDefaultLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (controller.statusText.value case final status?) ...[
              const SizedBox(height: 8),
              Text(
                status,
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
