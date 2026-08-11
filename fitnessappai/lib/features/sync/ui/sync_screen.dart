import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/features/sync/ui/sync_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран «Синхронизация»: экспорт и импорт базы данных.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key, this.controller});

  final SyncController? controller;

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  late final SyncController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SyncController();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sync)),
      body: SignalBuilder(builder: (_) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = _controller.isBusy.value;
    return ListView(
      padding: const EdgeInsets.all(16),
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
          label: Text(l10n.syncExport),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : _import,
          icon: const Icon(Icons.download_outlined),
          label: Text(l10n.syncImport),
        ),
        if (_controller.statusText.value case final status?) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                _controller.hasError.value
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: _controller.hasError.value
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              title: Text(status),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _export() async {
    await _controller.exportDatabase();
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final imported = await _controller.importDatabase();
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
