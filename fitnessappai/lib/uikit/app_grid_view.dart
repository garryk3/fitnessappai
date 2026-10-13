// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Сетка UI-кита — единственная точка использования Material [GridView].
///
/// Материальный [GridView] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppGridView]/[AppGridView.builder]/[AppGridView.count]
/// (иначе падает правило `ban_gridview_widget`).
class AppGridView extends StatelessWidget {
  const AppGridView({
    super.key,
    required this.children,
    required this.gridDelegate,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  }) : itemCount = null,
       itemBuilder = null,
       crossAxisCount = null,
       mainAxisSpacing = 0,
       crossAxisSpacing = 0,
       childAspectRatio = 1.0,
       mainAxisExtent = null;

  const AppGridView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
  }) : children = null,
       crossAxisCount = null,
       mainAxisSpacing = 0,
       crossAxisSpacing = 0,
       childAspectRatio = 1.0,
       mainAxisExtent = null;

  const AppGridView.count({
    super.key,
    required this.children,
    required this.crossAxisCount,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent,
  }) : itemCount = null,
       itemBuilder = null,
       gridDelegate = null;

  /// Дети (для [AppGridView] и [AppGridView.count]).
  final List<Widget>? children;

  /// Сеточный делегат (для [AppGridView] и [AppGridView.builder]).
  final SliverGridDelegate? gridDelegate;

  /// Количество элементов (для [AppGridView.builder]).
  final int? itemCount;

  /// Построитель элементов (для [AppGridView.builder]).
  final IndexedWidgetBuilder? itemBuilder;

  /// Число колонок (для [AppGridView.count]).
  final int? crossAxisCount;

  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  /// Фиксированная высота ячейки (для [AppGridView.count]); взаимоисключимо
  /// с [childAspectRatio] на стороне Flutter (`GridView.count` принимает
  /// ровно одно из двух — второе должно быть `null`).
  final double? mainAxisExtent;

  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool reverse;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount case final count?) {
      return GridView.count(
        padding: padding,
        scrollDirection: scrollDirection,
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        reverse: reverse,
        keyboardDismissBehavior: keyboardDismissBehavior,
        clipBehavior: clipBehavior,
        crossAxisCount: count,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: mainAxisExtent == null ? childAspectRatio : 1.0,
        mainAxisExtent: mainAxisExtent,
        children: children ?? const <Widget>[],
      );
    }
    if (itemBuilder case final buildItem?) {
      return GridView.builder(
        padding: padding,
        scrollDirection: scrollDirection,
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        reverse: reverse,
        keyboardDismissBehavior: keyboardDismissBehavior,
        clipBehavior: clipBehavior,
        gridDelegate: gridDelegate!,
        itemCount: itemCount!,
        itemBuilder: buildItem,
      );
    }
    return GridView(
      padding: padding,
      scrollDirection: scrollDirection,
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      keyboardDismissBehavior: keyboardDismissBehavior,
      clipBehavior: clipBehavior,
      gridDelegate: gridDelegate!,
      children: children ?? const <Widget>[],
    );
  }
}
