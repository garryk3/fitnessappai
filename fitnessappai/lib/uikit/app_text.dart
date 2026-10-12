// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Текст UI-кита — единственная точка рендера текста в приложении.
///
/// Материальный [Text] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppText] (иначе падает правило `ban_text_widget`).
///
/// Стиль по умолчанию НЕ навязывается: если [style] не задан, применяется
/// окружной `DefaultTextStyle` (как у голого [Text]) — так текст внутри кнопок,
/// полей и списков получает тему своего родителя. Это гарантирует визуальную
/// эквивалентность при миграции `Text` → [AppText].
///
/// Форма с несколькими стилями — [AppText.rich] (замена `Text.rich`).
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  /// Текст из нескольких фрагментов ([InlineSpan]) — замена `Text.rich`.
  const AppText.rich(
    this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  /// Отображаемый текст (для [AppText]); `null` у [AppText.rich].
  final String? data;

  /// Размеченный текст (для [AppText.rich]); `null` у [AppText].
  final InlineSpan? textSpan;

  /// Явный стиль; при `null` наследуется `DefaultTextStyle`.
  final TextStyle? style;

  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final span = textSpan;
    if (span != null) {
      return Text.rich(
        span,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return Text(
      data ?? '',
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
