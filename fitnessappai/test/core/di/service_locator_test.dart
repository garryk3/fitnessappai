import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/di/service_locator.dart';

void main() {
  group('ServiceLocator', () {
    late ServiceLocator sl;

    setUp(() {
      sl = ServiceLocator();
    });

    test('registerFactory создаёт новый экземпляр на каждый get', () {
      sl.registerFactory<Foo>(() => Foo());

      expect(sl.get<Foo>(), isNot(same(sl.get<Foo>())));
    });

    test('registerLazySingleton возвращает один и тот же экземпляр', () {
      sl.registerLazySingleton<Foo>(() => Foo());

      expect(sl.get<Foo>(), same(sl.get<Foo>()));
    });

    test('registerInstance возвращает переданный экземпляр', () {
      final Foo foo = Foo();
      sl.registerInstance<Foo>(foo);

      expect(sl.get<Foo>(), same(foo));
    });

    test('get бросает StateError для незарегистрированного типа', () {
      expect(() => sl.get<Foo>(), throwsStateError);
    });

    test('reset очищает регистрации и созданные синглтоны', () {
      sl.registerLazySingleton<Foo>(() => Foo());
      final Foo first = sl.get<Foo>();

      sl.reset();
      expect(() => sl.get<Foo>(), throwsStateError);

      sl.registerLazySingleton<Foo>(() => Foo());
      expect(sl.get<Foo>(), isNot(same(first)));
    });
  });
}

class Foo {
  Foo();
}
