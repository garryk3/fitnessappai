// ignore_for_file: type=lint
/// Типизированный элемент выпадающего списка для [AppDropdown].
///
/// Гибкий синтаксис Dart 3 — в call-site'ах не строится сырой
/// [DropdownMenuItem] (запрет этапа 52/56): элементы описываются парой
/// значений.
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_text.dart';

class AppDropdownItem<T> {
  const AppDropdownItem({
    required this.value,
    required this.label,
    this.labelWidget,
  });

  /// Значение пункта (`T?` — сигнатура `DropdownMenuItem.value`); для
  /// «без значения» — `null`.
  final T? value;

  /// Подпись пункта (одиночная строка — рендерит [AppText]).
  final String label;

  /// Переопределение подписи виджетом (перенос/ellipsis при длинных
  /// названиях в [AppDropdownInline]); `label` остаётся строкой-фоллбэком.
  final Widget? labelWidget;
}

/// Выпадающий список UI-кита (обёртка [DropdownButtonFormField]).
///
/// Материальный [DropdownButtonFormField] разрешён только внутри
/// `lib/uikit/`; в UI приложения используйте [AppDropdown]. Оформление
/// поля — [InputDecoration] с [labelText]; граница по умолчанию —
/// контурная (OutlineInputBorder), как во всех формах проекта.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.isExpanded = false,
    this.isDense = false,
  });

  /// Начальный выбор.
  final T? initialValue;

  /// Пункты списка.
  final List<AppDropdownItem<T>> items;

  /// `null`-выбор допустим (пустые пункты очищают значение).
  final ValueChanged<T?> onChanged;

  /// Подпись поля (FloatLabelBehavior дефолт темы).
  final String? labelText;

  /// Подсказка при пустом значении.
  final String? hintText;

  /// Растягивать выпадающий элемент на всю ширину поля.
  final bool isExpanded;

  /// Плотный вариант (компактные высоты — диалоговые пикеры).
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        isDense: isDense,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item.value,
            child: item.labelWidget ?? AppText(item.label),
          ),
      ],
      onChanged: onChanged,
      isExpanded: isExpanded,
    );
  }
}

/// Строчный селектор UI-кита (обёртка [DropdownButton]) — без подписи и
/// границы: выбор внутри содержимого карточек (метрика графика, упражнение),
/// M3-подчёркивание дефолтное.
///
/// Материальный [DropdownButton] разрешён только внутри `lib/uikit/`;
/// в UI приложения используйте [AppDropdownInline] (для полей формы —
/// [AppDropdown]).
class AppDropdownInline<T> extends StatelessWidget {
  const AppDropdownInline({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
  });

  /// Текущее значение.
  final T? value;

  /// Пункты списка.
  final List<AppDropdownItem<T>> items;

  /// В отличие от [AppDropdown] возвращает тот же тип, что и выбор
  /// (пустые (`null`) пункты задаются через `value: null`);
  /// `null` — селектор заблокирован.
  final ValueChanged<T?>? onChanged;

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item.value,
            child: item.labelWidget ?? AppText(item.label),
          ),
      ],
      onChanged: onChanged,
      isExpanded: isExpanded,
    );
  }
}
