import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/app/theme/theme_settings_repository.dart';
import 'package:fitnessappai/core/database/app_database.dart';
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
  late AppDatabase db;
  late ThemeController themeController;

  setUp(() {
    service = _FakeSyncService();
    pickedPath = null;
    sharedPath = null;
    db = AppDatabase(executor: NativeDatabase.memory());
    themeController = ThemeController(ThemeSettingsRepository(db));
    addTearDown(db.close);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    SyncService? syncService,
    Future<String?> Function()? pickFile,
    Future<void> Function(String path)? shareFile,
    Future<bool> Function(String path)? saveFile,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = SyncController(
      syncServiceFactory: () => syncService ?? service,
      pickFile: pickFile ?? () async => pickedPath,
      shareFile:
          shareFile ??
          (path) async {
            sharedPath = path;
          },
      saveFile: saveFile ?? (_) async => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: SettingsScreen(
          syncController: controller,
          themeController: themeController,
        ),
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
    expect(find.text('Тёмная'), findsOneWidget);
    expect(find.text('Светлая'), findsOneWidget);
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
    expect(find.text('Экспортировать БД'), findsNothing);
    expect(find.text('Поделиться'), findsOneWidget);
    expect(find.text('Сохранить в файлы'), findsOneWidget);
    expect(find.text('Импортировать БД'), findsOneWidget);
    expect(find.text('Облачная синхронизация появится позже.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('выбор темы сохраняется и переключает контроллер', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();

    expect(themeController.value, ThemeMode.light);
    expect(await ThemeSettingsRepository(db).getThemeMode(), ThemeMode.light);
  });

  testWidgets('экспорт делится файлом и показывает статус', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Поделиться'));
    await tester.pumpAndSettle();

    expect(service.exportCalls, 1);
    expect(sharedPath, 'backup.sqlite');
    expect(find.text('Резервная копия создана и отправлена'), findsOneWidget);
  });

  testWidgets('экспорт сохраняет файл в файловую систему', (tester) async {
    String? savedTo;
    await pumpScreen(
      tester,
      saveFile: (path) async {
        savedTo = path;
        return true;
      },
    );

    await tester.tap(find.text('Сохранить в файлы'));
    await tester.pumpAndSettle();

    expect(service.exportCalls, 1);
    expect(savedTo, 'backup.sqlite');
    expect(find.text('Резервная копия сохранена'), findsOneWidget);
  });

  testWidgets('отмена сохранения файла показывает статус без ошибки', (
    tester,
  ) async {
    await pumpScreen(tester, saveFile: (_) async => false);

    await tester.tap(find.text('Сохранить в файлы'));
    await tester.pumpAndSettle();

    expect(service.exportCalls, 1);
    expect(find.text('Сохранение отменено'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
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

  testWidgets('экспорт перехватывает Error (не только Exception)', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      shareFile: (_) async => throw UnimplementedError('sharing'),
    );

    await tester.tap(find.text('Поделиться'));
    await tester.pumpAndSettle();

    expect(service.exportCalls, 1);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      find.textContaining('операция недоступна на этой платформе'),
      findsOneWidget,
    );
  });

  testWidgets('импорт перехватывает Error из пикера', (tester) async {
    await pumpScreen(
      tester,
      pickFile: () async => throw UnimplementedError('picker'),
    );

    await tester.tap(find.text('Импортировать БД'));
    await tester.pumpAndSettle();

    expect(service.importCalls, 0);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      find.textContaining('операция недоступна на этой платформе'),
      findsOneWidget,
    );
  });

  testWidgets('импорт перехватывает Error из сервиса импорта', (tester) async {
    service.importError = UnimplementedError('db');
    pickedPath = 'bad.sqlite';
    await pumpScreen(tester);

    await tester.tap(find.text('Импортировать БД'));
    await tester.pumpAndSettle();

    expect(service.importCalls, 1);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
