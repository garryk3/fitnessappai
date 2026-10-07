import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Разрешения Android, без которых приложение не работает или напоминания
/// приходят с задержкой (задача 47.6).
///
/// Проверка файлом, а не вызовом на устройстве: потеря разререния в манифесте
/// не ломает ни сборку, ни тесты — уведомления просто перестают приходить
/// вовремя, и это замечают только пользователи.
void main() {
  late String manifest;

  setUpAll(() {
    final file = File('android/app/src/main/AndroidManifest.xml');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'манифест должен лежать от корня пакета (cwd теста)',
    );
    manifest = file.readAsStringSync();
  });

  test(
    'USE_EXACT_ALARM объявлен: точный режим доступен без тапа пользователя',
    () {
      expect(manifest, contains('android.permission.USE_EXACT_ALARM'));
    },
  );

  test('SCHEDULE_EXACT_ALARM остаётся фолбэком для Android 12 и старше', () {
    expect(manifest, contains('android.permission.SCHEDULE_EXACT_ALARM'));
  });

  test('REQUEST_IGNORE_BATTERY_OPTIMIZATIONS объявлен: диалог исключения '
      'открывается по кнопке в настройках (48.7)', () {
    expect(manifest, contains('android.permission.REQUEST_IGNORE_BATTERY'));
  });

  test('разрешения уведомлений и перезапуска на месте', () {
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
  });
}
