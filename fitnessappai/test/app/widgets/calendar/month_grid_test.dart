// ignore_for_file: type=lint
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/widgets/calendar/month_grid.dart';
import 'package:fitnessappai/app/localization_delegates.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  /// Качает сетку в режиме заполнения высоты и возвращает размер её ячейки.
  Future<Size> cellSizeFor(WidgetTester tester, DateTime monthStart) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: MonthGridView(
            monthStart: monthStart,
            today: DateTime(2026, 10, 11),
            fillHeight: true,
            cellBuilder: (context, date) => MonthDayCell(
              day: date.day,
              background: Colors.transparent,
              foreground: Colors.white,
              onTap: () {},
              fillHeight: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getSize(find.byType(MonthDayCell).first);
  }

  testWidgets(
    'размер ячейки одинаков для месяцев с разным числом недель (51.5)',
    (tester) async {
      // Широкий экран: размер ячейки ограничивает высота, а не ширина.
      await tester.binding.setSurfaceSize(const Size(900, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Февраль 2027 — 4 недели, октябрь 2026 — 5, ноябрь 2026 — 6.
      final fourWeeks = await cellSizeFor(tester, DateTime(2027, 2));
      final fiveWeeks = await cellSizeFor(tester, DateTime(2026, 10));
      final sixWeeks = await cellSizeFor(tester, DateTime(2026, 11));

      // Ячейки квадратные.
      expect(fourWeeks.width, closeTo(fourWeeks.height, 0.5));
      // Резерв под 6 строк: размер не зависит от месяца.
      expect(fiveWeeks, fourWeeks);
      expect(sixWeeks, fourWeeks);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('месяц из 4 недель не растягивает ячейки на всю высоту (51.5)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cell = await cellSizeFor(tester, DateTime(2027, 2));

    // Резерв 6 строк, а не 4: ячейка меньше 1/4 доступной высоты.
    expect(cell.height, lessThan(600 / 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('61.3: при избытке высоты сетка центрируется по вертикали', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: MonthGridView(
            monthStart: DateTime(2027, 2),
            today: DateTime(2026, 10, 11),
            fillHeight: true,
            verticalAlignment: Alignment.center,
            cellBuilder: (context, date) => MonthDayCell(
              day: date.day,
              background: Colors.transparent,
              foreground: Colors.white,
              onTap: () {},
              fillHeight: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Верхняя строка отступает от верха экрана: пустота разделена поровну
    // (меряем контейнер сетки — у ячейки есть собственный паддинг).
    final grid = find.descendant(
      of: find.byType(MonthGridView),
      matching: find.byType(SingleChildScrollView),
    );
    final top = tester.getTopLeft(grid).dy;
    final bottom = tester.getBottomRight(grid).dy;
    expect(top, greaterThan(0));
    // Сетка центрирована: свободное место снизу равно свободному сверху.
    expect(600 - bottom, closeTo(top, 1));
  });

  testWidgets('61.3: дефолт — прижать сетку к верху (совместимость)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: MonthGridView(
            monthStart: DateTime(2027, 2),
            today: DateTime(2026, 10, 11),
            fillHeight: true,
            cellBuilder: (context, date) => MonthDayCell(
              day: date.day,
              background: Colors.transparent,
              foreground: Colors.white,
              onTap: () {},
              fillHeight: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Дефолт topCenter: контейнер сетки прижат к верху (24 — внутренний
    // паддинг ячейки, не смещение контейнера).
    final grid = find.descendant(
      of: find.byType(MonthGridView),
      matching: find.byType(SingleChildScrollView),
    );
    expect(tester.getTopLeft(grid).dy, moreOrLessEquals(0, epsilon: 0.5));
  });
}
