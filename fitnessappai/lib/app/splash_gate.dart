import 'package:material_ui/material_ui.dart';

import 'package:fitnessappai/app/bootstrap.dart';
import 'package:fitnessappai/app/localization_delegates.dart';
import 'package:fitnessappai/app/splash_video.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/settings/data/apk_downloader.dart';
import 'package:fitnessappai/features/settings/data/apk_installer.dart';
import 'package:fitnessappai/features/settings/data/auto_update_repository.dart';
import 'package:fitnessappai/features/settings/domain/auto_update_controller.dart';
import 'package:fitnessappai/features/settings/domain/update_service.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/main.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Исход операции «скачать + установить» (fix task-reviewer): отказ
/// установщика — с диалогом-сообщением, ошибка сети/записи — молча
/// (решение владельца 64.1).
enum _InstallOutcome { done, installerRefused, silentFailure }

/// Стартовый экран: показывает видео-заставку, пока идёт инициализация,
/// затем плавно переходит в [FitnessAppAi].
///
/// [bootstrap], [homeBuilder] и [splashBody] инъектируемы для тестов.
/// [autoUpdateController] — проверка новой версии на входе (64.1);
/// `null` (тесты) — проверка не выполняется.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    this.bootstrap,
    this.homeBuilder,
    this.splashBody = const SplashVideo(),
    this.autoUpdateController,
    this.apkDownloader,
    this.apkInstaller,
  });

  /// Инициализация перед показом приложения. По умолчанию — [bootstrap].
  final Future<void> Function()? bootstrap;

  /// Строит основное приложение после заставки.
  final Widget Function()? homeBuilder;

  /// Содержимое заставки. По умолчанию — полноэкранное видео.
  final Widget splashBody;

  /// Контроллер автообновления (64.1): при включённом флаге на заставке
  /// проверяется новая версия и, если есть, показывается модалка
  /// «Доступна новая версия» с кнопкой «Загрузить»; после показа флаг
  /// сбрасывается. `null` (тесты) — проверка не выполняется.
  final AutoUpdateController? autoUpdateController;

  /// Загрузчик APK (64.1); `null` — реальный `HttpApkDownloader`.
  final ApkDownloader? apkDownloader;

  /// Установщик APK (64.1); `null` — реальный платформенный установщик.
  final ApkInstaller? apkInstaller;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _ready = false;

  /// Контекст навигатора заставки: модалка обновления (64.1) показывается
  /// поверх inner-MaterialApp, у state.context навигатора нет.
  final GlobalKey<NavigatorState> _splashNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Загрузчик APK (64.1); инъекция для тестов.
  ApkDownloader get _apkDownloader =>
      widget.apkDownloader ?? const HttpApkDownloader();

  /// Установщик APK (64.1); инъекция для тестов.
  ApkInstaller get _apkInstaller =>
      widget.apkInstaller ?? const MethodChannelApkInstaller();

  /// Контроллер автообновления в проде: собирается лениво из locator после
  /// bootstrap (репозитории появляются только после него); в тестах
  /// передаётся конструктором, либо отсутствует — проверки нет.
  AutoUpdateController? _lazyAutoUpdate;

  AutoUpdateController? get _autoUpdate {
    if (widget.autoUpdateController != null) {
      return widget.autoUpdateController;
    }
    if (_lazyAutoUpdate != null) {
      return _lazyAutoUpdate;
    }
    try {
      _lazyAutoUpdate = AutoUpdateController(
        repository: locator.get<AutoUpdateRepository>(),
        service: locator.get<UpdateService>(),
      );
    } catch (_) {
      // Репозитории не зарегистрированы (тесты) — проверка не выполняется.
      return null;
    }
    return _lazyAutoUpdate;
  }

  /// Минимальное время показа заставки до начала исчезновения.
  static const Duration _minVisible = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    final started = DateTime.now();
    await (widget.bootstrap ?? bootstrap)();
    final elapsed = DateTime.now().difference(started);
    final remaining = _minVisible - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    // 64.1: пока флаг «автообновление» включён, на заставке проверяется
    // новая версия; при наличии — модалка. Любой исход (загрузить/позже)
    // сбрасывает флаг — проверка не повторяется на следующих запусках.
    final autoUpdate = _autoUpdate;
    await autoUpdate?.load();
    if (!mounted) {
      return;
    }
    final check = await autoUpdate?.runCheck();
    if (!mounted) {
      return;
    }
    if (check != null) {
      await _showUpdateDialog(check);
      await autoUpdate?.consume();
    }
    if (!mounted) {
      return;
    }
    await _controller.reverse();
    if (!mounted) {
      return;
    }
    setState(() => _ready = true);
  }

  /// Модалка «Доступна новая версия» (64.1): кнопка «Загрузить» скачивает
  /// APK и запускает установку; «Позже» закрывает. Диалог не даёт
  /// продолжить в приложение, пока пользователь не выберет.
  Future<void> _showUpdateDialog(AutoUpdateCheck check) async {
    final navigatorContext = _splashNavigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }
    final l10n = AppLocalizations.of(navigatorContext);
    final open = await showAppDialog<bool>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: AppText(l10n.settingsUpdateAvailable),
        content: AppText(l10n.settingsUpdateContent(check.version)),
        actions: [
          AppTextButton(
            label: l10n.settingsUpdateLater,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: l10n.settingsUpdateDownload,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (open != true || !mounted) {
      return;
    }
    await _downloadAndInstall(check);
  }

  Future<void> _downloadAndInstall(AutoUpdateCheck check) async {
    final url = check.release.apkUrl;
    if (url == null || url.isEmpty) {
      // Релиз без APK-ассета: тихий пропуск (fix task-reviewer — раньше
      // fallback скачивал HTML-страницу релиза как update.apk).
      return;
    }
    final rootContext = _splashNavigatorKey.currentContext;
    if (rootContext == null) {
      return;
    }
    final l10n = AppLocalizations.of(rootContext);
    // Операция «скачать + установить»: FutureBuilder в диалоге закрывает
    // его сам по завершении (post-frame callback после кадра результата) —
    // не завися от того, успел ли билдер к моменту пумпа.
    final operation = _runDownloadAndInstall(url);
    await showAppDialog<void>(
      context: rootContext,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<_InstallOutcome>(
        future: operation,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
          return AppDialog(
            content: Row(
              children: [
                const AppSpinner(),
                const SizedBox(width: 12),
                Expanded(child: AppText(l10n.settingsUpdateDownloading)),
              ],
            ),
          );
        },
      ),
    );
    // Диалог закрыт — операция завершена (тот же Future замемоизирован).
    final outcome = await operation;
    if (outcome != _InstallOutcome.installerRefused || !rootContext.mounted) {
      return;
    }
    // Отказ системного установщика — блокирующий диалог (не снекбар:
    // сплэш исчезает через ~0.9 с, снекбар был бы нечитаем).
    await showAppDialog<void>(
      context: rootContext,
      builder: (context) => AppDialog(
        title: AppText(l10n.settingsUpdateInstallFailed),
        actions: [
          AppTextButton(
            label: l10n.commonOk,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Скачивает APK и запускает установку.
  ///
  /// Ошибка сети/записи — [SILENT] (молчаливый пропуск по решению
  /// владельца 64.1); отказ системного установщика — [installerRefused]
  /// (диалог с сообщением).
  Future<_InstallOutcome> _runDownloadAndInstall(String url) async {
    try {
      final apkPath = await _apkDownloader.download(Uri.parse(url));
      final started = await _apkInstaller.install(apkPath);
      return started ? _InstallOutcome.done : _InstallOutcome.installerRefused;
    } catch (_) {
      // Ошибка сети/записи: молчаливый пропуск; пользователь может
      // скачать APK вручную со страницы релиза.
      return _InstallOutcome.silentFailure;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return (widget.homeBuilder ?? () => const FitnessAppAi())();
    }
    return MaterialApp(
      // navigatorKey: контекст навигатора нужен модалке обновления (64.1) —
      // у state.context над этим MaterialApp навигатора нет.
      navigatorKey: _splashNavigatorKey,
      theme: AppTheme.dark(),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: AppScaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: FadeTransition(opacity: _fade, child: widget.splashBody),
      ),
    );
  }
}
