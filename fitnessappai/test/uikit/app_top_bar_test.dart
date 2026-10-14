// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/uikit/app_text.dart';
import 'package:fitnessappai/uikit/app_top_bar.dart';

void main() {
  group('AppTopBar', () {
    testWidgets('рендерит строковый заголовок', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: AppTopBar(title: 'История')),
        ),
      );

      expect(find.text('История'), findsOneWidget);
    });

    testWidgets('titleWidget приоритетнее title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppTopBar(title: 'Строка', titleWidget: Text('Виджет')),
          ),
        ),
      );

      expect(find.text('Виджет'), findsOneWidget);
      expect(find.text('Строка'), findsNothing);
    });

    testWidgets('рендерит actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppTopBar(
              title: 'Экран',
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('54.2: дефолтный заголовок — headlineMedium из темы', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(appBar: AppTopBar(title: 'История')),
        ),
      );

      final contextTheme = Theme.of(tester.element(find.byType(AppTopBar)));
      final text = tester.widget<AppText>(find.byType(AppText));
      expect(
        text.style?.fontSize,
        contextTheme.textTheme.headlineMedium?.fontSize,
      );
    });

    testWidgets('54.2: large=true — заголовок displaySmall (корневой экран)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(appBar: AppTopBar(title: 'Главная', large: true)),
        ),
      );

      final contextTheme = Theme.of(tester.element(find.byType(AppTopBar)));
      final text = tester.widget<AppText>(find.byType(AppText));
      expect(
        text.style?.fontSize,
        contextTheme.textTheme.displaySmall?.fontSize,
      );
      // Крупнее обычного заголовка (headlineMedium).
      expect(
        text.style!.fontSize!,
        greaterThan(contextTheme.textTheme.headlineMedium!.fontSize!),
      );
    });

    testWidgets(
      '54.2: длинный заголовок — перенос на 2 строки, далее ellipsis',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              appBar: AppTopBar(
                title: 'Подготовка к очень длинной тренировке на всю ширину',
              ),
            ),
          ),
        );
        // Кадр синхронизации: Scaffold читает preferredSize в своём build
        // (до build шапки), поэтому после смены измерения он перестраивается
        // пост-фреймом — дожидаемся конвергенции.
        await tester.pumpAndSettle();

        final text = tester.widget<AppText>(find.byType(AppText));
        expect(text.softWrap, isTrue);
        expect(text.maxLines, 2);
        expect(text.overflow, TextOverflow.ellipsis);
        // Высота тулбара уходит выше дефолтной — под две строки.
        final topBar = tester.widget<AppTopBar>(find.byType(AppTopBar));
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.toolbarHeight!, greaterThan(kToolbarHeight));
        // Слот AppBar ровно = измеренной высоте: без «воздушной» подложки
        // и без обрезки второй строки (Align внутри AppBar тянется до
        // preferredSize — они обязаны совпадать).
        expect(
          tester.getSize(find.byType(AppBar)).height,
          appBar.toolbarHeight,
        );
        expect(topBar.preferredSize.height, appBar.toolbarHeight);
      },
    );

    testWidgets('54.2: короткий заголовок — дефолтная высота тулбара', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(appBar: AppTopBar(title: 'План')),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, kToolbarHeight);
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    });

    testWidgets(
      '54.2: замер идёт по констрейнтам слота, а не MediaQuery (wide-слот уже)',
      (tester) async {
        // Окно широкое (800dp — по MediaQuery заголовок уместился бы в одну
        // строку), но слот шапки узкий (300dp, как в body при rail ≥840dp) —
        // замер обязан взять ширину слота и дать 2 строки, а не обрезать.
        tester.view.physicalSize = const Size(800, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                child: Scaffold(
                  appBar: AppTopBar(
                    title: 'Очень длинный заголовок тренировки',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.toolbarHeight!, greaterThan(kToolbarHeight));
        expect(
          tester.getSize(find.byType(AppBar)).height,
          appBar.toolbarHeight,
        );
      },
    );

    testWidgets('54.2: preferredSize отражает измеренную высоту', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final bar = AppTopBar(
        title: 'Подготовка к очень длинной тренировке на всю ширину',
      );
      // До build — дефолт (холдер ещё не заполнен).
      expect(bar.preferredSize.height, kToolbarHeight);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(appBar: bar),
        ),
      );
      // После build — измеренная высота под 2 строки.
      expect(bar.preferredSize.height, greaterThan(kToolbarHeight));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.preferredSize.height, appBar.toolbarHeight);

      // Явный toolbarHeight побеждает.
      final fixed = AppTopBar(title: 'X', toolbarHeight: 64);
      expect(fixed.preferredSize.height, 64);
    });
  });
}
