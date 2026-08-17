import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fitnessappai/features/settings/domain/update_service.dart';

/// Получает последний релиз из GitHub API по тегу.
///
/// По умолчанию репозиторий `garryk3/fitnessappai`; APK публикуется workflow
/// `release.yml` как артефакт последнего релиза.
class GithubUpdateService implements UpdateService {
  GithubUpdateService({
    String? baseUrl,
    String? apkUrl,
    HttpClient? httpClient,
  }) : _baseUrl = baseUrl ?? defaultBaseUrl,
       _apkUrl = apkUrl ?? defaultApkUrl,
       _httpClient = httpClient ?? HttpClient();

  static const String defaultBaseUrl =
      'https://api.github.com/repos/garryk3/fitnessappai';
  static const String defaultApkUrl =
      'https://github.com/garryk3/fitnessappai/releases/latest/download/app-release.apk';

  final String _baseUrl;
  final String _apkUrl;
  final HttpClient _httpClient;

  @override
  Future<ReleaseInfo?> fetchLatestRelease() async {
    final request = await _httpClient
        .getUrl(Uri.parse('$_baseUrl/releases/latest'))
        .timeout(const Duration(seconds: 10));
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    final response = await request.close().timeout(const Duration(seconds: 10));
    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub API ответил статусом ${response.statusCode}');
    }
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final tagName = decoded['tag_name'];
    if (tagName is! String || tagName.isEmpty) {
      return null;
    }
    final htmlUrl = decoded['html_url'];
    return ReleaseInfo(
      tagName: tagName,
      htmlUrl: htmlUrl is String ? htmlUrl : null,
      apkUrl: _apkUrl,
    );
  }
}
