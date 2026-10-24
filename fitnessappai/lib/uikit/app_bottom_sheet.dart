// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Bottom sheet UI-кита (обёртка [showModalBottomSheet]).
///
/// Материальный вызов разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [showAppBottomSheet]. Оформление задаётся темой
/// (`bottomSheetTheme`, этап 55.2): `surfaceContainerLow`, верхний радиус
/// `AppRadii.xxl`, drag-handle включён по умолчанию.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
  );
}
