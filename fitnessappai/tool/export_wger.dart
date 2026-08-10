import 'dart:convert';
import 'dart:io';

/// Экспорт упражнений из wger API в скелет seed JSON.
///
/// Запуск: `dart run tool/export_wger.dart [--limit 100]`
///
/// Выводит массив записей в формате, близком к `assets/data/exercises_seed.json`
/// (название, английские инструкции, мышцы). Русский текст, подсказки,
/// противопоказания и анимации добавляются вручную.
Future<void> main(List<String> args) async {
  var limit = 100;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--limit' && i + 1 < args.length) {
      limit = int.tryParse(args[i + 1]) ?? limit;
    }
  }

  final client = HttpClient();
  try {
    final muscles = await _fetchJson(client, 'https://wger.de/api/v2/muscle/');
    final muscleNames = <int, String>{};
    for (final muscle in _asList(muscles['results'])) {
      final id = muscle['id'];
      if (id is int) {
        muscleNames[id] = _asString(muscle['name']);
      }
    }

    final data = await _fetchJson(
      client,
      'https://wger.de/api/v2/exerciseinfo/?limit=$limit',
    );
    final records = <Map<String, Object?>>[];
    for (final exercise in _asList(data['results'])) {
      final name = _asString(exercise['name']);
      if (name.isEmpty) {
        continue;
      }
      final primary = _muscleKeys(exercise['muscles'], muscleNames);
      final secondary = _muscleKeys(exercise['muscles_secondary'], muscleNames);
      records.add({
        'name': name,
        'type': 'strength',
        'description': '',
        'instructions': _stripHtml(_asString(exercise['description'])),
        'commonMistakes': const <String>[],
        'animation': '',
        'muscles': [
          for (final key in primary) {'key': key, 'intensity': 'primary'},
          for (final key in secondary) {'key': key, 'intensity': 'secondary'},
        ],
        'contraindications': const <String>[],
      });
    }
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(records));
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _fetchJson(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

List<dynamic> _asList(Object? value) => value is List ? value : const [];

String _asString(Object? value) => value is String ? value : '';

/// Маппинг названий мышц wger на ключи справочника приложения.
const Map<String, String> _muscleKeyByWgerName = <String, String>{
  'Biceps brachii': 'biceps',
  'Triceps brachii': 'triceps',
  'Pectoralis major': 'chest',
  'Anterior deltoid': 'shoulders',
  'Lateral deltoid': 'shoulders',
  'Posterior deltoid': 'shoulders',
  'Latissimus dorsi': 'lats',
  'Trapezius': 'traps',
  'Rectus abdominis': 'abs',
  'Obliquus externus abdominis': 'obliques',
  'Gluteus maximus': 'glutes',
  'Quadriceps femoris': 'quads',
  'Hamstrings': 'hamstrings',
  'Gastrocnemius': 'calves',
  'Erector spinae': 'lower_back',
  'Neck': 'neck',
};

List<String> _muscleKeys(Object? ids, Map<int, String> muscleNames) {
  final result = <String>[];
  if (ids is! List) {
    return result;
  }
  for (final id in ids) {
    if (id is! int) {
      continue;
    }
    final key = _muscleKeyByWgerName[muscleNames[id]];
    if (key != null && !result.contains(key)) {
      result.add(key);
    }
  }
  return result;
}

final RegExp _htmlTags = RegExp(r'<[^>]+>');

String _stripHtml(String value) =>
    value.replaceAll(_htmlTags, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
