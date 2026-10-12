// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Поле ввода UI-кита для `Form` (с валидацией и сохранением).
///
/// Материальный [TextFormField] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppTextFormField] (иначе падает правило
/// `ban_textformfield_widget`). Для поля вне `Form` — [AppTextField].
class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.style,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled,
    this.readOnly = false,
    this.autofocus = false,
    this.validator,
    this.autovalidateMode,
    this.onChanged,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.inputFormatters,
    this.buildCounter,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;

  /// Явная декорация; при `null` собирается из [labelText]/[hintText]/…
  final InputDecoration? decoration;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextStyle? style;
  final bool obscureText;
  final String obscuringCharacter;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool? enabled;
  final bool readOnly;
  final bool autofocus;

  /// Валидатор `Form`.
  final FormFieldValidator<String>? validator;

  /// Режим авто-валидации `Form`.
  final AutovalidateMode? autovalidateMode;

  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final List<TextInputFormatter>? inputFormatters;
  final InputCounterWidgetBuilder? buildCounter;

  /// Удобства для [decoration], когда она не задана явно.
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      decoration:
          decoration ??
          InputDecoration(
            labelText: labelText,
            hintText: hintText,
            errorText: errorText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      style: style,
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      validator: validator,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      onTap: onTap,
      onTapOutside: onTapOutside,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      onSaved: onSaved,
      inputFormatters: inputFormatters,
      buildCounter: buildCounter,
    );
  }
}
