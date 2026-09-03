import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/sound/sound_settings_controller.dart';
import 'package:fitnessappai/app/sound/sound_settings_repository.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/settings/domain/notification_settings_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_check_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';
import 'package:fitnessappai/features/settings/ui/sync_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран «Настройки»: синхронизация, звуки, уведомления и тема.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.syncController,
    this.themeController,
    this.soundController,
    this.updateController,
    this.notificationController,
  });

  final SyncController? syncController;
  final ThemeController? themeController;
  final SoundSettingsController? soundController;
  final UpdateCheckController? updateController;
  final NotificationSettingsController? notificationController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SyncController _syncController;
  late final ThemeController _themeController;
  late final SoundSettingsController _soundController;
  late final UpdateCheckController _updateController;
  NotificationSettingsController? _notificationController;

  @override
  void initState() {
    super.initState();
    _syncController = widget.syncController ?? SyncController();
    _themeController = widget.themeController ?? locator.get<ThemeController>();
    _soundController =
        widget.soundController ??
        SoundSettingsController(
          repository: locator.get<SoundSettingsRepository>(),
          soundService: locator.get<SoundService>(),
        );
    _soundController.load();
    _updateController =
        widget.updateController ??
        UpdateCheckController(service: locator.get<UpdateService>());
    _updateController.loadVersion();
    _notificationController = widget.notificationController;
    if (_notificationController == null) {
      try {
        _notificationController = NotificationSettingsController(
          reminderService: locator.get<ReminderService>(),
        );
        _notificationController?.load();
      } catch (_) {
        // ReminderService не зарегистрирован (тесты) — секция не показывается.
      }
    } else {
      _notificationController?.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settingsSyncSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _SyncSection(controller: _syncController),
          const SizedBox(height: 24),
          Text(l10n.settingsSoundSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _SoundSection(controller: _soundController),
          const SizedBox(height: 24),
          Text(
            l10n.settingsNotificationsSection,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_notificationController != null)
            _NotificationsSection(controller: _notificationController!),
          const SizedBox(height: 24),
          Text(l10n.settingsThemeSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: _themeController,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.settingsThemeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.settingsThemeLight),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                _themeController.setMode(selection.first);
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsAboutSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _AboutSection(controller: _updateController),
        ],
      ),
    );
  }
}

/// Секция настроек звуковых сигналов таймеров.
class _SoundSection extends StatefulWidget {
  const _SoundSection({required this.controller});

  final SoundSettingsController controller;

  @override
  State<_SoundSection> createState() => _SoundSectionState();
}

class _SoundSectionState extends State<_SoundSection> {
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
              title: Text(l10n.soundEnabled),
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

class _SyncSection extends StatefulWidget {
  const _SyncSection({required this.controller});

  final SyncController controller;

  @override
  State<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<_SyncSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = widget.controller.isBusy.value;
    return SignalBuilder(
      builder: (_) {
        final status = widget.controller.statusText.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.syncCloudHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: busy ? null : _export,
              icon: const Icon(Icons.upload_outlined),
              label: Text(l10n.syncShare),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : _exportToFile,
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(l10n.syncSaveFile),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : _import,
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.syncImport),
            ),
            if (status case final statusText?) ...[
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    widget.controller.hasError.value
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: widget.controller.hasError.value
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  title: Text(statusText),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.syncCloudComing,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _export() async {
    await widget.controller.exportDatabase();
  }

  Future<void> _exportToFile() async {
    await widget.controller.exportDatabaseToFile();
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncImportWarningTitle),
        content: Text(l10n.syncImportWarningBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.syncImportConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final imported = await widget.controller.importDatabase();
    if (!imported || !mounted) {
      return;
    }
    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncImportSuccess),
        content: Text(l10n.syncRestartHint),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
    if (restart == true && mounted) {
      restartApp();
    }
  }
}

/// Секция «Уведомления»: статус разрешений и кнопки запроса.
class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection({required this.controller});

  final NotificationSettingsController controller;

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
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
        final permissions = controller.status.value;
        final error = controller.error.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (permissions != null) ...[
              _PermissionTile(
                title: permissions.notificationsEnabled
                    ? l10n.settingsNotificationsEnabled
                    : l10n.settingsNotificationsDisabled,
                icon: permissions.notificationsEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: permissions.notificationsEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                onAction: permissions.notificationsEnabled
                    ? null
                    : () => controller.requestPermissions(),
                actionLabel: permissions.notificationsEnabled
                    ? null
                    : l10n.settingsNotificationsRequest,
              ),
              const SizedBox(height: 8),
              _PermissionTile(
                title: permissions.exactAlarmsEnabled
                    ? l10n.settingsNotificationsExactEnabled
                    : l10n.settingsNotificationsExactDisabled,
                icon: permissions.exactAlarmsEnabled
                    ? Icons.alarm_on_outlined
                    : Icons.alarm_off_outlined,
                color: permissions.exactAlarmsEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                onAction: permissions.exactAlarmsEnabled
                    ? null
                    : () => controller.requestPermissions(),
                actionLabel: permissions.exactAlarmsEnabled
                    ? null
                    : l10n.settingsNotificationsExactRequest,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.icon,
    required this.color,
    this.onAction,
    this.actionLabel,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}

/// Секция «О приложении»: версия и проверка обновлений.
class _AboutSection extends StatefulWidget {
  const _AboutSection({required this.controller});

  final UpdateCheckController controller;

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SignalBuilder(
      builder: (_) {
        final controller = widget.controller;
        final version = controller.versionText.value;
        final status = controller.statusText.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (version case final versionText?) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.settingsVersion} $versionText',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: controller.isChecking.value ? null : _check,
              icon: controller.isChecking.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.update),
              label: Text(l10n.settingsCheckUpdate),
            ),
            if (status case final statusText?) ...[
              const SizedBox(height: 8),
              Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: controller.hasError.value
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _check() async {
    final l10n = AppLocalizations.of(context);
    await widget.controller.checkForUpdates();
    if (!mounted || !widget.controller.hasUpdate.value) {
      return;
    }
    final version = widget.controller.latestVersion.value;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsUpdateAvailable),
        content: Text(l10n.settingsUpdateContent(version ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.settingsUpdateLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsUpdateDownload),
          ),
        ],
      ),
    );
    if (open == true) {
      await widget.controller.openUpdate();
    }
  }
}
