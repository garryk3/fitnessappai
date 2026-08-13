import 'dart:async';

import 'package:flutter/foundation.dart';

/// Оповещает об изменении данных в БД.
///
/// Репозитории вызывают [notifyChanged] после успешной записи, а контроллеры
/// списков/деталей подписываются и перезагружают данные. Это закрывает
/// проблему устаревших списков, т.к. экраны живут в `indexedStack` и их
/// `State` переживает навигацию.
class DataChangeNotifier extends ChangeNotifier {
  void notifyChanged() => notifyListeners();
}

/// Глобальный источник событий изменения данных.
///
/// Используется по умолчанию репозиториями и контроллерами; в тестах можно
/// передать собственный экземпляр для изоляции.
final DataChangeNotifier appDataChanges = DataChangeNotifier();

/// Подписка на [DataChangeNotifier] с перезагрузкой данных.
///
/// Несколько синхронных событий объединяются в одну перезагрузку через
/// микротаск — репозиторий, изменивший несколько таблиц, уведомляет один раз
/// за кадр.
class ChangeReloadSubscription {
  ChangeReloadSubscription({required this._changes, required this._reload}) {
    _changes?.addListener(_onChanged);
  }

  final DataChangeNotifier? _changes;
  final Future<void> Function() _reload;
  bool _scheduled = false;

  void _onChanged() {
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      _reload();
    });
  }

  void dispose() {
    _changes?.removeListener(_onChanged);
  }
}
