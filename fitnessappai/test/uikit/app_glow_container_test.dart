// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/uikit/app_glow_container.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
}) async {
  final ThemeData theme = brightness == Brightness.dark
      ? AppTheme.dark()
      : AppTheme.light();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: child),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  final Container container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppGlowContainer),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('AppGlowContainer', () {
    testWidgets('рендерит child', (tester) async {
      await _pump(tester, const AppGlowContainer(child: Text('Содержимое')));

      expect(find.text('Содержимое'), findsOneWidget);
    });

    testWidgets('тёмная тема: единственная glow-тень из токенов', (
      tester,
    ) async {
      await _pump(tester, const AppGlowContainer(child: Text('x')));

      final BoxDecoration decoration = _decoration(tester);
      expect(
        decoration.boxShadow,
        hasLength(1),
        reason: 'max 1 glow на виджет',
      );
      final BoxShadow shadow = decoration.boxShadow!.single;
      expect(shadow.blurRadius, AppGlow.radius);
      expect(shadow.spreadRadius, AppGlow.spread);
      expect(shadow.color.a, moreOrLessEquals(AppGlow.alpha, epsilon: 0.01));
    });

    testWidgets('светлая тема: без glow, обводка остаётся', (tester) async {
      await _pump(
        tester,
        const AppGlowContainer(child: Text('x')),
        brightness: Brightness.light,
      );

      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.boxShadow, isEmpty);
      expect(decoration.border, isNotNull);
    });

    testWidgets('showBorder=false убирает обводку, glow остаётся', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppGlowContainer(showBorder: false, child: Text('x')),
      );

      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, hasLength(1));
    });

    testWidgets('custom color окрашивает свечение и обводку', (tester) async {
      const Color accent = Color(0xFF123456);
      await _pump(
        tester,
        const AppGlowContainer(color: accent, child: Text('x')),
      );

      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.boxShadow!.single.color.r, accent.r);
      final BorderSide side = decoration.border!.top;
      expect(side.color.r, accent.r);
    });

    testWidgets('intensity масштабирует альфу свечения', (tester) async {
      await _pump(
        tester,
        const AppGlowContainer(intensity: 0.5, child: Text('x')),
      );

      final BoxShadow shadow = _decoration(tester).boxShadow!.single;
      expect(
        shadow.color.a,
        moreOrLessEquals(AppGlow.alpha * 0.5, epsilon: 0.01),
      );
    });

    testWidgets('radius-токен задаёт скругление', (tester) async {
      await _pump(
        tester,
        const AppGlowContainer(radius: AppRadii.xl, child: Text('x')),
      );

      final BorderRadius radius =
          _decoration(tester).borderRadius! as BorderRadius;
      expect(radius.topLeft.x, AppRadii.xl);
    });
  });
}
