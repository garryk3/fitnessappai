import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/settings/ui/sync_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран «Настройки»: синхронизация и настройки темы.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.syncController, this.themeController});

  final SyncController? syncController;
  final ThemeController? themeController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SyncController _syncController;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _syncController = widget.syncController ?? SyncController();
    _themeController = widget.themeController ?? locator.get<ThemeController>();
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
            FilledButton.icon(
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
    final imported = await widget.controller.importDatabase();
    if (!imported || !mounted) {
      return;
    }
    final restart = await showDialog<bool>(
      context: context,
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
    if (restart == true) {
      restartApp();
    }
  }
}
