// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Однострочное/многострочное поле ввода UI-кита.
///
/// Материальный [TextField] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppTextField] (иначе падает правило `ban_textfield_widget`).
/// Для полей внутри `Form` с валидацией — [AppTextFormField].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
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
    this.onChanged,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController? controller;
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
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  /// Удобства для [decoration], когда она не задана явно.
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
      onChanged: onChanged,
      onTap: onTap,
      onTapOutside: onTapOutside,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
    );
  }
}
