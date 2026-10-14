// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/uikit/app_text.dart';

/// Сегментированный переключатель UI-кита в pill-форме
/// (редизайн 54, DESIGN.md §11): Неделя/Месяц/Год, пол и т.п.
///
/// Тонкая обёртка над `SegmentedButton`: пилюля ([AppRadii.pill]),
/// текст — через [AppText] labelLarge; цвета ролей не переопределяются —
/// берутся M3-дефолтом из темы (индикатор `secondaryContainer`,
/// текст `onSecondaryContainer`). Сырой `SegmentedButton` вне
/// `lib/uikit/` не используется.
class AppSegmentedButton<T> extends StatelessWidget {
  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.expanded = false,
    this.multiSelectionEnabled = false,
    this.showSelectedIcon = false,
  });

  /// Значения сегментов (порядок = порядок отображения).
  final List<AppSegment<T>> segments;

  /// Выбранное значение(я).
  final Set<T> selected;

  /// null — переключатель неактивен.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// true — растянуть на всю ширину (`Expanded` + fill).
  final bool expanded;

  final bool multiSelectionEnabled;
  final bool showSelectedIcon;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
    );
    final List<ButtonSegment<T>> buttonSegments = [
      for (final AppSegment<T> segment in segments)
        ButtonSegment<T>(
          value: segment.value,
          label: AppText(segment.label),
          icon: segment.icon != null ? Icon(segment.icon) : null,
        ),
    ];
    final ButtonStyle effectiveStyle = expanded
        ? style.copyWith(visualDensity: VisualDensity.compact)
        : style;
    final SegmentedButton<T> button = SegmentedButton<T>(
      segments: buttonSegments,
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      showSelectedIcon: showSelectedIcon,
      style: effectiveStyle,
    );
    if (!expanded) {
      return button;
    }
    return Row(children: [Expanded(child: button)]);
  }
}

/// Описание одного сегмента [AppSegmentedButton].
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;

  /// Текст подписи (локализованная строка вызывающего кода).
  final String label;

  final IconData? icon;
}
