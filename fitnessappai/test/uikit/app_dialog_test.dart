// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_dialog.dart';
import 'package:fitnessappai/uikit/app_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppDialog', () {
    testWidgets('рендерит AlertDialog с заголовком, контентом и действиями', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppDialog(
          title: AppText('Заголовок'),
          content: AppText('Содержимое'),
          actions: [AppText('Ок')],
        ),
      );

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Заголовок'), findsOneWidget);
      expect(find.text('Содержимое'), findsOneWidget);
      expect(find.text('Ок'), findsOneWidget);
    });

    testWidgets('title/content/actions опциональны', (tester) async {
      await _pump(tester, const AppDialog());

      expect(find.byType(AlertDialog), findsOneWidget);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.title, isNull);
      expect(dialog.content, isNull);
      expect(dialog.actions, isNull);
    });

    testWidgets('scrollable прокидывается в AlertDialog', (tester) async {
      await _pump(tester, const AppDialog(scrollable: true));

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
    });
  });

  group('showAppDialog', () {
    testWidgets('открывает диалог и возвращает результат', (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (pageContext) => FilledButton(
              onPressed: () async {
                result = await showAppDialog<String>(
                  context: pageContext,
                  builder: (dialogContext) => AppDialog(
                    content: const AppText('Тело'),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop('ok'),
                        child: const AppText('Ок'),
                      ),
                    ],
                  ),
                );
              },
              child: const AppText('Показать'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Показать'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('Тело'), findsOneWidget);

      await tester.tap(find.text('Ок'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsNothing);
      expect(result, 'ok');
    });

    testWidgets('barrierDismissible: false — закрытие по барьеру выключено', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (pageContext) => FilledButton(
              onPressed: () => showAppDialog<String>(
                context: pageContext,
                barrierDismissible: false,
                builder: (dialogContext) =>
                    const AppDialog(content: AppText('Тело')),
              ),
              child: const AppText('Показать'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Показать'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsOneWidget);
    });
  });
}
