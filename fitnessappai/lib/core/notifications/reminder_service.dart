import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fitnessappai/app/sound/sound_settings_store.dart';
import 'package:fitnessappai/core/domain/models/workout_reminder.dart';
import 'package:fitnessappai/core/notifications/notification_log.dart';
import 'package:fitnessappai/core/notifications/reminder_catch_up_log.dart';
import 'package:fitnessappai/core/notifications/reminder_delivered_log.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/domain/plan_schedule_item.dart';

/// Статус разрешений на уведомления.
class NotificationPermissionStatus {
  const NotificationPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
}

/// Флаг процесса: launch details холодного старта уже прочитаны.
///
/// На Android плагин выводит ответ из launch Intent главной активности
/// (`mainActivity.getIntent()`): Intent не очищается и не меняется, пока
/// жива активность, поэтому `getNotificationAppLaunchDetails()` вернул бы
/// тот же payload при любом повторном вызове. Он описывает запуск
/// **активности**, а не конкретного экземпляра сервиса, и потому читается
/// ровно один раз: иначе пересоздание `ReminderService` (например, импорт
/// БД) доставило бы payload повторно и продублировало переход на уже
/// открытый день.
bool _launchDetailsRead = false;

/// Сбрасывает [_launchDetailsRead] для тестов.
///
/// Каждый тест имитирует новый запуск процесса, поэтому без сброса сценарии
/// начнут зависеть от порядка выполнения.
@visibleForTesting
void resetLaunchDetailsForTests() => _launchDetailsRead = false;

