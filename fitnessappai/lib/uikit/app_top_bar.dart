// ignore_for_file: type=lint
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_text.dart';

/// Верхняя панель UI-кита — единственная точка использования Material [AppBar].
///
/// Материальный [AppBar] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppTopBar] (иначе падает правило `ban_appbar_widget`).
///
/// Заголовок можно задать строкой [title] (тогда он рендерится через [AppText]
/// со стилем из `AppBarTheme`) или произвольным виджетом [titleWidget].
///
/// Редизайн 54 (DESIGN.md §11): базовый текстовый стиль — `headlineMedium`
/// из темы; для корневых экранов (без кнопки «назад», по образцам) —
/// `large: true` (стиль `displaySmall`). Вес обоих — w600 по образцам
/// templates/ (semibold). Отступы — дефолтные M3 (единые).
///
/// **Двухстрочная обрезка:** строковый заголовок переносится максимум на
/// 2 строки, далее — ellipsis; высота шапки подгоняется под замеренный текст
/// (`TextPainter` по фактическим констрейнтам слота — не по MediaQuery, т.к.
/// в wide-раскладке с rail тулбар уже на ширину rail), чтобы вторая строка не
/// обрезалась. Одинаковый стиль для заголовков любой длины — кегль не
/// уменьшается.
///
/// Высота уходит в [preferredSize] через холдер [_MeasuredHeight]. Важный
/// нюанс: `Scaffold` читает `preferredSize` в **своём** `build`, который
/// выполняется ДО `build` дочерней шапки, поэтому при первом кадре (и при
/// каждом новом экземпляре виджета) в холдере ещё старое значение. Если новое
/// измерение отличается, шапка пост-фреймом помечает ancestor-`Scaffold`
/// грязным ([_AppTopBarState._schedulePreferredSizeSync]) — на следующем
/// кадре слот перестраивается под точную высоту. Это необходимо: `AppBar`
/// заворачивает тулбар в `Align(topCenter)` и растягивается ровно до высоты,
/// отданной Scaffold'ом из `preferredSize`; если она меньше измеренной —
/// вторая строка заголовка обрезается.
class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.large = false,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.centerTitle,
    this.toolbarHeight,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
  }) : _measuredHeight = _MeasuredHeight();

  /// Текстовый заголовок.
  final String? title;

  /// Заголовок-виджет (приоритетнее [title]).
  final Widget? titleWidget;

  /// true — крупный заголовок корневого экрана (`displaySmall`, по образцам
  /// редизайна); false — обычный (`headlineMedium` из темы AppBar).
  final bool large;

  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final bool? centerTitle;
  final double? toolbarHeight;
  final double toolbarOpacity;
  final double bottomOpacity;

  /// Измеренная в build высота тулбара (заполняется [_AppTopBarState]).
  final _MeasuredHeight _measuredHeight;

  /// Максимум строк строкового заголовка (двухстрочная обрезка, §11).
  static const int _kTitleMaxLines = 2;

  /// Вертикальный отступ вокруг строк заголовка при подгонке высоты.
  static const double _kTitleVerticalPadding = 16;

  /// Дополнительный запас ширины при оценке переносов (недооценка ширины
  /// опаснее переоценки: переоценка даёт лишь чуть более высокую шапку).
  static const double _kTitleWidthSafety = 16;

  /// Кламп масштаба текста заголовка — зеркалит приватный
  /// `_kMaxTitleTextScaleFactor` Flutter [AppBar] (титл не растёт выше).
  static const double _kMaxTitleTextScaleFactor = 1.34;

  // Высота зеркалит поведение Flutter `AppBar`: при явном `toolbarHeight`
  // возвращается он; иначе — измеренная в build высота тулбара (до первого
  // build — дефолт kToolbarHeight).
  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight ??
        _measuredHeight.value + (bottom?.preferredSize.height ?? 0),
  );

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

/// Холдер измеренной высоты тулбара — общий объект виджета и его [State].
class _MeasuredHeight {
  double value = kToolbarHeight;
}

