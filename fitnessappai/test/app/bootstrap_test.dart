import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/bootstrap.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/seed/exercise_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late ServiceLocator container;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('bootstrap_test');
    container = ServiceLocator();
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  MediaStore mediaStore() => MediaStore(
    directoryProvider: () async => tempDir,
    assetLoader: (assetPath) async =>
        Uint8List.fromList(utf8.encode('webp:$assetPath')),
    filePicker: (fileType) async => null,
  );

  Future<String> seedJson() =>
      File(ExerciseSeeder.seedAssetPath).readAsString();

  Future<int> exercisesCount() =>
      db.select(db.exercises).get().then((rows) => rows.length);

  test('bootstrap заливает 16 упражнений и ставит флаг в app_meta', () async {
    await bootstrap(
      container: container,
      database: db,
      mediaStore: mediaStore(),
      seedJsonLoader: seedJson,
    );

    expect(await exercisesCount(), 16);
    final flag =
        await (db.select(db.appMeta)
              ..where((t) => t.key.equals(ExerciseSeeder.seededFlagKey)))
            .getSingleOrNull();
    expect(flag, isNotNull);
  });

  test('повторный bootstrap не дублирует упражнения', () async {
    await bootstrap(
      container: container,
      database: db,
      mediaStore: mediaStore(),
      seedJsonLoader: seedJson,
    );
    final count = await exercisesCount();

    await bootstrap(
      container: container,
      database: db,
      mediaStore: mediaStore(),
      seedJsonLoader: seedJson,
    );

    expect(await exercisesCount(), count);
  });
}
