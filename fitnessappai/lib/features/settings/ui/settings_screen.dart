import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
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
            systemReadable: snapshot.systemReadable,
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
    return AppScaffold(
      appBar: AppTopBar(
        leading: const AppMenuButton(),
        title: l10n.settings,
        large: true,
      ),
      body: AppListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Секции-карточки (54.9, образец «Настройки»): заголовок
          // секции внутри AppCard; контракты находок тестов сохраняются
          // (тексты/типы содержимого не меняются, порядок тот же).
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(title: l10n.settingsSyncSection),
                const SizedBox(height: 8),
                _SyncSection(controller: _syncController),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(title: l10n.settingsSoundSection),
                const SizedBox(height: 8),
                SoundSettingsSection(
                  controller: _soundController,
                  title: l10n.soundEnabled,
                ),
              ],
            ),
          ),
          if (_reminderSoundController != null) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(title: l10n.settingsReminderSoundSection),
                  const SizedBox(height: 8),
                  SoundSettingsSection(
                    controller: _reminderSoundController!,
                    title: l10n.reminderSoundEnabled,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    l10n.reminderSoundHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_notificationController != null) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(title: l10n.settingsNotificationsSection),
                  const SizedBox(height: 8),
                  _NotificationsSection(controller: _notificationController!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(title: l10n.settingsThemeSection),
                const SizedBox(height: 8),
                // Сегмент темы — pill-обёртка 54.1 на всю ширину
                // (54.9, образец: активный сегмент-пилюля); нативный
                // SegmentedButton<ThemeMode> рендерится внутри — контракт
                // byType теста сохранён.
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: _themeController,
                  builder: (context, mode, _) => AppSegmentedButton<ThemeMode>(
                    segments: [
                      AppSegment(
                        value: ThemeMode.dark,
                        label: l10n.settingsThemeDark,
                        icon: Icons.dark_mode_outlined,
                      ),
                      AppSegment(
                        value: ThemeMode.light,
                        label: l10n.settingsThemeLight,
                        icon: Icons.light_mode_outlined,
                      ),
                    ],
                    selected: {mode},
                    expanded: true,
                    onSelectionChanged: (selection) {
                      _themeController.setMode(selection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(title: l10n.settingsAboutSection),
                const SizedBox(height: 8),
                _AboutSection(controller: _updateController),
              ],
            ),
          ),
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
        final validationError = widget.controller.importValidationError.value;
        final syncStatus = widget.controller.status.value;
        final status = validationError != null
            ? syncValidationMessage(l10n, validationError)
            : syncStatus == null
            ? null
            : syncStatusMessage(l10n, syncStatus);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              l10n.syncCloudHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Три плитки в ряд (54.9, образец): иконка сверху + подпись;
            // IntrinsicHeight + stretch — равная высота плиток при переносах
            // подписей на крупном шрифте (дизайн-ревью 54.9; без IntrinsicHeight
            // Row в Column получает бесконечную высоту). Тексты не менять —
            // контракт тестов/e2e.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SyncTile(
                      icon: Icons.upload_outlined,
                      label: l10n.syncShare,
                      onTap: busy ? null : _export,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SyncTile(
                      icon: Icons.save_alt_outlined,
                      label: l10n.syncSaveFile,
                      onTap: busy ? null : _exportToFile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SyncTile(
                      icon: Icons.download_outlined,
                      label: l10n.syncImport,
                      onTap: busy ? null : _import,
                    ),
                  ),
                ],
              ),
            ),
            if (status case final statusText?) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  AppIcon(
                    widget.controller.hasError.value
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 20,
                    color: widget.controller.hasError.value
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: AppText(statusText)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Info-баннер (54.9, образец): роли темы, ≥4.5:1 обеих тем.
            AppContainer(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      l10n.syncCloudComing,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
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
    final l10n = AppLocalizations.of(context);
    await widget.controller.exportDatabaseToFile(
      dialogTitle: l10n.syncSaveDialogTitle,
    );
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText(l10n.syncImportWarningTitle),
        content: AppText(l10n.syncImportWarningBody),
        actions: [
          AppTextButton(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: l10n.syncImportConfirm,
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
    final restart = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: AppText(l10n.syncImportSuccess),
        content: AppText(l10n.syncRestartHint),
        actions: [
          AppButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: l10n.commonOk,
          ),
        ],
      ),
    );
    if (restart == true && mounted) {
      restartApp();
    }
  }
}

/// Плитка действия синхронизации (54.9, образец): иконка сверху,
/// подпись снизу; `onTap == null` — состояние disabled (цвета приглушены).
class _SyncTile extends StatelessWidget {
  const _SyncTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final foreground = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final labelColor = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    return AppContainer(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Column(
          children: [
            AppIcon(icon, size: 24, color: foreground),
            const SizedBox(height: 8),
            AppText(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(color: labelColor),
            ),
          ],
        ),
      ),
    );
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
        final errorKind = controller.error.value;
        final error = errorKind == null
            ? null
            : notificationErrorMessage(l10n, errorKind);
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
              // Без точного режима задержка штатная, а в Doze — до десятков
              // минут: об этом пользователь должен знать, иначе считает
              // напоминания сломанными (задача 47.6).
              if (!permissions.exactAlarmsEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AppText(
                    l10n.settingsNotificationsExactHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            // Оптимизация батареи — оружие OEM против фоновых будильников:
            // запрос только по кнопке и с пояснением, что это нужно не всем
            // (задача 48.7). Статус `null` (не Android, канал не отвечает) —
            // плитку не показываем, чтобы не врать.
            if (controller.batteryOptimizationExempt.value != null) ...[
              _PermissionTile(
                title: controller.batteryOptimizationExempt.value!
                    ? l10n.settingsNotificationsBatteryExempt
                    : l10n.settingsNotificationsBatteryEnabled,
                icon: Icons.battery_saver_outlined,
                color: controller.batteryOptimizationExempt.value!
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                onAction: controller.batteryOptimizationExempt.value!
                    ? null
                    : () => controller.requestBatteryOptimization(),
                actionLabel: controller.batteryOptimizationExempt.value!
                    ? null
                    : l10n.settingsNotificationsBatteryRequest,
              ),
              if (!controller.batteryOptimizationExempt.value!)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AppText(
                    l10n.settingsNotificationsBatteryHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              AppText(
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
            AppIcon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
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
            child: AppButton(
              onPressed: onAction,
              label: actionLabel!,
              tonal: true,
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
        final updateStatus = controller.status.value;
        final status = updateStatus == null
            ? null
            : updateStatusMessage(l10n, updateStatus);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (version case final versionText?) ...[
              const SizedBox(height: 8),
              AppText(
                '${l10n.settingsVersion} $versionText',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              onPressed: controller.isChecking.value ? null : _check,
              icon: Icons.update,
              label: l10n.settingsCheckUpdate,
              tonal: true,
              pending: controller.isChecking.value,
            ),
            if (status case final statusText?) ...[
              const SizedBox(height: 8),
              AppText(
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
    final open = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText(l10n.settingsUpdateAvailable),
        content: AppText(l10n.settingsUpdateContent(version ?? '')),
        actions: [
          AppTextButton(
            label: l10n.settingsUpdateLater,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: l10n.settingsUpdateDownload,
          ),
        ],
      ),
    );
    if (open == true) {
      await widget.controller.openUpdate();
    }
  }
}
