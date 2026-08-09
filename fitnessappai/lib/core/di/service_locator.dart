typedef ServiceFactory<T> = T Function();

/// Простой контейнер внедрения зависимостей.
///
/// Регистрация фабрик ([registerFactory]), ленивых синглтонов
/// ([registerLazySingleton]) и готовых экземпляров ([registerInstance]).
/// [reset] очищает все регистрации и созданные синглтоны.
class ServiceLocator {
  final Map<Type, _Registration<Object?>> _registrations = {};
  final Map<Type, Object?> _singletons = {};

  void registerFactory<T>(ServiceFactory<T> factory) {
    _registrations[T] = _FactoryRegistration<T>(factory);
    _singletons.remove(T);
  }

  void registerLazySingleton<T>(ServiceFactory<T> factory) {
    _registrations[T] = _LazySingletonRegistration<T>(factory);
  }

  void registerInstance<T>(T instance) {
    _registrations[T] = _InstanceRegistration<T>(instance);
    _singletons[T] = instance;
  }

  T get<T>() {
    final registration = _registrations[T];
    if (registration == null) {
      throw StateError('Service of type $T is not registered');
    }
    return registration.resolve(this) as T;
  }

  void reset() {
    _registrations.clear();
    _singletons.clear();
  }
}

sealed class _Registration<T> {
  T resolve(ServiceLocator locator);
}

final class _FactoryRegistration<T> extends _Registration<T> {
  _FactoryRegistration(this._factory);

  final ServiceFactory<T> _factory;

  @override
  T resolve(ServiceLocator locator) => _factory();
}

final class _LazySingletonRegistration<T> extends _Registration<T> {
  _LazySingletonRegistration(this._factory);

  final ServiceFactory<T> _factory;

  @override
  T resolve(ServiceLocator locator) {
    return locator._singletons.putIfAbsent(T, _factory) as T;
  }
}

final class _InstanceRegistration<T> extends _Registration<T> {
  _InstanceRegistration(this.instance);

  final T instance;

  @override
  T resolve(ServiceLocator locator) => instance;
}

/// Глобальный экземпляр [ServiceLocator] приложения.
final ServiceLocator locator = ServiceLocator();