class _AppTopBarState extends State<AppTopBar> {
  /// Запланирована ли пост-фреймовая синхронизация `preferredSize` со
  /// Scaffold'ом (защита от повторной подписки в одном кадре).
  bool _syncScheduled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Редизайн 54 (§11): обычный заголовок — headlineMedium (28/36, по
    // образцам «Новый замер»); корневой экран (large) — displaySmall (36/44,
    // «Главная»). Цвет — onSurface; стиль берётся из контекстной темы
    // (локализованной MaterialApp), а не из standalone ThemeData. Вес w600 —
    // по образцам templates/ (semibold; M3-дефолт w400 визуально легче).
    final baseStyle =
        theme.appBarTheme.titleTextStyle ?? theme.textTheme.headlineMedium;
    final TextStyle? baseTitleStyle = widget.large
        ? theme.textTheme.displaySmall?.copyWith(
            color: baseStyle?.color ?? theme.colorScheme.onSurface,
          )
        : baseStyle;
    final TextStyle? titleStyle = baseTitleStyle?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final bool canMeasureTitle =
        widget.toolbarHeight == null &&
        widget.titleWidget == null &&
        widget.title != null;
    final bool hasLeading =
        widget.leading != null ||
        (widget.automaticallyImplyLeading &&
            (ModalRoute.of(context)?.canPop ?? false));
    final int actionsCount = widget.actions?.length ?? 0;
    // Двухстрочная обрезка (§11): перенос максимум на 2 строки, далее
    // ellipsis; высота тулбара уточняется под замеренный текст, чтобы вторая
    // строка не обрезалась. DefaultTextStyle AppBar задаёт softWrap: false —
    // поэтому softWrap/maxLines передаём явно.
    //
    // Замер идёт по ФАКТИЧЕСКИМ констрейнтам слота шапки (LayoutBuilder), а
    // не MediaQuery: в wide-раскладке с NavigationRail тулбар уже на ширину
    // rail (81–257dp) — по полной ширине окна замер решил бы «1 строка» и
    // вторая строка обрезалась бы. LayoutBuilder перестраивает child только
    // при смене constraints — TextPainter-замер не гоняется на каждый кадр.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double slotWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double previousToolbarHeight = widget._measuredHeight.value;
        final double resolvedToolbarHeight =
            widget.toolbarHeight ??
            (canMeasureTitle
                ? _measureToolbarHeight(
                    context,
                    titleStyle,
                    slotWidth,
                    hasLeading,
                    actionsCount,
                  )
                : kToolbarHeight);
        widget._measuredHeight.value = resolvedToolbarHeight;
        // Scaffold читал preferredSize ДО этого build (значение старое) —
        // если высота изменилась, перестраиваем его на следующем кадре.
        if (resolvedToolbarHeight != previousToolbarHeight) {
          _schedulePreferredSizeSync();
        }

        return AppBar(
          title:
              widget.titleWidget ??
              (widget.title == null
                  ? null
                  : AppText(
                      widget.title!,
                      style: titleStyle,
                      softWrap: true,
                      maxLines: AppTopBar._kTitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                    )),
          leading: widget.leading,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          actions: widget.actions,
          flexibleSpace: widget.flexibleSpace,
          bottom: widget.bottom,
          elevation: widget.elevation,
          scrolledUnderElevation: widget.scrolledUnderElevation,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          surfaceTintColor: widget.surfaceTintColor,
          shadowColor: widget.shadowColor,
          centerTitle: widget.centerTitle,
          toolbarHeight: resolvedToolbarHeight,
          toolbarOpacity: widget.toolbarOpacity,
          bottomOpacity: widget.bottomOpacity,
        );
      },
    );
  }

  /// По истечении кадра помечает ближайший ancestor-[Scaffold] грязным, чтобы
  /// тот перечитал `preferredSize` уже с актуальным измерением (см. док-коммент
  /// к [AppTopBar]). В build-фазе это нелегально, поэтому — post-frame;
  /// до вызова гарантируется, что кадр идёт, значит колбэк точно выполнится.
  void _schedulePreferredSizeSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      Element? scaffold;
      context.visitAncestorElements((element) {
        if (element.widget is Scaffold) {
          scaffold = element;
          return false;
        }
        return true;
      });
      scaffold?.markNeedsBuild();
    });
  }

  /// Оценивает высоту тулбара под строковый заголовок: одна строка — дефолт
  /// [kToolbarHeight], две — замеренный текст + отступ.
  ///
  /// [slotWidth] — фактическая ширина слота шапки (из LayoutBuilder); из неё
  /// вычитаются leading/actions/spacing — приближение реального места
  /// заголовка у `NavigationToolbar`. Недооценка ширины безопасна — даёт лишь
  /// шапку чуть выше необходимости; переоценка (полная ширина окна вместо
  /// слота) опасна — вторая строка обрезалась бы в wide-раскладке с rail.
  double _measureToolbarHeight(
    BuildContext context,
    TextStyle? style,
    double slotWidth,
    bool hasLeading,
    int actionsCount,
  ) {
    final double leadingWidth = hasLeading ? kToolbarHeight : 0;
    final double actionsWidth = actionsCount * kMinInteractiveDimension;
    const double middleSpacing = 16 * 2; // NavigationToolbar.kMiddleSpacing*2
    final double available = math.max(
      slotWidth -
          leadingWidth -
          actionsWidth -
          middleSpacing -
          AppTopBar._kTitleWidthSafety,
      0,
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(text: widget.title, style: style),
      textDirection: Directionality.of(context),
      // Кламп зеркалит AppBar: титл не растёт выше 1.34.
      textScaler: MediaQuery.textScalerOf(
        context,
      ).clamp(maxScaleFactor: AppTopBar._kMaxTitleTextScaleFactor),
      maxLines: AppTopBar._kTitleMaxLines,
    )..layout(maxWidth: available);
    final double textHeight = painter.height;
    painter.dispose();
    return math.max(
      kToolbarHeight,
      textHeight + AppTopBar._kTitleVerticalPadding,
    );
  }
}
