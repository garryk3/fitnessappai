// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'FitnessAppAI';

  @override
  String placeholderTab(String tab) {
    return 'Раздел «$tab» в разработке';
  }

  @override
  String get navHome => 'Главная';

  @override
  String get navExercises => 'Упражнения';

  @override
  String get navPrograms => 'Программы';

  @override
  String get navPlan => 'План';

  @override
  String get navProgress => 'Прогресс';

  @override
  String get navProfile => 'Профиль';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonAll => 'Все';

  @override
  String get commonEdit => 'Редактировать';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get settings => 'Настройки';

  @override
  String get settingsSyncSection => 'Синхронизация';

  @override
  String get settingsSoundSection => 'Звук';

  @override
  String get soundEnabled => 'Звук таймеров';

  @override
  String get soundPickFile => 'Выбрать звук';

  @override
  String get soundReset => 'Вернуть стандартный сигнал';

  @override
  String get soundDefaultLabel => 'Стандартный сигнал';

  @override
  String get settingsThemeSection => 'Тема';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get exerciseTypeStrength => 'Силовые';

  @override
  String get exerciseTypeBodyweight => 'Свой вес';

  @override
  String get exerciseTypePlank => 'Планка';

  @override
  String get exerciseTypeRunning => 'Бег';

  @override
  String get exerciseListHint => 'Поиск упражнений';

  @override
  String get exerciseListEmpty => 'Список упражнений пуст';

  @override
  String get exerciseFilterAll => 'Все';

  @override
  String get exerciseListCreate => 'Новое упражнение';

  @override
  String get schedulePerformed => 'Выполнено';

  @override
  String get scheduleRescheduled => 'Перенесено';

  @override
  String get scheduleSkipped => 'Пропущено';

  @override
  String get schedulePending => 'Запланировано';

  @override
  String get weekPlanToday => 'Сегодня';

  @override
  String get weekPlanStart => 'Начать';

  @override
  String get weekPlanReschedule => 'Перенести на сегодня';

  @override
  String get weekPlanSkip => 'Пропустить';

  @override
  String get weekPlanUnskip => 'Отменить пропуск';

  @override
  String get weekPlanEmpty => 'Нет запланированных тренировок';

  @override
  String get weekPlanHint =>
      'Привяжите дни программы к дням недели в конструкторе, чтобы они появились в плане';

  @override
  String get weekPlanPrevWeek => 'Предыдущая неделя';

  @override
  String get weekPlanNextWeek => 'Следующая неделя';

  @override
  String get weekPlanQuickStart => 'Быстрый старт';

  @override
  String get muscleAbs => 'Пресс';

  @override
  String get muscleObliques => 'Косые';

  @override
  String get muscleChest => 'Грудь';

  @override
  String get muscleShoulders => 'Плечи';

  @override
  String get muscleBiceps => 'Бицепс';

  @override
  String get muscleTriceps => 'Трицепс';

  @override
  String get muscleForearms => 'Предплечья';

  @override
  String get muscleTraps => 'Трапеции';

  @override
  String get muscleLats => 'Широчайшие';

  @override
  String get muscleLowerBack => 'Поясница';

  @override
  String get muscleGlutes => 'Ягодицы';

  @override
  String get muscleQuads => 'Квадрицепсы';

  @override
  String get muscleHamstrings => 'Бицепс бедра';

  @override
  String get muscleCalves => 'Икры';

  @override
  String get muscleNeck => 'Шея';

  @override
  String get errorNotFound => 'Страница не найдена';

  @override
  String get exerciseNew => 'Новое упражнение';

  @override
  String get exerciseEdit => 'Редактирование упражнения';

  @override
  String get exerciseDetail => 'Упражнение';

  @override
  String get exerciseDetailNotFound => 'Упражнение не найдено';

  @override
  String get exerciseDetailDescription => 'Описание';

  @override
  String get exerciseDetailTechnique => 'Техника выполнения';

  @override
  String get exerciseDetailMistakes => 'Частые ошибки';

  @override
  String get exerciseDetailMuscles => 'Задействованные мышцы';

  @override
  String exerciseDetailDeleteConfirm(String name) {
    return 'Удалить упражнение «$name»?';
  }

  @override
  String exerciseDetailDeleteBlocked(String name) {
    return 'Нельзя удалить «$name»';
  }

  @override
  String get exerciseDetailDeleteBlockedHint =>
      'Упражнение используется в программах:';

  @override
  String get exerciseFormName => 'Название';

  @override
  String get exerciseFormType => 'Тип';

  @override
  String get exerciseFormDescription => 'Описание';

  @override
  String get exerciseFormTechnique => 'Техника выполнения';

  @override
  String get exerciseFormMistakes => 'Частые ошибки';

  @override
  String get exerciseFormMistakeAdd => 'Добавить ошибку';

  @override
  String get exerciseFormMuscles => 'Задействованные мышцы';

  @override
  String get exerciseFormMusclesRequired => 'Выберите хотя бы одну мышцу';

  @override
  String get exerciseFormMusclePrimary => 'Основная';

  @override
  String get exerciseFormMuscleSecondary => 'Вспомогательная';

  @override
  String get exerciseFormContraindications => 'Противопоказания';

  @override
  String get exerciseFormAnimation => 'Анимация';

  @override
  String get exerciseFormAnimationPick => 'Выбрать анимацию';

  @override
  String get exerciseFormAnimationRemove => 'Убрать анимацию';

  @override
  String get exerciseFormAnimationError =>
      'Не удалось загрузить файл. Попробуйте ещё раз.';

  @override
  String get exerciseFormThumbnail => 'Миниатюра';

  @override
  String get exerciseFormThumbnailPick => 'Выбрать изображение';

  @override
  String get exerciseFormThumbnailRemove => 'Убрать изображение';

  @override
  String get exerciseFormNameRequired => 'Введите название';

  @override
  String get exerciseFormSave => 'Сохранить';

  @override
  String get exerciseFormHideOptional =>
      'Скрывать необязательные поля в тренировке';

  @override
  String get exerciseFormHideOptionalHelp =>
      'Описание, техника и параметры не будут показываться при выполнении';

  @override
  String get exerciseParams => 'Параметры упражнения';

  @override
  String get programNew => 'Новая программа';

  @override
  String get programEdit => 'Редактирование программы';

  @override
  String get programListEmpty => 'Список программ пуст';

  @override
  String get programListCreate => 'Новая программа';

  @override
  String get programMakeActive => 'Сделать активной';

  @override
  String get programActive => 'Активная';

  @override
  String get programCopyJson => 'Скопировать JSON';

  @override
  String get copyJsonCopied => 'JSON скопирован в буфер обмена';

  @override
  String get copyJsonNotFound => 'Не удалось скопировать JSON';

  @override
  String programDeleteConfirm(String name) {
    return 'Удалить программу «$name»?';
  }

  @override
  String programDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      few: '$count дня',
      one: '1 день',
    );
    return '$_temp0';
  }

  @override
  String programExercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнений',
      few: '$count упражнения',
      one: '1 упражнение',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMon => 'Пн';

  @override
  String get weekdayTue => 'Вт';

  @override
  String get weekdayWed => 'Ср';

  @override
  String get weekdayThu => 'Чт';

  @override
  String get weekdayFri => 'Пт';

  @override
  String get weekdaySat => 'Сб';

  @override
  String get weekdaySun => 'Вс';

  @override
  String get programBuilderName => 'Название';

  @override
  String get programBuilderNameRequired => 'Введите название';

  @override
  String get programBuilderDescription => 'Описание';

  @override
  String get programBuilderDaysCount => 'Количество дней';

  @override
  String programBuilderDay(int index) {
    return 'День $index';
  }

  @override
  String get programBuilderDayNoWeekday => 'Без привязки';

  @override
  String get programBuilderDayWeekday => 'День недели';

  @override
  String get programBuilderDaySettings => 'Настройка дня';

  @override
  String get programBuilderWarmupMinutes => 'Разминка, мин';

  @override
  String programBuilderWarmupShort(int minutes) {
    return 'разминка $minutes мин';
  }

  @override
  String get reminderToggle => 'Напоминать';

  @override
  String get reminderTime => 'Время напоминания';

  @override
  String get programBuilderSave => 'Сохранить';

  @override
  String programBuilderFillNextDay(int dayNumber) {
    return 'Заполнить день $dayNumber';
  }

  @override
  String get programBuilderAddExercise => 'Добавить упражнение';

  @override
  String get programBuilderPickExercise => 'Выберите упражнение';

  @override
  String get programBuilderMainSet => 'Основной набор';

  @override
  String get programBuilderAlternativeSet => 'Альтернативный набор';

  @override
  String get programBuilderMuscles => 'Задействованные мышцы';

  @override
  String get programBuilderMuscleFilter => 'Мышцы';

  @override
  String get programBuilderTypeFilter => 'Категория';

  @override
  String get programBuilderEmptyDay => 'В этом дне пока нет упражнений';

  @override
  String programBuilderDayProgress(int filled, int total) {
    return 'Заполнено $filled из $total дней';
  }

  @override
  String get programBuilderMetricsInvalid =>
      'Укажите параметры упражнения перед сохранением';

  @override
  String get programValidationTitle => 'Недостаточно данных для сохранения';

  @override
  String get programValidationMessage => 'Заполните недостающее:';

  @override
  String get programValidationContinue => 'Продолжить редактирование';

  @override
  String get programValidationExit => 'Выйти';

  @override
  String get programBuilderNoMetrics => 'Параметры не заданы';

  @override
  String get exerciseParamsSets => 'Подходы';

  @override
  String get exerciseParamsReps => 'Повторения';

  @override
  String get exerciseParamsWeightKg => 'Вес (кг)';

  @override
  String get exerciseParamsDurationSeconds => 'Время (сек)';

  @override
  String get exerciseParamsDurationMinutes => 'Время (мин)';

  @override
  String get exerciseParamsDistanceKm => 'Дистанция (км)';

  @override
  String get exerciseParamsRestSeconds => 'Отдых (сек)';

  @override
  String get exerciseParamsRequired => 'Заполните поле';

  @override
  String get exerciseParamsPositive => 'Значение должно быть больше нуля';

  @override
  String get exerciseParamsNotNegative =>
      'Значение не может быть отрицательным';

  @override
  String get exerciseParamsHoldHint => 'Пусто — время удержания со счётчика';

  @override
  String get workoutPrepare => 'Подготовка к тренировке';

  @override
  String get workoutRun => 'Тренировка';

  @override
  String get workoutPrepareStart => 'Начать тренировку';

  @override
  String get workoutWarmup => 'Разминка';

  @override
  String get workoutWarmupDone => 'Разминка завершена';

  @override
  String get workoutWarmupSkip => 'Пропустить';

  @override
  String workoutWarmupSecondsLeft(int seconds) {
    return 'осталось $seconds с';
  }

  @override
  String get workoutWarmupStartWorkout => 'Начать тренировку';

  @override
  String get workoutPrepareNotFound => 'День не найден';

  @override
  String workoutPrepareRest(int seconds) {
    return 'Отдых $seconds с';
  }

  @override
  String get workoutUnitReps => 'повт';

  @override
  String get workoutUnitSeconds => 'с';

  @override
  String get workoutUnitMinutes => 'мин';

  @override
  String get workoutUnitKg => 'кг';

  @override
  String get workoutUnitKm => 'км';

  @override
  String workoutRunExerciseOf(int current, int total) {
    return 'Упражнение $current из $total';
  }

  @override
  String workoutRunSetOf(int current, int total) {
    return 'Подход $current из $total';
  }

  @override
  String get workoutRunApproachDone => 'Подход выполнен';

  @override
  String get workoutRunRest => 'Отдых';

  @override
  String get workoutRunSkipRest => 'Пропустить отдых';

  @override
  String get workoutRunFinish => 'Завершить тренировку';

  @override
  String get workoutRunFinished => 'Тренировка завершена';

  @override
  String workoutRunHold(int seconds) {
    return 'Удержание $seconds с';
  }

  @override
  String workoutRunHoldTarget(int seconds) {
    return 'Цель: $seconds с';
  }

  @override
  String get workoutRunHoldStart => 'Начать';

  @override
  String get workoutRunExitTitle => 'Выйти из тренировки?';

  @override
  String get workoutRunExitBody => 'Тренировка не будет сохранена. Выйти?';

  @override
  String get workoutRunExit => 'Выйти';

  @override
  String workoutRunTime(int minutes) {
    return 'Время: $minutes мин';
  }

  @override
  String workoutRunSetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подходов',
      few: '$count подхода',
      one: '1 подход',
    );
    return '$_temp0';
  }

  @override
  String get workoutRunSaved => 'Тренировка сохранена';

  @override
  String get workoutRunGoProgress => 'К прогрессу';

  @override
  String get workoutRunEmpty => 'В этом дне нет упражнений';

  @override
  String get progressPeriodWeek => 'Неделя';

  @override
  String get progressPeriodMonth => 'Месяц';

  @override
  String get progressPeriodYear => 'Год';

  @override
  String get progressWorkouts => 'Тренировок';

  @override
  String get progressDistance => 'Дистанция';

  @override
  String get progressPlankTime => 'Время планки';

  @override
  String get progressWorkoutsChart => 'Тренировки по срезам';

  @override
  String get progressMetricChart => 'Прогресс метрики';

  @override
  String get progressMuscleLoad => 'Нагрузка на мышцы';

  @override
  String get progressEmpty => 'Нет тренировок за период';

  @override
  String get progressProgression => 'Динамика упражнения';

  @override
  String get progressProgressionOpen => 'Открыть динамику';

  @override
  String get progressProgressionEmpty =>
      'Ещё нет тренировок с этим упражнением';

  @override
  String get progressProgressionMax => 'Максимум';

  @override
  String get progressDayDetail => 'Тренировки за день';

  @override
  String get progressDayEmpty => 'Нет тренировок за этот день';

  @override
  String get monthShortJan => 'Янв';

  @override
  String get monthShortFeb => 'Фев';

  @override
  String get monthShortMar => 'Мар';

  @override
  String get monthShortApr => 'Апр';

  @override
  String get monthShortMay => 'Май';

  @override
  String get monthShortJun => 'Июн';

  @override
  String get monthShortJul => 'Июл';

  @override
  String get monthShortAug => 'Авг';

  @override
  String get monthShortSep => 'Сен';

  @override
  String get monthShortOct => 'Окт';

  @override
  String get monthShortNov => 'Ноя';

  @override
  String get monthShortDec => 'Дек';

  @override
  String get history => 'История';

  @override
  String get historyDetail => 'Детали тренировки';

  @override
  String get historyEmpty => 'Пока нет тренировок';

  @override
  String get historySessionNotFound => 'Тренировка не найдена';

  @override
  String get homeActiveProgram => 'Активная программа';

  @override
  String get homeUpcomingDay => 'Ближайший день';

  @override
  String get homeRecentWorkouts => 'Последние тренировки';

  @override
  String get homeNoProgramsTitle => 'Нет программ';

  @override
  String get homeNoProgramsHint =>
      'Создайте программу тренировок, чтобы видеть её здесь.';

  @override
  String get homeGoToPrograms => 'К программам';

  @override
  String get homeNoActiveProgramHint =>
      'Сделайте программу активной, чтобы видеть её здесь.';

  @override
  String get homeNoWorkoutsHint =>
      'Выполните первую тренировку — она появится здесь.';

  @override
  String get homeViewAll => 'Вся история';

  @override
  String get homeGoToHistory => 'К истории';

  @override
  String get historyCopyJson => 'Скопировать JSON';

  @override
  String get historyCopyJsonTooltip => 'Скопировать историю в JSON';

  @override
  String historyExercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнений',
      few: '$count упражнения',
      one: '1 упражнение',
    );
    return '$_temp0';
  }

  @override
  String historyDuration(int minutes) {
    return '$minutes мин';
  }

  @override
  String get sync => 'Синхронизация';

  @override
  String get syncCloudHint =>
      'Переносите данные между устройствами через файл резервной копии базы данных.';

  @override
  String get syncCloudComing => 'Облачная синхронизация появится позже.';

  @override
  String get syncShare => 'Поделиться';

  @override
  String get syncSaveFile => 'Сохранить в файлы';

  @override
  String get syncImport => 'Импортировать БД';

  @override
  String get syncImportSuccess => 'База данных импортирована';

  @override
  String get syncRestartHint =>
      'Для полного применения изменений приложение будет перезапущено.';

  @override
  String get contraindications => 'Противопоказания';

  @override
  String get contraindicationsTitle => 'Моё здоровье';

  @override
  String get contraindicationsHint =>
      'Отметьте свои противопоказания. Упражнения с ними будут отмечены предупреждением.';

  @override
  String get contraindicationsSaved => 'Настройки сохранены';

  @override
  String get contraindicationWarningForYou => 'Есть противопоказания для вас';

  @override
  String get workoutWarningsTitle => 'Противопоказания';

  @override
  String get workoutWarningsBody =>
      'В программе есть упражнения с противопоказаниями:';

  @override
  String get workoutWarningsProceed => 'Продолжить';

  @override
  String get workoutWarningsDontShow =>
      'Больше не показывать для этой программы';

  @override
  String get contraindicationDescKnees => 'Избегайте приседаний и прыжков.';

  @override
  String get contraindicationDescBack =>
      'Избегайте осевых нагрузок на позвоночник.';

  @override
  String get contraindicationDescNeck => 'Избегайте нагрузки на шейный отдел.';

  @override
  String get contraindicationDescShoulders =>
      'Избегайте жимов и махов над головой.';

  @override
  String get contraindicationDescElbows =>
      'Избегайте ударной нагрузки на локти.';

  @override
  String get contraindicationDescWrists =>
      'Избегайте упоров и отжиманий на запястьях.';

  @override
  String get contraindicationDescHeart =>
      'Проконсультируйтесь с врачом перед тренировками.';

  @override
  String get contraindicationDescPregnancy =>
      'Умеренные нагрузки, без упражнений на пресс.';

  @override
  String get profileCurrentValues => 'Текущие значения';

  @override
  String get profileMetricChart => 'Динамика';

  @override
  String get profileMeasurementsHistory => 'История замеров';

  @override
  String get profileEmpty => 'Пока нет замеров тела';

  @override
  String get profileChartEmpty => 'Добавьте замеры, чтобы увидеть динамику';

  @override
  String get profileAddMeasurement => 'Добавить замер';

  @override
  String get profileDeleteMeasurementConfirm => 'Удалить замер?';

  @override
  String get profileUnitCm => 'см';

  @override
  String get measurementFormTitle => 'Новый замер';

  @override
  String get measurementFormDate => 'Дата';

  @override
  String get measurementFormNumberError => 'Введите число';
}
