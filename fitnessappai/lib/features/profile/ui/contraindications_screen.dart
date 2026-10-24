import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/profile/ui/contraindications_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

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
    return AppScaffold(
      appBar: AppTopBar(title: l10n.contraindicationsTitle),
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
    return AppListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info-баннер (54.9, образец «Моё здоровье»): роли темы
        // (surfaceContainerHigh + onSurfaceVariant ≥4.5:1 обеих тем).
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
                  l10n.contraindicationsHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Отдельная карточка на тумблер (54.9, образец): зазор вместо
        // Divider внутри общей карточки. SwitchListTile сохраняется —
        // контракт тестов и e2e (byType ×8, widgetWithText «Колени»,
        // title как AppText); `secondary` рендерится в слоте leading
        // (controlAffinity.platform), свитч — trailing: бейдж слева
        // и участвует в тапе плитки.
        for (final tag in tags) ...[
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: _TagBadge(icon: _iconFor(tag.key)),
              title: AppText(tag.labelRu),
              subtitle: AppText(_description(l10n, tag.key)),
              value: selectedKeys.contains(tag.key),
              onChanged: isSaving
                  ? null
                  : (enabled) => _toggleWithFeedback(tag.key, enabled),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// Иконка-бейдж тега: иллюстраций образца в ассетах нет — осмысленный
  /// набор `Icons.*` в скруглённом бейдже (54.9).
  static IconData _iconFor(String key) => switch (key) {
    'knees' => Icons.directions_run,
    'back' => Icons.self_improvement,
    'neck' => Icons.face,
    'shoulders' => Icons.accessibility_new,
    'elbows' => Icons.front_hand,
    'wrists' => Icons.back_hand_outlined,
    'heart' => Icons.monitor_heart_outlined,
    'pregnancy' => Icons.pregnant_woman,
    _ => Icons.health_and_safety_outlined,
  };

  Future<void> _toggleWithFeedback(String key, bool enabled) async {
    await _controller.toggle(key, enabled);
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      AppLocalizations.of(context).contraindicationsSaved,
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

/// Скруглённый бейдж-иконка строки тега (роли темы, 40dp).
class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppContainer(
      width: 40,
      height: 40,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Center(
        child: AppIcon(icon, size: 22, color: scheme.onSecondaryContainer),
      ),
    );
  }
}
