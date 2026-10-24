// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Диалог UI-кита (обёртка [AlertDialog]).
///
/// Материальный [AlertDialog] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppDialog] и [showAppDialog]. Оформление
/// задаётся темой (`dialogTheme`, этап 54): `surfaceContainerHigh`,
/// радиус `AppRadii.xxl`.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.scrollable = false,
  });

  /// Заголовок диалога — обычно [AppText] роли `titleLarge`.
  final Widget? title;

  /// Содержимое — [AppText], форма или произвольный виджет.
  final Widget? content;

  /// Действия (кнопки) — [AppTextButton] (отмена/деструктивное) слева,
  /// [AppButton] (primary) справа; контракт 54.6.
  final List<Widget>? actions;

  /// Прокручиваемое содержимое (длинные списки ошибок).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
    );
  }
}

/// Показ диалога UI-кита (обёртка [showDialog]).
///
/// Единая точка вызова модалок в приложении: прямые [showDialog] и
/// [AlertDialog] вне `lib/uikit/` запрещены.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
  );
}