/// Управление еженедельными уведомлениями о тренировочных днях.
///
/// Планирование через [FlutterLocalNotificationsPlugin] с повторением
/// `dayOfWeekAndTime`. Идентификатор еженедельного уведомления совпадает с
/// [WorkoutReminder.programDayId], поэтому отмена и перепланирование
/// выполняются по id дня.
///
/// Ручное назначение из плана (48.10) живёт в отдельной таблице и получает
/// **одноразовое** уведомление в диапазоне id [manualReminderIdBase] —
/// оно не повторяется по дню недели и не участвует в догоне
/// ([catchUpMissed]): единственный его источник — прямой вызов
/// [scheduleManualReminder], поэтому второй показ исключён самим фактом
/// планирования.
class ReminderService {
  ReminderService({
    required this._repository,
    FlutterLocalNotificationsPlugin? plugin,
    SoundSettingsStore? soundSettings,
    ReminderCatchUpLog? catchUpLog,
    ReminderDeliveredLog? deliveredLog,
    PlanScheduleRepository? planSchedule,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _soundSettings = soundSettings,
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _catchUpLog = catchUpLog,
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _deliveredLog = deliveredLog,
       // ignore: prefer_initializing_formals -- имя параметра публичное.
       _planSchedule = planSchedule;

  final WorkoutReminderRepository _repository;
  final FlutterLocalNotificationsPlugin _plugin;

  /// Ручные назначения с временем (48.10) — источник одноразовых
  /// напоминаний; `null` — только еженедельные (тесты, окружения без
  /// зарегистрированного репозитория).
  final PlanScheduleRepository? _planSchedule;

  /// Настройки звука напоминаний; null — звук остаётся стандартным (тесты,
  /// окружения без зарегистрированного хранилища).
  final SoundSettingsStore? _soundSettings;

  /// Журнал показа «догоняющих» уведомлений; null — без защиты от повторов
  /// (тесты, окружения без зарегистрированного хранилища).
  final ReminderCatchUpLog? _catchUpLog;

  /// Журнал системной доставки напоминаний (48.8); null — без отметок о
  /// тапе по уведомлению (тесты, окружения без зарегистрированного
  /// хранилища).
  final ReminderDeliveredLog? _deliveredLog;

  /// Незавершённые отметки системной доставки (48.8).
  ///
  /// Тап по уведомлению в фоне пишет отметку асинхронно, а вместе с тапом
  /// приходит возврат из фона — и догон успевает стартовать раньше записи.
  /// [catchUpMissed] ждёт эту цепочку, чтобы не принять свежий тап за
  /// «система не доставила».
  Future<void> _deliveryMarks = Future<void>.value();

  /// Текущий прогон [catchUpMissed] (48.8): параллельные вызовы из
  /// инициализации и обработчика lifecycle схлопываются в один, вместо двух
  /// показов одного уведомления.
  Future<void>? _catchUpRunning;

  /// Код ошибки плагина, когда точный режим недоступен: разрешение могли
  /// отозвать между проверкой и планированием, и `zonedSchedule` падает
  /// целиком — день остался бы без напоминания.
  static const String _exactAlarmsNotPermitted = 'exact_alarms_not_permitted';

  /// Насколько поздно должно пройти время напоминания, чтобы догон показал
  /// его при возврате в приложение.
  ///
  /// Порог покрывает типичную задержку inexact-будильника с окном (замерено
  /// на эмуляторе: 1–2 минуты) и не превращает обычное напоминание в
  /// «пропущенное». Задержки Doze и агрессивных прошивок (Xiaomi) — от 15
  /// минут до часа, их как раз и ловит догон.
  static const Duration catchUpGrace = Duration(minutes: 15);

  /// Кэш последней применённой звуковой настройки: [initialize] и
  /// [applySoundSettings] должны одинаково понимать, какой звук у канала.
  bool _soundEnabled = true;
  String? _soundFilePath;

  /// Прочитает ли [_soundFilePath] системный процесс, играющий звук канала
  /// (48.1). Пока неизвестно — считаем, что прочитает.
  bool _soundFileSystemReadable = true;

  static const String _channelId = 'workout_reminders';
  static const String _channelName = 'Напоминания о тренировках';
  static const String _channelDescription =
      'Еженедельные напоминания о тренировочных днях';
  static const String _iconName = 'ic_stat_launcher';
  static const String _soundName = 'notification';

  bool _initialized = false;

  /// Инициализация в процессе: параллельные вызовы [initialize] ждут её,
  /// а не запускают вторую (см. [initialize]).
  Future<void>? _initializing;

  void Function(int programDayId)? _onReminderTapped;
  int? _pendingProgramDayId;

  /// Обработчик тапа по уведомлению; получает `programDayId` из payload.
  ///
  /// Задаётся слоем приложения, у которого есть роутер: [ReminderService]
  /// создаётся в контейнере до появления UI.
  void Function(int programDayId)? get onReminderTapped => _onReminderTapped;

  set onReminderTapped(void Function(int programDayId)? handler) {
    _onReminderTapped = handler;
    final pending = _pendingProgramDayId;
    if (handler != null && pending != null) {
      _pendingProgramDayId = null;
      handler(pending);
    }
  }

  /// Статус разрешений на уведомления.
  Future<NotificationPermissionStatus> checkPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      // На не-Android платформах локальных уведомлений нет вовсе, поэтому
      // оба флага всегда «не выдано». Прежде здесь возвращалось true/true,
      // а позже — notificationsEnabled вычислялся из наличия
      // запланированных напоминаний, что смешивало статус разрешения с
      // состоянием расписания и снова показывало ложное «выдано».
      return const NotificationPermissionStatus(
        notificationsEnabled: false,
        exactAlarmsEnabled: false,
      );
    }
    final notificationsEnabled =
        await android.areNotificationsEnabled() ?? false;
    final exactAlarmsEnabled =
        await android.canScheduleExactNotifications() ?? false;
    return NotificationPermissionStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsEnabled: exactAlarmsEnabled,
    );
  }

  /// Запрашивает только разрешение на уведомления и возвращает свежий статус.
  ///
  /// Системный диалог Android 13+ показывается лишь один раз; если после
  /// запроса уведомления всё ещё отключены, открывает системные настройки
  /// уведомлений приложения. При выдаче разрешения перепланирует сохранённые
  /// напоминания (они не планировались, пока уведомления были отключены);
  /// показ того, что выпало за это время, — задача догоняющего
  /// [catchUpMissed], который выполняется при старте и возврате в приложение.
  Future<NotificationPermissionStatus> requestNotificationsPermission() async {
    await _requestNotifications();
    final status = await checkPermissions();
    if (status.notificationsEnabled) {
      await rescheduleAll();
    }
    return status;
  }

  /// Запрашивает только разрешение на точные будильники и возвращает свежий
  /// статус.
  ///
  /// На Android 12+ открывает системный экран «Будильники и напоминания».
  /// При выдаче разрешения перепланирует напоминания в точном режиме.
  Future<NotificationPermissionStatus> requestExactAlarmsPermission() async {
    await _requestExactAlarms();
    final status = await checkPermissions();
    if (status.exactAlarmsEnabled) {
      await rescheduleAll();
    }
    return status;
  }

  Future<void> _requestNotifications() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }
    await android.requestNotificationsPermission();
    final enabled = await android.areNotificationsEnabled() ?? false;
    if (!enabled) {
      await android.openAppNotificationSettings();
    }
  }

  Future<void> _requestExactAlarms() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }
    final canExact = await android.canScheduleExactNotifications() ?? false;
    if (canExact) {
      return;
    }
    await android.requestExactAlarmsPermission();
  }

  /// Инициализирует часовой пояс, плагин и канал уведомлений.
  ///
  /// Разрешения (уведомления, точные будильники) при старте не запрашивает —
  /// это делается явно из экрана «Настройки», чтобы не открывать системные
  /// диалоги/экраны помимо воли пользователя.
  Future<void> initialize() {
    final inFlight = _initializing;
    if (inFlight != null) {
      return inFlight;
    }
    if (_initialized) {
      return Future.value();
    }
    // Параллельные вызовы ждут одну инициализацию: [_loadSoundSettings] может
    // переносить файл звука, и два конкурентных переноса скопировали бы один
    // файл в одну цель, а удалили бы исходник дважды (48.1).
    return _initializing = _initialize().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initialize() async {
    await _initTimeZone();
    await _loadSoundSettings();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_iconName),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: true,
      ),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Открыть'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      // Звук привязан к каналу и неизменен после создания, поэтому на первом
      // запуске канал создаётся сразу с нужным звуком, а при смене настройки
      // пересоздаётся (см. [_recreateChannel]).
      await android.createNotificationChannel(_buildChannel());
      await _logPermissionState(android);
    }
    _initialized = true;
    // Приложение могло быть запущено тапом по уведомлению: событие дошло до
    // плагина до инициализации, поэтому payload приходит только здесь.
    // Читаем не больше раза за процесс (см. [_launchDetailsRead]): сервис
    // пересоздаётся при импорте БД, и повторное чтение продублировало бы
    // переход на уже открытый день.
    //
    // Только на Android: у плагина `getNotificationAppLaunchDetails()`
    // реализован под web/Android/iOS/macOS/Windows, а на остальных платформах
    // (Linux — на нём идёт e2e) метод не переопределён и бросает
    // `UnimplementedError`, из-за чего каждая инициализация desktop-сборки
    // падала с ошибкой в лог (задача 47.15). Напоминания вне Android и не
    // планируются (те же методы пропускают Android-объект), так что терять
    // здесь нечего.
    if (android == null || _launchDetailsRead) {
      return;
    }
    _launchDetailsRead = true;
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        launchResponse != null) {
      // await обязателен: до догона [catchUpMissed] отметка доставки должна
      // успеть попасть в БД, иначе тапом открытый день показали бы второй раз.
      await handleNotificationResponse(launchResponse);
    }
  }

  /// Пишет в лог разрешения, с которыми стартовало приложение (задача 48.7).
  ///
  /// В 47.8 режим логируется только в момент постановки, поэтому по логу
  /// нельзя отличить «будильник поставили в точном режиме, а разрешение
  /// отозвали» от «система не доставила вовремя». Состояние читается один
  /// раз за запуск; сбой чтения — только запись в журнал, инициализация
  /// из-за него падать не должна.
  Future<void> _logPermissionState(
    AndroidFlutterLocalNotificationsPlugin android,
  ) async {
    try {
      final notificationsEnabled =
          await android.areNotificationsEnabled() ?? false;
      final exactAlarmsEnabled =
          await android.canScheduleExactNotifications() ?? false;
      logNotificationIssue(
        'Разрешения на старте: уведомления=$notificationsEnabled, '
        'точные будильники=$exactAlarmsEnabled '
        '(режим показа: ${exactAlarmsEnabled ? 'точный' : 'inexact'})',
      );
    } catch (e, st) {
      logNotificationIssue(
        'Не удалось прочитать разрешения на старте',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Читает сохранённые настройки звука напоминаний в кэш полей.
  Future<void> _loadSoundSettings() async {
    final settings = _soundSettings;
    if (settings == null) {
      return;
    }
    _soundEnabled = await settings.isEnabled();
    // Файл, выбранный до 48.1, лежит в приватном хранилище и системе
    // недоступен — репозиторий переносит его сам, владельцу перевыбирать файл
    // не приходится.
    await settings.ensureSoundFileReady();
    _soundFilePath = await settings.soundFilePath();
    _soundFileSystemReadable = await settings.isSoundSystemReadable();
  }

  /// Применяет настройки звука напоминаний (задача 47.5).
  ///
  /// Звук в Android привязан к каналу уведомлений и не может быть изменён
  /// после создания, поэтому канал удаляется и создаётся заново, а уже
  /// запланированные уведомления перепланируются с новым каналом.
  Future<void> applySoundSettings({
    required bool enabled,
    required String? filePath,
    bool systemReadable = true,
  }) async {
    _soundEnabled = enabled;
    _soundFilePath = filePath;
    _soundFileSystemReadable = systemReadable;
    await _recreateChannel();
    await rescheduleAll();
  }

  /// Удаляет и заново создаёт канал уведомлений с текущим звуком.
  Future<void> _recreateChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }
    await android.deleteNotificationChannel(channelId: _channelId);
    await android.createNotificationChannel(_buildChannel());
  }

  /// Канал уведомлений с текущими настройками звука.
  AndroidNotificationChannel _buildChannel() {
    return AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: _soundEnabled,
      sound: _androidSound,
      enableVibration: true,
    );
  }

  /// Звук уведомления: выбранный пользователем файл, если он есть и
  /// настройка включена; иначе встроенный raw-ресурс.
  ///
  /// **Ограничение Android:** звук канала воспроизводит системный процесс, а не
  /// приложение, поэтому файл должен быть ему доступен для чтения. Выбранный
  /// файл копируется во внешнюю директорию приложения именно поэтому (48.1);
  /// если системе он недоступен (копирование не удалось, файл удалён
  /// пользователем), канал получает встроенный raw-ресурс — уведомление
  /// приходит со стандартным сигналом приложения, а не молчит.
  AndroidNotificationSound? get _androidSound {
    if (!_soundEnabled) {
      return null;
    }
    final file = _soundFilePath;
    if (file == null || file.isEmpty || !File(file).existsSync()) {
      return const RawResourceAndroidNotificationSound(_soundName);
    }
    if (!_soundFileSystemReadable) {
      developer.log(
        'Файл звука напоминаний недоступен системе, канал использует '
        'встроенный сигнал: $file',
        name: 'ReminderService',
      );
      return const RawResourceAndroidNotificationSound(_soundName);
    }
    return UriAndroidNotificationSound(Uri.file(file).toString());
  }

  /// Разбирает нажатие на уведомление и передаёт `programDayId` обработчику.
  ///
  /// Попутно фиксирует, что системное напоминание этого дня показано: тап
  /// снимает уведомление из трея (`autoCancel`), поэтому догон его там уже
  /// не увидит и показал бы второй раз (задача 48.8).
  ///
  /// Открыт наружу (а не приватный метод) ради тестов: логика отложенной
  /// доставки payload'а — единственное, что отличает запуск тапом от обычного
  /// старта, и она обязана быть покрыта.
  @visibleForTesting
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload ?? '';
    final isManual = payload.startsWith(_manualPayloadPrefix);
    int? programDayId;
    if (isManual) {
      // Формат `m:<scheduleId>:<programDayId>`: строка назначения нужна, чтобы
      // отличать уведомление от еженедельного; навигация идёт по дню.
      final parts = payload.substring(_manualPayloadPrefix.length).split(':');
      if (parts.length == 2) {
        programDayId = int.tryParse(parts[1]);
      }
    } else {
      programDayId = int.tryParse(payload);
    }
    if (programDayId == null) {
      return;
    }
    final handler = _onReminderTapped;
    if (handler == null) {
      // Приложение стартовало тапом по уведомлению: обработчик появится
      // только после сборки UI, payload ждёт его.
      _pendingProgramDayId = programDayId;
    } else {
      handler(programDayId);
    }
    if (isManual) {
      // Отметка доставки (48.8) относится к еженедельным напоминаниям: тап по
      // ручному уведомлению не доказывает, что недельное дошло вовремя, —
      // записав её, мы заставили бы догон молча пропустить уведомление дня.
      return;
    }
    // Отметка доставки пишется после навигации — она не должна её ждать.
    // Догон, в свою очередь, дожидается записи через [_deliveryMarks].
    await _markDelivered(programDayId);
  }

  /// Запоминает, что системное напоминание дня показано (48.8).
  ///
  /// Сбой не роняет разбор payload'а: без отметки худший исход — прежнее
  /// поведение, догон показал бы уведомление второй раз.
  Future<void> _markDelivered(int programDayId) async {
    final log = _deliveredLog;
    if (log == null) {
      return;
    }
    final mark = () async {
      try {
        await log.markDelivered(programDayId, DateTime.now());
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось отметить доставку напоминания дня $programDayId',
          error: e,
          stackTrace: st,
        );
      }
    }();
    _deliveryMarks = _deliveryMarks.then((_) => mark);
    await mark;
  }

  /// Планирует еженедельное уведомление для дня по [dayOfWeek].
  Future<void> schedule(
    WorkoutReminder reminder, {
    required int dayOfWeek,
    required String programName,
    required int dayNumber,
  }) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      // Планируемые локальные уведомления поддерживает только Android. Без
      // этой проверки прямой вызов (например, при сохранении программы)
      // дошёл бы до zonedSchedule и на Linux попытался завести DBus-будильник,
      // а на web упал бы с MissingPluginException.
      return;
    }
    final enabled = await android.areNotificationsEnabled() ?? false;
    if (!enabled) {
      logNotificationIssue(
        'Уведомления отключены пользователем, пропуск планирования '
        'дня ${reminder.programDayId}',
      );
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = nextInstance(
      now,
      dayOfWeek: dayOfWeek,
      hour: reminder.hour,
      minute: reminder.minute,
    );
    final canExact = await android.canScheduleExactNotifications() ?? false;
    // Режим планирования в журнал: без него на устройстве (Xiaomi, задачи
    // 47.6/47.8-2а) невозможно отличить «система отложила inexact-будильник»
    // от «приложение запланировало не на то время».
    logNotificationIssue(
      'Напоминание дня ${reminder.programDayId} запланировано на $scheduled '
      '(${canExact ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle'})',
    );
    final details = _notificationDetails();
    try {
      await _plugin.zonedSchedule(
        id: reminder.programDayId,
        title: programName,
        body: _body(dayNumber),
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: reminder.programDayId.toString(),
      );
    } on PlatformException catch (e) {
      if (!canExact || e.code != _exactAlarmsNotPermitted) {
        rethrow;
      }
      // Точное разрешение отозвали между проверкой и вызовом: лучше
      // неточное напоминание с задержкой, чем никакого.
      logNotificationIssue(
        'Точный режим недоступен для дня ${reminder.programDayId}, '
        'планирую inexactAllowWhileIdle',
        error: e,
      );
      await _plugin.zonedSchedule(
        id: reminder.programDayId,
        title: programName,
        body: _body(dayNumber),
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: reminder.programDayId.toString(),
      );
    }
  }

  /// Базовый id уведомлений ручных назначений (48.10).
  ///
  /// id еженедельных напоминаний равен `programDayId` (автоинкремент
  /// `program_days` — единицы и десятки), поэтому одноразовым назначениям
  /// отведён собственный диапазон: отмена одного вида не задевает другой.
  static const int manualReminderIdBase = 1000000;

  /// Префикс payload'а ручного напоминания: `m:<scheduleId>:<programDayId>`.
  ///
  /// Еженедельные уведомления несут голый `programDayId`, и разбор по
  /// префиксу не даёт тапу по ручному уведомлению записать отметку
  /// доставки еженедельного дня ([_markDelivered], 48.8).
  static const String _manualPayloadPrefix = 'm:';

  /// Горизонт перепланирования одноразовых напоминаний (48.10).
  ///
  /// План показывает текущую и следующую недели, поэтому месяца с запасом
  /// хватает, чтобы покрыть всё ещё не наступившее.
  static const Duration manualHorizon = Duration(days: 30);

  /// Id уведомления ручного назначения [scheduleId].
  @visibleForTesting
  static int manualReminderId(int scheduleId) =>
      manualReminderIdBase + scheduleId;

  /// Планирует одноразовое уведомление ручного назначения (48.10).
  ///
  /// В отличие от [schedule] не повторяется по дню недели: вспыхивает ровно
  /// один раз — в дату и время назначения. На уже прошедшее время не
  /// планируется, иначе Android показал бы уведомление сразу после
  /// сохранения. Недельное напоминание того же дня при этом не отменяется:
  /// это два независимых уведомления (решение владельца).
  Future<void> scheduleManualReminder({
    required int scheduleId,
    required int programDayId,
    required DateTime date,
    required int hour,
    required int minute,
    required String programName,
    required int dayNumber,
  }) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      // Как и у еженедельных: локальные уведомления планируем только на
      // Android (на Linux здесь завёлся бы датчиковый DBus-будильник, а на
      // web упал бы MissingPluginException).
      return;
    }
    final enabled = await android.areNotificationsEnabled() ?? false;
    if (!enabled) {
      logNotificationIssue(
        'Уведомления отключены пользователем, пропуск планирования '
        'назначения $scheduleId',
      );
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      logNotificationIssue(
        'Время назначения $scheduleId уже прошло ($scheduled), пропуск',
      );
      return;
    }
    final canExact = await android.canScheduleExactNotifications() ?? false;
    logNotificationIssue(
      'Напоминание назначения $scheduleId запланировано на $scheduled '
      '(${canExact ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle'})',
    );
    final details = _notificationDetails();
    final payload = '$_manualPayloadPrefix$scheduleId:$programDayId';
    try {
      await _plugin.zonedSchedule(
        id: manualReminderId(scheduleId),
        title: programName,
        body: _body(dayNumber),
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (!canExact || e.code != _exactAlarmsNotPermitted) {
        rethrow;
      }
      // Точное разрешение отозвали между проверкой и вызовом: лучше
      // неточное уведомление с задержкой, чем никакого.
      logNotificationIssue(
        'Точный режим недоступен для назначения $scheduleId, '
        'планирую inexactAllowWhileIdle',
        error: e,
      );
      await _plugin.zonedSchedule(
        id: manualReminderId(scheduleId),
        title: programName,
        body: _body(dayNumber),
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: payload,
      );
    }
  }

  /// Отменяет одноразовое уведомление назначения [scheduleId] (48.10).
  ///
  /// Идемпотентна: вызывается и когда напоминания не было (выключено),
  /// и когда строки назначения уже нет.
  Future<void> cancelManualReminder(int scheduleId) =>
      _plugin.cancel(id: manualReminderId(scheduleId));

  /// Ставит одноразовое уведомление одной строки назначения (48.10).
  ///
  /// Строки с датой в прошлом сервис пропускает сам — после импорта базы и
  /// на горизонте перепланирования встречаются назначения, время которых
  /// уже прошло.
  Future<void> _scheduleManualItem(PlanScheduleReminder item) async {
    await scheduleManualReminder(
      scheduleId: item.scheduleId,
      programDayId: item.programDayId,
      date: item.scheduledDate,
      hour: item.hour,
      minute: item.minute,
      programName: item.programName,
      dayNumber: item.dayNumber,
    );
  }

  /// Перепланировывает одноразовые напоминания всех дней [programDayIds] (48.10).
  ///
  /// Вызывается при активации программы вместе с недельными напоминаниями:
  /// ручные назначения её дней должны перевзвестись так же.
  Future<void> _rescheduleManualForDays(Iterable<int> programDayIds) async {
    final rows =
        await _planSchedule?.remindersForDays(programDayIds) ?? const [];
    for (final item in rows) {
      try {
        await _scheduleManualItem(item);
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось перепланировать напоминание назначения '
          '${item.scheduleId}',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Отменяет одноразовые напоминания дней [programDayIds] (48.10).
  ///
  /// Вызывается при деактивации программы: настройки дней и назначений в БД
  /// остаются, а уведомления повторной активации будут поставлены заново.
  Future<void> _cancelManualForDays(Iterable<int> programDayIds) async {
    final rows =
        await _planSchedule?.remindersForDays(programDayIds) ?? const [];
    for (final item in rows) {
      try {
        await cancelManualReminder(item.scheduleId);
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось отменить напоминание назначения ${item.scheduleId}',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Перепланировывает все одноразовые напоминания в горизонте (48.10).
  ///
  /// Нужно после импорта базы (`cancelAll` снял их вместе со всеми) и при
  /// возврате в приложение: система могла отозвать точные будильники, а
  /// пользователь — сменить часовой пояс. Еженедельные напоминания при этом
  /// не затрагиваются.
  Future<void> _rescheduleManualAll() async {
    final planSchedule = _planSchedule;
    if (planSchedule == null) {
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final rows = await planSchedule.remindersBetween(
      now,
      now.add(manualHorizon),
    );
    for (final item in rows) {
      try {
        await _scheduleManualItem(item);
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось перепланировать напоминание назначения '
          '${item.scheduleId}',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Показывает пропущенное напоминание сразу, если система его не доставила
  /// (задача 47.6).
  ///
  /// Вызывается на холодном старте и при возврате в приложение. Без точных
  /// будильников Android откладывает доставку (окно будильника — минуты, в
  /// Doze и на агрессивных прошивках — до десятков минут), а после
  /// «Остановить приложение» в настройках Android будильники отменяются
  /// вовсе. Пользователь узнаёт о тренировке слишком поздно или не узнаёт —
  /// догон показывает пропуск в момент возврата в приложение, один раз в
  /// день на день программы ([catchUpGrace] отсекает штатную задержку
  /// inexact-будильника).
  ///
  /// Защита от двойного показа (задача 48.8): дни с отметкой системной
  /// доставки ([ReminderDeliveredLog], пишется при тапе по уведомлению)
  /// пропускаются, отметка догона ставится до показа (claim-before-show),
  /// трей перечитывается прямо перед показом, а параллельные вызовы
  /// схлопываются в один прогон.
  Future<void> catchUpMissed() {
    final running = _catchUpRunning;
    if (running != null) {
      // Уже идёт: второй вызов (инициализация при старте и возврат из фона)
      // ждёт его, а не запускает свой прогон с тем же показом.
      return running;
    }
    return _catchUpRunning = _catchUpMissed().whenComplete(() {
      _catchUpRunning = null;
    });
  }

  Future<void> _catchUpMissed() async {
    if (_plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() ==
        null) {
      return;
    }
    // Тап по уведомлению в фоне мог ещё писать отметку доставки.
    await _deliveryMarks;
    final items = await _repository.allScheduled();
    if (items.isEmpty) {
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final deliveredLog = _deliveredLog;
    final log = _catchUpLog;
    for (final item in items) {
      if (!item.reminder.enabled) {
        continue;
      }
      final programDayId = item.reminder.programDayId;
      final due = catchUpDueTime(
        now,
        dayOfWeek: item.dayOfWeek,
        hour: item.reminder.hour,
        minute: item.reminder.minute,
      );
      if (due == null) {
        continue;
      }
      try {
        // Пользователь уже видел системное напоминание этого дня (открыл
        // приложение тапом по нему) — второй показ не нужен, хотя уведомления
        // в трее после `autoCancel` и нет (48.8, D1/D6).
        if (deliveredLog != null &&
            await deliveredLog.wasDeliveredOn(programDayId, now.toLocal())) {
          continue;
        }
        // Напоминание показывали сегодня другим путём (догон на прошлом
        // запуске) — повторный прогон молчит.
        if (log != null && await log.wasShownOn(programDayId, now)) {
          continue;
        }
        // Система могла доставить уведомление уже после начала прогона,
        // поэтому трей читаем прямо перед показом, а не один раз до цикла
        // (48.8, D2).
        if ((await _activeNotificationIds()).contains(programDayId)) {
          continue;
        }
        // Claim до показа: параллельный прогон увидит отметку и не
        // продублирует уведомление (48.8, D3).
        await log?.markShown(programDayId, now);
        try {
          await _plugin.show(
            id: programDayId,
            title: item.programName,
            body: '${_body(item.dayNumber)} ($_catchUpReason)',
            notificationDetails: _notificationDetails(),
            payload: programDayId.toString(),
          );
        } catch (_) {
          // Показ не удался — снимаем отметку, иначе день навсегда остался
          // бы «показанным» и догон не повторил бы попытку.
          await _unmarkQuietly(log, programDayId);
          rethrow;
        }
        logNotificationIssue(
          'Показано пропущенное напоминание дня $programDayId '
          '(плановое время $due)',
        );
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось показать пропущенное напоминание дня $programDayId',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Снимает отметку догона после неудачного показа (48.8, D3).
  ///
  /// Сбой здесь не затмевает исходную ошибку показа: он лишь пишется в
  /// журнал.
  Future<void> _unmarkQuietly(ReminderCatchUpLog? log, int programDayId) async {
    if (log == null) {
      return;
    }
    try {
      await log.unmarkShown(programDayId);
    } catch (e, st) {
      logNotificationIssue(
        'Не удалось снять отметку догона дня $programDayId',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Плановое время сегодняшнего напоминания, если его пора показывать, —
  /// иначе null.
  ///
  /// Отдельная чистая функция (как [nextInstance]): правило «сегодня, тот же
  /// день недели и просрочено дольше [catchUpGrace]» обязано проверяться
  /// детерминированно, а не гонкой с системными часами.
  @visibleForTesting
  static tz.TZDateTime? catchUpDueTime(
    tz.TZDateTime now, {
    required int? dayOfWeek,
    required int hour,
    required int minute,
  }) {
    if (dayOfWeek == null || dayOfWeek != now.weekday) {
      return null;
    }
    final due = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    return now.difference(due) >= catchUpGrace ? due : null;
  }

  /// Идентификаторы уведомлений, которые сейчас висят в трее.
  ///
  /// Пустое множество при любой ошибке: догон лишь подстраховывается, ломать
  /// из-за недоступности системного списка нельзя.
  Future<Set<int>> _activeNotificationIds() async {
    try {
      final active = await _plugin.getActiveNotifications();
      return {for (final notification in active) notification.id ?? -1};
    } catch (e, st) {
      logNotificationIssue(
        'Не удалось прочитать активные уведомления',
        error: e,
        stackTrace: st,
      );
      return <int>{};
    }
  }

  /// Описание уведомления с текущими настройками звука.
  NotificationDetails _notificationDetails() => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: _soundEnabled,
      sound: _androidSound,
    ),
    iOS: const DarwinNotificationDetails(),
    macOS: const DarwinNotificationDetails(),
  );

  static String _body(int dayNumber) => 'Тренировка: день $dayNumber';

  /// Пояснение к пропущенному напоминанию.
  static const String _catchUpReason = 'напоминание задержано системой';

  /// Отменяет уведомление дня по [programDayId].
  Future<void> cancel(int programDayId) async {
    await _plugin.cancel(id: programDayId);
  }

  /// Перепланирует напоминания указанных дней программы.
  ///
  /// Вызывается при активации программы (задача 47.8, п. 2г): настройки дней
  /// сохраняются в БД и при деактивации, но уведомления должны появляться
  /// только у активных программ. День без привязки или выключенное напоминание
  /// отменяется, а не планируется.
  Future<void> rescheduleDays(Iterable<int> programDayIds) async {
    if (_plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() ==
        null) {
      return;
    }
    final items = await _repository.scheduledForDays(programDayIds);
    for (final item in items) {
      final programDayId = item.reminder.programDayId;
      try {
        if (item.dayOfWeek == null || !item.reminder.enabled) {
          await cancel(programDayId);
          continue;
        }
        await schedule(
          item.reminder,
          dayOfWeek: item.dayOfWeek!,
          programName: item.programName,
          dayNumber: item.dayNumber,
        );
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось перепланировать напоминание дня $programDayId',
          error: e,
          stackTrace: st,
        );
      }
    }
    // Ручные назначения дней (48.10) перевзвешиваются вместе с недельными:
    // активация программы не должна оставить их уведомления без перепланировки.
    await _rescheduleManualForDays(programDayIds);
  }

  /// Отменяет уведомления указанных дней, не удаляя их настройки из БД.
  ///
  /// Вызывается при деактивации программы (задача 47.8, п. 2г): настройки
  /// сохраняются, чтобы повторная активация могла их запланировать снова.
  Future<void> cancelDays(Iterable<int> programDayIds) async {
    for (final programDayId in programDayIds) {
      try {
        await cancel(programDayId);
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось отменить напоминание дня $programDayId',
          error: e,
          stackTrace: st,
        );
      }
    }
    // Одноразовые напоминания ручных назначений (48.10): настройки строк
    // остаются в БД, снимаются только запланированные уведомления.
    await _cancelManualForDays(programDayIds);
  }

  /// Отменяет все запланированные уведомления.
  ///
  /// Нужен перед полной перепланировкой: аварийные будильники удалённых дней
  /// иначе остаются жить и напоминают о несуществующих тренировках.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Перепланирует все сохранённые напоминания (после импорта БД).
  ///
  /// Ошибка отдельного дня не должна срывать перепланирование остальных:
  /// иначе одно «битое» напоминание тихо оставляет весь список неактуальным.
  Future<void> rescheduleAll() async {
    // Планируемые локальные уведомления есть только на Android. На остальных
    // платформах расписание нечего переносить: `schedule()` там всё равно
    // дошёл бы до `zonedSchedule` и попытался завести датчиковый будильник
    // (DBus), который без запущенного приложения не сработает никогда.
    if (_plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() ==
        null) {
      return;
    }
    final items = await _repository.allScheduled();
    for (final item in items) {
      final programDayId = item.reminder.programDayId;
      try {
        if (item.dayOfWeek == null || !item.reminder.enabled) {
          await cancel(programDayId);
          continue;
        }
        await schedule(
          item.reminder,
          dayOfWeek: item.dayOfWeek!,
          programName: item.programName,
          dayNumber: item.dayNumber,
        );
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось перепланировать напоминание дня $programDayId',
          error: e,
          stackTrace: st,
        );
      }
    }
    // Ручные назначения с временем (48.10): `cancelAll` перед импортом снял
    // их вместе со всеми уведомлениями, поэтому без этой строки назначения
    // остались бы без напоминаний.
    await _rescheduleManualAll();
  }

  /// Ближайшее будущее вхождение дня недели [dayOfWeek] в [hour]:[minute].
  ///
  /// [dayOfWeek]: 1 — понедельник … 7 — воскресенье (как у [DateTime.weekday]).
  @visibleForTesting
  static tz.TZDateTime nextInstance(
    tz.TZDateTime now, {
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    final daysUntil = (dayOfWeek - now.weekday) % 7;
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + daysUntil,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  /// Инициализирует базу часовых поясов и локальную зону.
  ///
  /// Без явного `setLocalLocation` планирование уходит в UTC, и уведомления
  /// приходят со сдвигом на разницу часов — молча. Поэтому неудача видна в
  /// логе, даже когда часовой пояс определить не удалось.
  Future<void> _initTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } on Exception catch (e) {
      logNotificationIssue(
        'Не удалось определить локальный часовой пояс, напоминания '
        'планируются в UTC',
        error: e,
      );
    }
  }
}
