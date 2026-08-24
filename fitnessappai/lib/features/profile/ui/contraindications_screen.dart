import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/profile/ui/contraindications_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран «Моё здоровье»: выбор противопоказаний из каталога тегов.
class ContraindicationsScreen extends StatefulWidget {
  const ContraindicationsScreen({super.key, this.profileRepository});

  final UserProfileRepository? profileRepository;

  @override
  State<ContraindicationsScreen> createState() =>
      _ContraindicationsScreenState();
}

class _ContraindicationsScreenState extends State<ContraindicationsScreen> {
  late final ContraindicationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ContraindicationsController(
      repository:
          widget.profileRepository ?? locator.get<UserProfileRepository>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contraindicationsTitle)),
      body: SignalBuilder(builder: (_) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final tags = _controller.tags.value;
    final selectedKeys = _controller.selectedKeys.value;
    final isSaving = _controller.isSaving.value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.contraindicationsHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, tag) in tags.indexed) ...[
                if (index > 0) const Divider(height: 1),
                SwitchListTile(
                  title: Text(tag.labelRu),
                  subtitle: Text(_description(l10n, tag.key)),
                  value: selectedKeys.contains(tag.key),
                  onChanged: isSaving
                      ? null
                      : (enabled) => _toggleWithFeedback(tag.key, enabled),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleWithFeedback(String key, bool enabled) async {
    await _controller.toggle(key, enabled);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).contraindicationsSaved)),
    );
  }

  String _description(AppLocalizations l10n, String key) => switch (key) {
    'knees' => l10n.contraindicationDescKnees,
    'back' => l10n.contraindicationDescBack,
    'neck' => l10n.contraindicationDescNeck,
    'shoulders' => l10n.contraindicationDescShoulders,
    'elbows' => l10n.contraindicationDescElbows,
    'wrists' => l10n.contraindicationDescWrists,
    'heart' => l10n.contraindicationDescHeart,
    'pregnancy' => l10n.contraindicationDescPregnancy,
    _ => l10n.contraindicationsHint,
  };
}
