// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/uikit/app_gradient_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

Future<void> _pumpDark(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AppGradientButton', () {
    testWidgets('рендерит label', (tester) async {
      await _pump(tester, AppGradientButton(label: 'Старт', onPressed: () {}));

      expect(find.text('Старт'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('без icon не рисует Icon', (tester) async {
      await _pump(tester, AppGradientButton(label: 'Старт', onPressed: () {}));

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('с иконкой рисует её', (tester) async {
      await _pump(
        tester,
        AppGradientButton(
          label: 'Старт',
          onPressed: () {},
          icon: Icons.play_arrow,
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('onPressed вызывается по тапу', (tester) async {
      var pressed = false;
      await _pump(
        tester,
        AppGradientButton(label: 'Старт', onPressed: () => pressed = true),
      );

      await tester.tap(find.text('Старт'));
      expect(pressed, isTrue);
    });

    testWidgets('onPressed=null — кнопка неактивна', (tester) async {
      await _pump(tester, AppGradientButton(label: 'Старт', onPressed: null));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('busy=true — спиннер вместо текста и disabled', (tester) async {
      await _pump(
        tester,
        AppGradientButton(
          label: 'Старт',
          busy: true,
          onPressed: () => fail('busy не должен вызываться'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Старт'), findsNothing);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('дефолтный градиент — токен AppGradients.primaryCta', (
      tester,
    ) async {
      await _pump(tester, AppGradientButton(label: 'Старт', onPressed: () {}));

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AppGradientButton),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.gradient, same(AppGradients.primaryCta));
    });

    testWidgets('pill=true — скругление AppRadii.pill', (tester) async {
      await _pump(
        tester,
        AppGradientButton(label: 'Старт', pill: true, onPressed: () {}),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AppGradientButton),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(AppRadii.pill));
    });

    testWidgets('тёмная тема: glow-тень из токенов AppGlow', (tester) async {
      await _pumpDark(
        tester,
        AppGradientButton(label: 'Старт', onPressed: () {}),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AppGradientButton),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.blurRadius, AppGlow.radius);
    });

    testWidgets('светлая тема: без glow-тени', (tester) async {
      await _pump(tester, AppGradientButton(label: 'Старт', onPressed: () {}));

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AppGradientButton),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });
  });
}
