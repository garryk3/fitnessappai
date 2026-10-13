// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Список UI-кита — единственная точка использования Material [ListView].
///
/// Материальный [ListView] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppListView]/[AppListView.builder]/[AppListView.separated]
/// (иначе падает правило `ban_listview_widget`).
class AppListView extends StatelessWidget {
  const AppListView({
    super.key,
    required this.children,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  }) : itemCount = null,
       itemBuilder = null,
       separatorBuilder = null;

  const AppListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  }) : children = null,
       separatorBuilder = null;

  const AppListView.separated({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  }) : children = null;

  /// Дети для «плиточного» конструктора.
  final List<Widget>? children;

  /// Количество элементов для ленивых конструкторов.
  final int? itemCount;

  /// Построитель элементов для ленивых конструкторов.
  final IndexedWidgetBuilder? itemBuilder;

  /// Построитель разделителей для [AppListView.separated].
  final IndexedWidgetBuilder? separatorBuilder;

  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool reverse;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder case final buildSeparator?) {
      return ListView.separated(
        padding: padding,
        scrollDirection: scrollDirection,
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        reverse: reverse,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        keyboardDismissBehavior: keyboardDismissBehavior,
        clipBehavior: clipBehavior,
        itemCount: itemCount!,
        itemBuilder: itemBuilder!,
        separatorBuilder: buildSeparator,
      );
    }
    if (itemBuilder case final buildItem?) {
      return ListView.builder(
        padding: padding,
        scrollDirection: scrollDirection,
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        reverse: reverse,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        keyboardDismissBehavior: keyboardDismissBehavior,
        clipBehavior: clipBehavior,
        itemCount: itemCount!,
        itemBuilder: buildItem,
      );
    }
    return ListView(
      padding: padding,
      scrollDirection: scrollDirection,
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      keyboardDismissBehavior: keyboardDismissBehavior,
      clipBehavior: clipBehavior,
      children: children ?? const <Widget>[],
    );
  }
}
