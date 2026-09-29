import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/sound/reminder_sound_settings_repository.dart';
import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/sound/sound_settings_controller.dart';
import 'package:fitnessappai/app/sound/sound_settings_repository.dart';
import 'package:fitnessappai/app/sound/sound_settings_section.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/settings/domain/notification_settings_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_check_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';
import 'package:fitnessappai/features/settings/ui/sync_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Экран «Настройки»: синхронизация, звуки, уведомления и тема.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.syncController,
    this.themeController,
    this.soundController,
    this.reminderSoundController,
    this.updateController,
    this.notificationController,
  });

  final SyncController? syncController;
  final ThemeController? themeController;
  final SoundSettingsController? soundController;

  /// Настройки звука напоминаний (задача 47.5). null — секция не показывается
  /// (тесты, окружения без ReminderService).
  final SoundSettingsController? reminderSoundController;
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
  SoundSettingsController? _reminderSoundController;
  NotificationSettingsController? _notificationController;

  /// Контроллер звука напоминаний создан экраном: его нужно освободить вместе
  /// с подпиской на состояние воспроизведения.
  bool _ownsReminderSoundController = false;

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
    _initReminderSound();
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

  /// Создаёт контроллер звука напоминаний, если доступен ReminderService.
  ///
  /// Изменения применяются к каналу уведомлений: звук канала неизменен после
  /// создания, поэтому канал пересоздаётся, а напоминания перепланируются
  /// (задача 47.5).
  void _initReminderSound() {
    _reminderSoundController = widget.reminderSoundController;
    if (_reminderSoundController == null) {
      try {
        final reminders = locator.get<ReminderService>();
        _ownsReminderSoundController = true;
        _reminderSoundController = SoundSettingsController(
          repository: locator.get<ReminderSoundSettingsRepository>(),
          soundService: locator.get<ReminderSoundService>(),
          onChanged: (snapshot) => reminders.applySoundSettings(
            enabled: snapshot.enabled,
            filePath: snapshot.filePath,
          ),
        );
      } catch (_) {
        // ReminderService или БД не зарегистрированы (тесты) — секция скрыта.
        _reminderSoundController = null;
      }
    }
    _reminderSoundController?.load();
  }

  @override
  void dispose() {
    if (_ownsReminderSoundController) {
      _reminderSoundController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionHeader(title: l10n.settingsSyncSection),
          const SizedBox(height: 8),
          _SyncSection(controller: _syncController),
          const SizedBox(height: 24),
          AppSectionHeader(title: l10n.settingsSoundSection),
          const SizedBox(height: 8),
          SoundSettingsSection(
            controller: _soundController,
            title: l10n.soundEnabled,
          ),
          if (_reminderSoundController != null) ...[
            const SizedBox(height: 24),
            AppSectionHeader(title: l10n.settingsReminderSoundSection),
            const SizedBox(height: 8),
            SoundSettingsSection(
              controller: _reminderSoundController!,
              title: l10n.reminderSoundEnabled,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reminderSoundHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppSectionHeader(title: l10n.settingsNotificationsSection),
          const SizedBox(height: 8),
          if (_notificationController != null)
            _NotificationsSection(controller: _notificationController!),
          const SizedBox(height: 24),
          AppSectionHeader(title: l10n.settingsThemeSection),
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
          AppSectionHeader(title: l10n.settingsAboutSection),
          const SizedBox(height: 8),
          _AboutSection(controller: _updateController),
        ],
      ),
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
                    : () => controller.requestNotifications(),
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
                    : () => controller.requestExactAlarms(),
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
