// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/uikit/app_number_stepper.dart';

Future<void> _pumpStepper(
  WidgetTester tester, {
  required TextEditingController controller,
  String? Function(String?)? validator,
  double step = 1,
  bool decimals = false,
  ValueChanged<String>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Form(
          child: AppNumberStepper(
            controller: controller,
            label: 'Подходы',
            validator: validator ?? (_) => null,
            step: step,
            decimals: decimals,
            onChanged: onChanged,
            increaseTooltip: 'Увеличить',
            decreaseTooltip: 'Уменьшить',
          ),
        ),
      ),
    ),
  );
}

String? _requiredPositive(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Заполните поле';
  }
  final number = int.tryParse(text);
  if (number == null || number < 1) {
    return 'Минимум 1';
  }
  return null;
}

Finder _plus() => find.byTooltip('Увеличить');
Finder _minus() => find.byTooltip('Уменьшить');

void main() {
  group('AppNumberStepper', () {
    testWidgets('контракт TextFormField: лейбл и ввод сохраняются', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpStepper(tester, controller: controller);

      expect(find.widgetWithText(TextFormField, 'Подходы'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Подходы'),
        '7',
      );
      expect(controller.text, '7');
    });

    testWidgets('«+» увеличивает на step, «−» уменьшает', (tester) async {
      final controller = TextEditingController(text: '3');
      addTearDown(controller.dispose);
      await _pumpStepper(tester, controller: controller);

      await tester.tap(_plus());
      expect(controller.text, '4');
      await tester.tap(_plus());
      await tester.tap(_minus());
      expect(controller.text, '4');
    });

    testWidgets('«−» на нижней границе — no-op (min)', (tester) async {
      final controller = TextEditingController(text: '0');
      addTearDown(controller.dispose);
      await _pumpStepper(tester, controller: controller);

      await tester.tap(_minus());
      expect(controller.text, '0');
    });

    testWidgets('пустое поле: «+» пишет step, «−» — no-op', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpStepper(tester, controller: controller);

      await tester.tap(_minus());
      expect(controller.text, '');
      await tester.tap(_plus());
      expect(controller.text, '1');
    });

    testWidgets('дробный шаг 0.5 без хвостовых нулей', (tester) async {
      final controller = TextEditingController(text: '5');
      addTearDown(controller.dispose);
      await _pumpStepper(
        tester,
        controller: controller,
        decimals: true,
        step: 0.5,
      );

      await tester.tap(_plus());
      expect(controller.text, '5.5');
      await tester.tap(_plus());
      expect(controller.text, '6');
      await tester.tap(_minus());
      expect(controller.text, '5.5');
    });

    testWidgets('дробная запятая из ввода разбирается (5,5 + 0.5 = 6)', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpStepper(
        tester,
        controller: controller,
        decimals: true,
        step: 0.5,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Подходы'),
        '5,5',
      );

      await tester.tap(_plus());
      expect(controller.text, '6');
    });

    testWidgets('ошибка валидации появляется и снимается «вживую»', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpStepper(
        tester,
        controller: controller,
        validator: _requiredPositive,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Подходы'),
        '0',
      );
      await tester.pump();
      expect(find.text('Минимум 1'), findsOneWidget);

      await tester.tap(_plus());
      await tester.pump();
      expect(controller.text, '1');
      expect(find.text('Минимум 1'), findsNothing);
    });

    testWidgets('«−» до 0 у обязательного поля показывает ошибку (образец)', (
      tester,
    ) async {
      final controller = TextEditingController(text: '1');
      addTearDown(controller.dispose);
      await _pumpStepper(
        tester,
        controller: controller,
        validator: _requiredPositive,
      );

      await tester.tap(_minus());
      await tester.pump();
      expect(controller.text, '0');
      expect(find.text('Минимум 1'), findsOneWidget);
    });

    testWidgets('onChanged вызывается и при вводе, и при кнопках', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final received = <String>[];
      await _pumpStepper(
        tester,
        controller: controller,
        onChanged: received.add,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Подходы'),
        '2',
      );
      await tester.tap(_plus());

      expect(received, ['2', '3']);
    });
  });
}
