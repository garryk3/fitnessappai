// ignore_for_file: type=lint
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fitnessappai/uikit/app_container.dart';
import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_text_form_field.dart';

/// Числовое поле со степпером «+ / −» (редизайн 54, образец «Параметры
/// упражнения»): лейбл-плывущая подпись над крупным значением, кнопки ±
/// столбиком справа, необязательный иконочный бейдж слева.
///
/// Сохраняет контракт обычного `TextFormField`: лейбл — через `labelText`
/// (`find.widgetWithText(TextFormField, label)`), ввод — через контроллер
/// (`enterText`), валидация — `Form`/`validator` с
/// [AutovalidateMode.onUserInteraction]. Изменение значения кнопками ± идёт
/// через `controller.text` → `didChange` поля, поэтому ошибка валидации
/// появляется/снимается «вживую» (проверено по исходнику Flutter).
///
/// Арифметика кнопок: шаг [step], снизу клампится [min] (по умолчанию 0 —
/// «−» до нуля, валидатор решает, допустимо ли 0); пустое поле: «+» пишет
/// [step], «−» не делает ничего. Дробные поля ([decimals]) форматируются
/// без хвостовых нулей (5.0 → «5», 5.5 → «5.5»).
///
/// Кнопки без тултипа объявляются скринридером без имени — передавайте
/// [increaseTooltip]/[decreaseTooltip] (l10n).
class AppNumberStepper extends StatelessWidget {
  const AppNumberStepper({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.step = 1,
    this.min = 0,
    this.decimals = false,
    this.icon,
    this.style,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.onChanged,
    this.increaseTooltip,
    this.decreaseTooltip,
    this.helperText,
  });

  final TextEditingController controller;

  /// Подпись поля (labelText `TextFormField`).
  final String label;

  /// Валидатор `Form`.
  final FormFieldValidator<String> validator;

  /// Шаг кнопок «+»/«−» (1 — целые, 0.5 — вес/дистанция).
  final double step;

  /// Нижняя граница арифметики кнопок (значения из ввода не клампятся —
  /// валидация остаётся у [validator]).
  final double min;

  /// Дробное поле: формат с плавающей точкой и соответствующая клавиатура.
  final bool decimals;

  /// Необязательный иконочный бейдж слева от поля (укруглённая плашка).
  final IconData? icon;

  /// Стиль значения (по умолчанию — окружной DefaultTextStyle поля).
  final TextStyle? style;

  final AutovalidateMode autovalidateMode;

  /// Вызывается при любом изменении значения (ввод или кнопки ±).
  final ValueChanged<String>? onChanged;

  /// Тултипы/а11y-подписи кнопок (l10n) — обязательны для доступности.
  final String? increaseTooltip;
  final String? decreaseTooltip;

  /// Необязательная служебная подпись под полем (`helperText` — например,
  /// plank-подсказка «Пусто — время удержания со счётчика»).
  final String? helperText;

  double? _parse() {
    final text = controller.text.trim().replaceAll(',', '.');
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  static String _format(double value) {
    final rounded = (value * 100).round() / 100;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
  }

  void _apply(double value) {
    controller.text = _format(math.max(value, min));
    onChanged?.call(controller.text);
  }

  void _increase() {
    final current = _parse();
    _apply(current == null ? step : current + step);
  }

  void _decrease() {
    final current = _parse();
    if (current == null) {
      return;
    }
    _apply(math.max(current - step, min));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorSide = BorderSide(color: theme.colorScheme.error, width: 1.5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          AppContainer(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AppTextFormField(
            controller: controller,
            style: style,
            validator: validator,
            autovalidateMode: autovalidateMode,
            onChanged: onChanged,
            keyboardType: TextInputType.numberWithOptions(decimal: decimals),
            inputFormatters: [
              if (decimals)
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
              else
                FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
              // Не обрывается на крупном шрифте (fontScale ≥1.3 — дизайн-ревью 55.1).
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              // Валидное значение — без рамки (по образцу); ошибка — красная
              // рамка поля + служебный текст валидатора.
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              errorBorder: OutlineInputBorder(borderSide: errorSide),
              focusedErrorBorder: OutlineInputBorder(borderSide: errorSide),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: increaseTooltip,
              onPressed: _increase,
              icon: const AppIcon(Icons.add),
            ),
            IconButton(
              tooltip: decreaseTooltip,
              onPressed: _decrease,
              icon: const AppIcon(Icons.remove),
            ),
          ],
        ),
      ],
    );
  }
}
