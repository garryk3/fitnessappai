import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/features/settings/data/auto_update_repository.dart';
import 'package:fitnessappai/features/settings/domain/update_check_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';

typedef VersionLoader = Future<String> Function();

/// Результат проверки автообновления на старте (64.1): доступна новая
/// версия с номером и ссылками на релиз.
class AutoUpdateCheck {
  const AutoUpdateCheck({required this.version, required this.release});

  /// Номер версии без префикса `v`, например `1.1.0`.
  final String version;
  final ReleaseInfo release;
}

/// Управляет флагом «автообновление» и проверкой новой версии на входе
/// в приложение (64.1).
///
/// Логика одноразовая: пока флаг включён, на сплэше делается запрос
/// релиза; при наличии новой версии возвращается [AutoUpdateCheck] для
/// модалки, а после показа модалки флаг сбрасывается в `false`
/// (решение владельца — проверка не повторяется на следующих запусках).
/// Любая ошибка (сеть, разбор ответа) глушится: проверка молча
/// пропускается (решение владельца 2026-11-17).
class AutoUpdateController {
  AutoUpdateController({
    required this.repository,
    required this.service,
    VersionLoader? loadVersion,
  }) : _loadVersion = loadVersion ?? _defaultLoadVersion;

  final AutoUpdateRepository repository;
  final UpdateService service;
  final VersionLoader _loadVersion;

  /// Состояние флага для переключателя в настройках.
  final Signal<bool> autoUpdateEnabled = Signal(false);

  /// Загружает флаг (вызывается при открытии настроек и в bootstrap).
  Future<void> load() async {
    autoUpdateEnabled.value = await repository.read();
  }

  Future<void> setEnabled(bool value) async {
    autoUpdateEnabled.value = value;
    await repository.write(value);
  }

  /// Сбрасывает флаг после показа модалки обновления на сплэше (64.1).
  Future<void> consume() => setEnabled(false);

  /// Проверяет наличие новой версии. Возвращает [AutoUpdateCheck], если
  /// флаг включён и релиз новее установленной версии; иначе `null` —
  /// включая все ошибки (молчаливый пропуск, решение владельца).
  Future<AutoUpdateCheck?> runCheck() async {
    if (!autoUpdateEnabled.value) {
      return null;
    }
    try {
      final release = await service.fetchLatestRelease();
      if (release == null) {
        return null;
      }
      final current = await _loadVersion();
      if (!UpdateCheckController.isNewer(release.tagName, current)) {
        return null;
      }
      return AutoUpdateCheck(
        version: _cleanTag(release.tagName),
        release: release,
      );
    } catch (_) {
      return null;
    }
  }

  static String _cleanTag(String tag) =>
      tag.startsWith('v') ? tag.substring(1) : tag;

  static Future<String> _defaultLoadVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
