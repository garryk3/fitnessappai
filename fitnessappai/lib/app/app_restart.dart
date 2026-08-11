import 'package:flutter/foundation.dart';

/// Счётчик полных перезапусков приложения.
///
/// Инкремент [appRestartTick] принудительно пересоздаёт дерево виджетов
/// через [ValueKey], что обновляет состояние всех экранов после импорта БД.
final ValueNotifier<int> appRestartTick = ValueNotifier<int>(0);

/// Перезапускает приложение: перемонтирует [MaterialApp] с новым ключом.
void restartApp() {
  appRestartTick.value++;
}
