import 'package:material_ui/material_ui.dart';
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
      return const Center(child: AppSpinner());
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
        // 60.3: двухколоночный grid карточек тегов (в стиле карточек
        // замеров): тап по карточке — toggle, выбранная — градиент + галка.
        AppGridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // 60.3 (design-review High): extent масштабируется textScaler —
          // фиксированная высота резала описания при крупном системном
          // шрифте (fontScale 1.3, скриншот ревью).
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 124 * MediaQuery.textScalerOf(context).scale(1),
          ),
          children: [
            for (final tag in tags)
              _TagCard(
                label: tag.labelRu,
                description: _description(l10n, tag.key),
                icon: _iconFor(tag.key),
                selected: selectedKeys.contains(tag.key),
                enabled: !isSaving,
                onToggle: () => _toggleWithFeedback(
                  tag.key,
                  !selectedKeys.contains(tag.key),
                ),
              ),
          ],
        ),
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
    // 60.3 (решение владельца): снекбар «Настройки сохранены» на каждый
    // тап убран — в карточном мультивыборе это болтливый фидбек; сохранение
    // и так видно состоянием карточки.
    await _controller.toggle(key, enabled);
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

/// Карточка тега «Моё здоровье» (60.3): иконка-бейдж + название +
/// описание; выбранная — градиент карточек замеров и галка, тап — toggle.
class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Градиент выбранных — как у карточек формы замера (54.9/60.3):
    // тёмная тема — heroCard, светлая — лёгкий ролевой (DESIGN.md §11).
    final gradient = theme.brightness == Brightness.dark
        ? AppGradients.heroCard
        : AppGradients.roleSurface(theme.colorScheme);
    return Semantics(
      // 60.3 (design-review Medium): без label — текст карточки уже даёт
      // имя, иначе TalkBack произносит название дважды.
      toggled: selected,
      child: AppCard(
        onTap: enabled ? onToggle : null,
        gradient: selected ? gradient : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TagBadge(icon: icon, small: true),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Индикатор выбора: невыбранный — «пусто» (карточка без
                // градиента читается off), выбранный — галка роли primary.
                if (selected)
                  AppIcon(
                    Icons.check_circle,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: AppText(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Скруглённый бейдж-иконка тега (роли темы): 28dp в grid-карточке (60.3),
/// 40dp — прежний крупный режим.
class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.icon, this.small = false});

  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppContainer(
      width: small ? 28 : 40,
      height: small ? 28 : 40,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Center(
        child: AppIcon(
          icon,
          size: small ? 16 : 22,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
