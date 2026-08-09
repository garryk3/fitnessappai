import 'package:flutter/material.dart';

/// Двухпанельный макет для широких экранов: список + детали.
class TwoPaneLayout extends StatelessWidget {
  const TwoPaneLayout({
    super.key,
    required this.leading,
    required this.trailing,
    this.leadingWidth = 360,
  });

  final Widget leading;
  final Widget trailing;
  final double leadingWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: leadingWidth, child: leading),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: trailing),
      ],
    );
  }
}
