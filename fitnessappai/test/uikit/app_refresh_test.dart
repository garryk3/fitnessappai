// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_refresh.dart';
import 'package:fitnessappai/uikit/app_text.dart';

void main() {
  testWidgets('AppRefresh — пасс-тру onRefresh/child в RefreshIndicator', (
    tester,
  ) async {
    Future<void> onRefresh() async {}

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRefresh(
            onRefresh: onRefresh,
            child: ListView(
              children: const [SizedBox(height: 400, child: AppText('Список'))],
            ),
          ),
        ),
      ),
    );

    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.child, isA<ListView>());
    // Обёртка передала замыкание один-в-один.
    expect(indicator.onRefresh.toString(), onRefresh.toString());
  });
}
