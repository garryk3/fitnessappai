// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_text_form_field.dart';

void main() {
  group('AppTextFormField', () {
    testWidgets('показывает ошибку валидатора', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextFormField(
                labelText: 'Имя',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Обязательно' : null,
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Обязательно'), findsOneWidget);
    });

    testWidgets('initialValue подставляется', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Form(child: AppTextFormField(initialValue: 'Старт')),
          ),
        ),
      );

      expect(find.text('Старт'), findsOneWidget);
    });
  });
}
