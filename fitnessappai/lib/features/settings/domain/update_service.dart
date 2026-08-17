/// Информация о последнем релизе приложения из GitHub.
class ReleaseInfo {
  const ReleaseInfo({required this.tagName, this.htmlUrl, this.apkUrl});

  /// Тег релиза, например `v1.1.0`.
  final String tagName;

  /// Страница релиза на GitHub.
  final String? htmlUrl;

  /// Прямая ссылка на APK последнего релиза.
  final String? apkUrl;
}

/// Получает информацию о последнем опубликованном релизе приложения.
abstract class UpdateService {
  /// Возвращает последний релиз или `null`, если релизов ещё нет.
  Future<ReleaseInfo?> fetchLatestRelease();
}
