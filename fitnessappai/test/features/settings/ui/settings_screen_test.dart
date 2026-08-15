import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/features/settings/ui/settings_screen.dart';
import 'package:fitnessappai/features/settings/ui/sync_controller.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_validation_exception.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

class _FakeSyncService implements SyncService {
  String exportPath = 'backup.sqlite';
  Object? importError;
  int importCalls = 0;
  int exportCalls = 0;

  @override
  Future<String> export() async {
    exportCalls++;
    return exportPath;
  }

  @override
  Future<void> import(String sourcePath) async {
    importCalls++;
    final error = importError;
    if (error != null) {
      throw error;
    }
  }
}

void main() {
  late _FakeSyncService service;
  late String? pickedPath;
  late String? sharedPath;

  setUp(() {
    service = _FakeSyncService();
    pickedPath = null;
    sharedPath = null;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    SyncService? syncService,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = SyncController(
      syncServiceFactory: () => syncService ?? service,
      pickFile: () async => pickedPath,
      shareFile: (path) async {
        sharedPath = path;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: SettingsScreen(syncController: controller),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает секции синхронизации и темы', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Синхронизация'), findsOneWidget);
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Выбор темы появится позже'), findsOneWidget);
    expect(find.text('Экспортировать БД'), findsOneWidget);
    expect(find.text('Импортировать БД'), findsOneWidget);
    expect(find.text('Облачная синхронизация появится позже.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('экспорт делится файлом и показывает статус', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Экспортировать БД'));
    await tester.pumpAndSettle();

    expect(service.exportCalls, 1);
    expect(sharedPath, 'backup.sqlite');
    expect(find.text('Резервная копия создана и отправлена'), findsOneWidget);
  });

  testWidgets('импорт с отменой выбора не трогает БД', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Импортировать БД'));
    await tester.pumpAndSettle();

    expect(service.importCalls, 0);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('импорт отклоняет несовместимый файл с сообщением', (
    tester,
  ) async {
    service.importError = const SyncValidationException(
      'Несовместимая версия схемы: 99 (ожидается 1)',
    );
    pickedPath = 'bad.sqlite';
    await pumpScreen(tester);

    await tester.tap(find.text('Импортировать БД'));
    await tester.pumpAndSettle();

    expect(service.importCalls, 1);
    expect(
      find.text('Несовместимая версия схемы: 99 (ожидается 1)'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('успешный импорт показывает диалог перезапуска', (tester) async {
    pickedPath = 'good.sqlite';
    await pumpScreen(tester);

    await tester.tap(find.text('Импортировать БД'));
    await tester.pumpAndSettle();

    expect(service.importCalls, 1);
    expect(find.text('База данных импортирована'), findsWidgets);
    expect(
      find.text(
        'Для полного применения изменений приложение будет перезапущено.',
      ),
      findsOneWidget,
    );
  });
}
