import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fitnessappai/features/settings/data/github_update_service.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';

typedef VersionLoader = Future<String> Function();
typedef ReleaseOpener = Future<void> Function(String url);

/// Управляет проверкой обновлений: текущая версия, последний релиз из GitHub
/// и открытие ссылки на скачивание новой версии.
class UpdateCheckController {
  UpdateCheckController({
    UpdateService? service,
    VersionLoader? loadVersion,
    ReleaseOpener? openRelease,
  }) : _service = service ?? GithubUpdateService(),
       _loadVersion = loadVersion ?? _defaultLoadVersion,
       _openRelease = openRelease ?? _defaultOpenRelease;

  final UpdateService _service;
  final VersionLoader _loadVersion;
  final ReleaseOpener _openRelease;

  ReleaseInfo? _latestRelease;

  /// Текущая версия приложения, например `1.0.0`.
  final Signal<String?> versionText = Signal(null);

  /// Доступная версия из последнего релиза (без префикса `v`).
  final Signal<String?> latestVersion = Signal(null);
  final Signal<bool> isChecking = Signal(false);
  final Signal<String?> statusText = Signal(null);
  final Signal<bool> hasError = Signal(false);
  final Signal<bool> hasUpdate = Signal(false);

  /// Загружает версию приложения для показа в настройках.
  Future<void> loadVersion() async {
    try {
      versionText.value = await _loadVersion();
    } catch (_) {
      versionText.value = null;
    }
  }

  /// Проверяет наличие более новой версии на GitHub.
  Future<void> checkForUpdates() async {
    if (isChecking.value) {
      return;
    }
    isChecking.value = true;
    statusText.value = null;
    hasError.value = false;
    hasUpdate.value = false;
    latestVersion.value = null;
    try {
      final release = await _service.fetchLatestRelease();
      if (release == null) {
        statusText.value = 'Релизы ещё не опубликованы';
        hasError.value = true;
        return;
      }
      _latestRelease = release;
      final current = versionText.value ?? await _loadVersion();
      if (_isNewer(release.tagName, current)) {
        hasUpdate.value = true;
        latestVersion.value = _cleanTag(release.tagName);
        statusText.value = 'Доступна новая версия ${latestVersion.value}';
      } else {
        statusText.value = 'Установлена актуальная версия';
      }
    } catch (error) {
      statusText.value = 'Ошибка проверки обновления: $error';
      hasError.value = true;
    } finally {
      isChecking.value = false;
    }
  }

  /// Открывает ссылку на скачивание последнего релиза в браузере.
  Future<void> openUpdate() async {
    final release = _latestRelease;
    if (release == null) {
      return;
    }
    final url = release.apkUrl ?? release.htmlUrl;
    if (url == null || url.isEmpty) {
      return;
    }
    await _openRelease(url);
  }

  static Future<String> _defaultLoadVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<void> _defaultOpenRelease(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Сравнивает семантические версии без префикса `v`: `latest` новее `current`.
  static bool _isNewer(String latestTag, String current) {
    final latest = _parseVersion(latestTag);
    final installed = _parseVersion(current);
    if (latest == null || installed == null) {
      return false;
    }
    for (var i = 0; i < latest.length; i++) {
      if (latest[i] != installed[i]) {
        return latest[i] > installed[i];
      }
    }
    return false;
  }

  static List<int>? _parseVersion(String version) {
    final clean = version
        .trim()
        .replaceFirst(RegExp(r'^[vV]'), '')
        .replaceFirst(RegExp(r'-.*'), '');
    final parts = clean.split('.');
    if (parts.length > 3) {
      return null;
    }
    final result = <int>[];
    for (final part in parts) {
      final number = int.tryParse(part);
      if (number == null) {
        return null;
      }
      result.add(number);
    }
    while (result.length < 3) {
      result.add(0);
    }
    return result;
  }

  static String _cleanTag(String tag) =>
      tag.replaceFirst(RegExp(r'^[vV]'), '').replaceFirst(RegExp(r'-.*'), '');
}
