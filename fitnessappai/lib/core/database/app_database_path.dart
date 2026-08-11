import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Путь к файлу локальной БД в documents-каталоге.
///
/// Совпадает с расположением, которое использует `driftDatabase(name:)`
/// в [AppDatabase]: `getApplicationDocumentsDirectory()/fitnessappai.sqlite`.
Future<String> appDatabasePath() async {
  final docs = await getApplicationDocumentsDirectory();
  return p.join(docs.path, 'fitnessappai.sqlite');
}
