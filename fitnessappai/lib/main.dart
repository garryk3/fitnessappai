import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/app_restart.dart';
import 'package:fitnessappai/app/router.dart';
import 'package:fitnessappai/app/splash_gate.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/notifications/notification_log.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashGate());
}

class FitnessAppAi extends StatefulWidget {
  const FitnessAppAi({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<FitnessAppAi> createState() => _FitnessAppAiState();
}

class _FitnessAppAiState extends State<FitnessAppAi>
    with WidgetsBindingObserver {
  /// Роутер создаётся один раз и живёт в состоянии: пересоздание при смене
  /// темы сбросило бы навигацию на главный экран.
  late GoRouter _router = AppRouter.create();

  ReminderService? _reminders;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appRestartTick.addListener(_handleRestart);
    _reminders = _resolveReminders();
    _reminders?.onReminderTapped = _openReminderDay;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRestartTick.removeListener(_handleRestart);
    _reminders?.onReminderTapped = null;
    super.dispose();
  }

  /// Напоминания регистрируются не во всех окружениях (например, в
  /// виджет-тестах контейнер может быть пустым), поэтому подключаем их
  /// только когда сервис действительно есть.
  ReminderService? _resolveReminders() {
    try {
      return locator.get<ReminderService>();
    } on StateError {
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    // Пока приложение было в фоне, пользователь мог отозвать точные
    // будильники или сменить часовой пояс — пересчитываем расписание, иначе
    // уведомления продолжат приходить по старым правилам.
    unawaited(_rescheduleReminders());
  }

  Future<void> _rescheduleReminders() async {
    try {
      await _reminders?.rescheduleAll();
    } catch (e, st) {
      logNotificationIssue(
        'Напоминания не перепланированы при возврате в приложение',
        error: e,
        stackTrace: st,
        name: 'main',
      );
    }
  }

  /// Открывает день тренировки, на который пришло нажатие уведомления.
  Future<void> _openReminderDay(int programDayId) async {
    final ReminderTarget? target;
    try {
      target = await locator.get<WorkoutReminderRepository>().targetForDay(
        programDayId,
      );
    } catch (e, st) {
      logNotificationIssue(
        'Не удалось найти день $programDayId для перехода из уведомления',
        error: e,
        stackTrace: st,
        name: 'main',
      );
      return;
    }
    if (!mounted) {
      return;
    }
    final context = AppRouter.navigatorKey.currentContext;
    if (target == null || context == null || !context.mounted) {
      logNotificationIssue(
        'Переход из уведомления не выполнен: '
        'день=$programDayId, найден=$target, навигатор=${context != null}',
        name: 'main',
      );
      return;
    }
    context.go('/programs/${target.programId}/day/${target.dayIndex}');
  }

  /// Полный перезапуск после импорта БД: новый роутер + новый ключ,
  /// чтобы дерево виджетов перемонтировалось с нуля.
  void _handleRestart() {
    // Импорт БД пересоздаёт контейнер, поэтому прежний ReminderService
    // смотрит в уже закрытую базу. Переподключаемся к новому экземпляру,
    // иначе перепланирование по lifecycle и тап по уведомлению работали бы
    // со старыми данными.
    _reminders?.onReminderTapped = null;
    _reminders = _resolveReminders();
    _reminders?.onReminderTapped = _openReminderDay;
    setState(() {
      _router = AppRouter.create();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController =
        widget.themeController ?? locator.get<ThemeController>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) => MaterialApp.router(
        key: ValueKey<int>(appRestartTick.value),
        title: 'Личный тренер',
        themeMode: mode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        routerConfig: _router,
      ),
    );
  }
}
