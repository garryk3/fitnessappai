import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'FitnessAppAI'**
  String get appTitle;

  /// Заглушка экрана вкладки
  ///
  /// In ru, this message translates to:
  /// **'Раздел «{tab}» в разработке'**
  String placeholderTab(String tab);

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navExercises.
  ///
  /// In ru, this message translates to:
  /// **'Упражнения'**
  String get navExercises;

  /// No description provided for @navPrograms.
  ///
  /// In ru, this message translates to:
  /// **'Программы'**
  String get navPrograms;

  /// No description provided for @navPlan.
  ///
  /// In ru, this message translates to:
  /// **'План'**
  String get navPlan;

  /// No description provided for @navProgress.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get commonToday;

  /// No description provided for @commonOk.
  ///
  /// In ru, this message translates to:
  /// **'ОК'**
  String get commonOk;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get commonAll;

  /// No description provided for @commonEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get commonAdd;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @settingsSyncSection.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация'**
  String get settingsSyncSection;

  /// No description provided for @settingsSoundSection.
  ///
  /// In ru, this message translates to:
  /// **'Звук'**
  String get settingsSoundSection;

  /// No description provided for @soundEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Звук таймеров'**
  String get soundEnabled;

  /// No description provided for @soundPickFile.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать звук'**
  String get soundPickFile;

  /// No description provided for @soundReset.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть стандартный сигнал'**
  String get soundReset;

  /// No description provided for @soundPreview.
  ///
  /// In ru, this message translates to:
  /// **'Прослушать'**
  String get soundPreview;

  /// No description provided for @soundStop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get soundStop;

  /// No description provided for @soundDefaultLabel.
  ///
  /// In ru, this message translates to:
  /// **'Стандартный сигнал'**
  String get soundDefaultLabel;

  /// No description provided for @settingsThemeSection.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsThemeSection;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get settingsThemeLight;

  /// No description provided for @settingsAboutSection.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAboutSection;

  /// No description provided for @settingsAboutHint.
  ///
  /// In ru, this message translates to:
  /// **'Проверка обновлений выполняется через GitHub.'**
  String get settingsAboutHint;

  /// No description provided for @settingsVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get settingsVersion;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Проверить обновление'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsUpdateAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Доступна новая версия'**
  String get settingsUpdateAvailable;

  /// Сообщение диалога обновления
  ///
  /// In ru, this message translates to:
  /// **'Версия {version} доступна для скачивания.'**
  String settingsUpdateContent(String version);

  /// No description provided for @settingsUpdateLater.
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get settingsUpdateLater;

  /// No description provided for @settingsUpdateDownload.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get settingsUpdateDownload;

  /// No description provided for @commonClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @exerciseTypeStrength.
  ///
  /// In ru, this message translates to:
  /// **'Силовые'**
  String get exerciseTypeStrength;

  /// No description provided for @exerciseTypeBodyweight.
  ///
  /// In ru, this message translates to:
  /// **'Свой вес'**
  String get exerciseTypeBodyweight;

  /// No description provided for @exerciseTypePlank.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get exerciseTypePlank;

  /// No description provided for @exerciseTypeRunning.
  ///
  /// In ru, this message translates to:
  /// **'Бег'**
  String get exerciseTypeRunning;

  /// No description provided for @exerciseListHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск упражнений'**
  String get exerciseListHint;

  /// No description provided for @exerciseListEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Список упражнений пуст'**
  String get exerciseListEmpty;

  /// No description provided for @exerciseFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get exerciseFilterAll;

  /// No description provided for @exerciseListCreate.
  ///
  /// In ru, this message translates to:
  /// **'Новое упражнение'**
  String get exerciseListCreate;

  /// No description provided for @exerciseListOnlyCustom.
  ///
  /// In ru, this message translates to:
  /// **'Только свои упражнения'**
  String get exerciseListOnlyCustom;

  /// No description provided for @exerciseListDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить упражнение ({count, plural, one{#} few{#} other{#}})?'**
  String exerciseListDeleteTitle(int count);

  /// No description provided for @exerciseListDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить {count, plural, one{выбранное упражнение} few{# выбранных упражнения} other{# выбранных упражнений}}?'**
  String exerciseListDeleteConfirm(int count);

  /// No description provided for @exerciseListDeleteButton.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get exerciseListDeleteButton;

  /// No description provided for @exerciseListDeleteWarning.
  ///
  /// In ru, this message translates to:
  /// **'Упражнение используется в программах:'**
  String get exerciseListDeleteWarning;

  /// No description provided for @schedulePerformed.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено'**
  String get schedulePerformed;

  /// No description provided for @scheduleRescheduled.
  ///
  /// In ru, this message translates to:
  /// **'Перенесено'**
  String get scheduleRescheduled;

  /// No description provided for @scheduleSkipped.
  ///
  /// In ru, this message translates to:
  /// **'Пропущено'**
  String get scheduleSkipped;

  /// No description provided for @schedulePending.
  ///
  /// In ru, this message translates to:
  /// **'Запланировано'**
  String get schedulePending;

  /// No description provided for @weekPlanToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get weekPlanToday;

  /// No description provided for @weekPlanStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get weekPlanStart;

  /// No description provided for @weekPlanReschedule.
  ///
  /// In ru, this message translates to:
  /// **'Перенести на сегодня'**
  String get weekPlanReschedule;

  /// No description provided for @weekPlanSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get weekPlanSkip;

  /// No description provided for @weekPlanUnskip.
  ///
  /// In ru, this message translates to:
  /// **'Отменить пропуск'**
  String get weekPlanUnskip;

  /// No description provided for @weekPlanEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет запланированных тренировок'**
  String get weekPlanEmpty;

  /// No description provided for @weekPlanHint.
  ///
  /// In ru, this message translates to:
  /// **'Привяжите дни программы к дням недели в конструкторе, чтобы они появились в плане'**
  String get weekPlanHint;

  /// No description provided for @weekPlanPrevWeek.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущая неделя'**
  String get weekPlanPrevWeek;

  /// No description provided for @weekPlanNextWeek.
  ///
  /// In ru, this message translates to:
  /// **'Следующая неделя'**
  String get weekPlanNextWeek;

  /// No description provided for @weekPlanQuickStart.
  ///
  /// In ru, this message translates to:
  /// **'Быстрый старт'**
  String get weekPlanQuickStart;

  /// No description provided for @programBuilderDayOfWeek.
  ///
  /// In ru, this message translates to:
  /// **'Привязка к дню недели'**
  String get programBuilderDayOfWeek;

  /// No description provided for @muscleAbs.
  ///
  /// In ru, this message translates to:
  /// **'Пресс'**
  String get muscleAbs;

  /// No description provided for @muscleObliques.
  ///
  /// In ru, this message translates to:
  /// **'Косые'**
  String get muscleObliques;

  /// No description provided for @muscleChest.
  ///
  /// In ru, this message translates to:
  /// **'Грудь'**
  String get muscleChest;

  /// No description provided for @muscleShoulders.
  ///
  /// In ru, this message translates to:
  /// **'Плечи'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In ru, this message translates to:
  /// **'Бицепс'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In ru, this message translates to:
  /// **'Трицепс'**
  String get muscleTriceps;

  /// No description provided for @muscleForearms.
  ///
  /// In ru, this message translates to:
  /// **'Предплечья'**
  String get muscleForearms;

  /// No description provided for @muscleTraps.
  ///
  /// In ru, this message translates to:
  /// **'Трапеции'**
  String get muscleTraps;

  /// No description provided for @muscleLats.
  ///
  /// In ru, this message translates to:
  /// **'Широчайшие'**
  String get muscleLats;

  /// No description provided for @muscleLowerBack.
  ///
  /// In ru, this message translates to:
  /// **'Поясница'**
  String get muscleLowerBack;

  /// No description provided for @muscleGlutes.
  ///
  /// In ru, this message translates to:
  /// **'Ягодицы'**
  String get muscleGlutes;

  /// No description provided for @muscleQuads.
  ///
  /// In ru, this message translates to:
  /// **'Квадрицепсы'**
  String get muscleQuads;

  /// No description provided for @muscleHamstrings.
  ///
  /// In ru, this message translates to:
  /// **'Бицепс бедра'**
  String get muscleHamstrings;

  /// No description provided for @muscleCalves.
  ///
  /// In ru, this message translates to:
  /// **'Икры'**
  String get muscleCalves;

  /// No description provided for @muscleNeck.
  ///
  /// In ru, this message translates to:
  /// **'Шея'**
  String get muscleNeck;

  /// No description provided for @errorNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Страница не найдена'**
  String get errorNotFound;

  /// No description provided for @exerciseNew.
  ///
  /// In ru, this message translates to:
  /// **'Новое упражнение'**
  String get exerciseNew;

  /// No description provided for @exerciseEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование упражнения'**
  String get exerciseEdit;

  /// No description provided for @exerciseDetail.
  ///
  /// In ru, this message translates to:
  /// **'Упражнение'**
  String get exerciseDetail;

  /// No description provided for @exerciseDetailNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Упражнение не найдено'**
  String get exerciseDetailNotFound;

  /// No description provided for @exerciseDetailDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get exerciseDetailDescription;

  /// No description provided for @exerciseDetailTechnique.
  ///
  /// In ru, this message translates to:
  /// **'Техника выполнения'**
  String get exerciseDetailTechnique;

  /// No description provided for @exerciseDetailMistakes.
  ///
  /// In ru, this message translates to:
  /// **'Частые ошибки'**
  String get exerciseDetailMistakes;

  /// No description provided for @exerciseDetailMuscles.
  ///
  /// In ru, this message translates to:
  /// **'Задействованные мышцы'**
  String get exerciseDetailMuscles;

  /// No description provided for @exerciseDetailHistoryRecent.
  ///
  /// In ru, this message translates to:
  /// **'История за последние 3 дня'**
  String get exerciseDetailHistoryRecent;

  /// Подтверждение удаления упражнения
  ///
  /// In ru, this message translates to:
  /// **'Удалить упражнение «{name}»?'**
  String exerciseDetailDeleteConfirm(String name);

  /// Заголовок диалога при попытке удалить упражнение, используемое в программах
  ///
  /// In ru, this message translates to:
  /// **'Нельзя удалить «{name}»'**
  String exerciseDetailDeleteBlocked(String name);

  /// Пояснение в диалоге блокировки удаления упражнения
  ///
  /// In ru, this message translates to:
  /// **'Упражнение используется в программах:'**
  String get exerciseDetailDeleteBlockedHint;

  /// No description provided for @exerciseFormName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get exerciseFormName;

  /// No description provided for @exerciseFormType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get exerciseFormType;

  /// No description provided for @exerciseFormDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get exerciseFormDescription;

  /// No description provided for @exerciseFormTechnique.
  ///
  /// In ru, this message translates to:
  /// **'Техника выполнения'**
  String get exerciseFormTechnique;

  /// No description provided for @exerciseFormMistakes.
  ///
  /// In ru, this message translates to:
  /// **'Частые ошибки'**
  String get exerciseFormMistakes;

  /// No description provided for @exerciseFormMistakeAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить ошибку'**
  String get exerciseFormMistakeAdd;

  /// No description provided for @exerciseFormMuscles.
  ///
  /// In ru, this message translates to:
  /// **'Задействованные мышцы'**
  String get exerciseFormMuscles;

  /// No description provided for @exerciseFormMusclesRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите хотя бы одну мышцу'**
  String get exerciseFormMusclesRequired;

  /// No description provided for @exerciseFormMusclePrimary.
  ///
  /// In ru, this message translates to:
  /// **'Основная'**
  String get exerciseFormMusclePrimary;

  /// No description provided for @exerciseFormMuscleSecondary.
  ///
  /// In ru, this message translates to:
  /// **'Вспомогательная'**
  String get exerciseFormMuscleSecondary;

  /// No description provided for @exerciseFormContraindications.
  ///
  /// In ru, this message translates to:
  /// **'Противопоказания'**
  String get exerciseFormContraindications;

  /// No description provided for @exerciseFormAnimation.
  ///
  /// In ru, this message translates to:
  /// **'Изображение'**
  String get exerciseFormAnimation;

  /// No description provided for @exerciseFormAnimationPick.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать изображение'**
  String get exerciseFormAnimationPick;

  /// No description provided for @exerciseFormAnimationRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать изображение'**
  String get exerciseFormAnimationRemove;

  /// No description provided for @exerciseFormAnimationError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить файл. Попробуйте ещё раз.'**
  String get exerciseFormAnimationError;

  /// No description provided for @exerciseFormThumbnail.
  ///
  /// In ru, this message translates to:
  /// **'Миниатюра'**
  String get exerciseFormThumbnail;

  /// No description provided for @exerciseFormThumbnailPick.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать миниатюру'**
  String get exerciseFormThumbnailPick;

  /// No description provided for @exerciseFormThumbnailRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать миниатюру'**
  String get exerciseFormThumbnailRemove;

  /// No description provided for @exerciseFormMediaInfo.
  ///
  /// In ru, this message translates to:
  /// **'Форматы: jpg, png, webp, gif. Максимум: 5 МБ'**
  String get exerciseFormMediaInfo;

  /// No description provided for @exerciseFormNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get exerciseFormNameRequired;

  /// No description provided for @exerciseFormSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get exerciseFormSave;

  /// No description provided for @exerciseFormHideOptional.
  ///
  /// In ru, this message translates to:
  /// **'Скрывать необязательные поля в тренировке'**
  String get exerciseFormHideOptional;

  /// No description provided for @exerciseFormHideOptionalHelp.
  ///
  /// In ru, this message translates to:
  /// **'Описание, техника и параметры не будут показываться при выполнении'**
  String get exerciseFormHideOptionalHelp;

  /// No description provided for @exerciseFormFixedWeight.
  ///
  /// In ru, this message translates to:
  /// **'Фиксированный вес'**
  String get exerciseFormFixedWeight;

  /// No description provided for @exerciseFormFixedWeightHelp.
  ///
  /// In ru, this message translates to:
  /// **'Вес будет подставляться из параметров тренировки, но его можно изменить'**
  String get exerciseFormFixedWeightHelp;

  /// No description provided for @exerciseFormPerSide.
  ///
  /// In ru, this message translates to:
  /// **'Выполнение по сторонам (левая/правая)'**
  String get exerciseFormPerSide;

  /// No description provided for @exerciseFormPerSideHelp.
  ///
  /// In ru, this message translates to:
  /// **'Каждый подход выполняется на обе стороны с отдыхом между ними'**
  String get exerciseFormPerSideHelp;

  /// No description provided for @exerciseParams.
  ///
  /// In ru, this message translates to:
  /// **'Параметры упражнения'**
  String get exerciseParams;

  /// No description provided for @programNew.
  ///
  /// In ru, this message translates to:
  /// **'Новая программа'**
  String get programNew;

  /// No description provided for @programEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование программы'**
  String get programEdit;

  /// No description provided for @programListEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Список программ пуст'**
  String get programListEmpty;

  /// No description provided for @programListCreate.
  ///
  /// In ru, this message translates to:
  /// **'Новая программа'**
  String get programListCreate;

  /// No description provided for @programMakeActive.
  ///
  /// In ru, this message translates to:
  /// **'Сделать активной'**
  String get programMakeActive;

  /// No description provided for @programActivatePrompt.
  ///
  /// In ru, this message translates to:
  /// **'Сделать программу активной?'**
  String get programActivatePrompt;

  /// No description provided for @programActive.
  ///
  /// In ru, this message translates to:
  /// **'Активная'**
  String get programActive;

  /// No description provided for @programDeactivate.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать'**
  String get programDeactivate;

  /// No description provided for @programCopyJson.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать JSON'**
  String get programCopyJson;

  /// No description provided for @copyJsonCopied.
  ///
  /// In ru, this message translates to:
  /// **'JSON скопирован в буфер обмена'**
  String get copyJsonCopied;

  /// No description provided for @copyJsonNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скопировать JSON'**
  String get copyJsonNotFound;

  /// Подтверждение удаления программы
  ///
  /// In ru, this message translates to:
  /// **'Удалить программу «{name}»?'**
  String programDeleteConfirm(String name);

  /// Количество дней в программе
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{1 день} few{{count} дня} other{{count} дней}}'**
  String programDaysCount(int count);

  /// Количество упражнений в программе
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{1 упражнение} few{{count} упражнения} other{{count} упражнений}}'**
  String programExercisesCount(int count);

  /// No description provided for @weekdayMon.
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get weekdaySun;

  /// No description provided for @programBuilderName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get programBuilderName;

  /// No description provided for @programBuilderNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get programBuilderNameRequired;

  /// No description provided for @programBuilderDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get programBuilderDescription;

  /// No description provided for @programBuilderDaysCount.
  ///
  /// In ru, this message translates to:
  /// **'Количество дней'**
  String get programBuilderDaysCount;

  /// Заголовок тренировочного дня в конструкторе
  ///
  /// In ru, this message translates to:
  /// **'День {index}'**
  String programBuilderDay(int index);

  /// No description provided for @programBuilderDayNoWeekday.
  ///
  /// In ru, this message translates to:
  /// **'Без привязки'**
  String get programBuilderDayNoWeekday;

  /// No description provided for @programBuilderDayWeekday.
  ///
  /// In ru, this message translates to:
  /// **'День недели'**
  String get programBuilderDayWeekday;

  /// No description provided for @programBuilderDaySettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройка дня'**
  String get programBuilderDaySettings;

  /// No description provided for @programBuilderWarmupMinutes.
  ///
  /// In ru, this message translates to:
  /// **'Разминка, мин'**
  String get programBuilderWarmupMinutes;

  /// Короткая подпись разминки в тайле дня
  ///
  /// In ru, this message translates to:
  /// **'разминка {minutes} мин'**
  String programBuilderWarmupShort(int minutes);

  /// No description provided for @reminderToggle.
  ///
  /// In ru, this message translates to:
  /// **'Напоминать'**
  String get reminderToggle;

  /// No description provided for @reminderTime.
  ///
  /// In ru, this message translates to:
  /// **'Время напоминания'**
  String get reminderTime;

  /// No description provided for @programBuilderSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get programBuilderSave;

  /// Кнопка перехода к заполнению следующего незаполненного дня
  ///
  /// In ru, this message translates to:
  /// **'Заполнить день {dayNumber}'**
  String programBuilderFillNextDay(int dayNumber);

  /// No description provided for @programBuilderAddExercise.
  ///
  /// In ru, this message translates to:
  /// **'Добавить упражнение'**
  String get programBuilderAddExercise;

  /// No description provided for @programBuilderCopyDay.
  ///
  /// In ru, this message translates to:
  /// **'Копировать день'**
  String get programBuilderCopyDay;

  /// No description provided for @programBuilderPickExercise.
  ///
  /// In ru, this message translates to:
  /// **'Выберите упражнение'**
  String get programBuilderPickExercise;

  /// No description provided for @programBuilderMainSet.
  ///
  /// In ru, this message translates to:
  /// **'Основной набор'**
  String get programBuilderMainSet;

  /// No description provided for @programBuilderAlternativeSet.
  ///
  /// In ru, this message translates to:
  /// **'Альтернативный набор'**
  String get programBuilderAlternativeSet;

  /// No description provided for @programBuilderMuscles.
  ///
  /// In ru, this message translates to:
  /// **'Задействованные мышцы'**
  String get programBuilderMuscles;

  /// No description provided for @programBuilderMuscleFilter.
  ///
  /// In ru, this message translates to:
  /// **'Мышцы'**
  String get programBuilderMuscleFilter;

  /// No description provided for @programBuilderTypeFilter.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get programBuilderTypeFilter;

  /// No description provided for @programBuilderEmptyDay.
  ///
  /// In ru, this message translates to:
  /// **'В этом дне пока нет упражнений'**
  String get programBuilderEmptyDay;

  /// Прогресс наполнения программы упражнениями
  ///
  /// In ru, this message translates to:
  /// **'Заполнено {filled} из {total} дней'**
  String programBuilderDayProgress(int filled, int total);

  /// No description provided for @programBuilderMetricsInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Укажите параметры упражнения перед сохранением'**
  String get programBuilderMetricsInvalid;

  /// No description provided for @programValidationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно данных для сохранения'**
  String get programValidationTitle;

  /// No description provided for @programValidationMessage.
  ///
  /// In ru, this message translates to:
  /// **'Заполните недостающее:'**
  String get programValidationMessage;

  /// No description provided for @programValidationContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить редактирование'**
  String get programValidationContinue;

  /// No description provided for @programValidationExit.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get programValidationExit;

  /// No description provided for @programBuilderNoMetrics.
  ///
  /// In ru, this message translates to:
  /// **'Параметры не заданы'**
  String get programBuilderNoMetrics;

  /// No description provided for @exerciseParamsSets.
  ///
  /// In ru, this message translates to:
  /// **'Подходы'**
  String get exerciseParamsSets;

  /// No description provided for @exerciseParamsReps.
  ///
  /// In ru, this message translates to:
  /// **'Повторения'**
  String get exerciseParamsReps;

  /// No description provided for @exerciseParamsWeightKg.
  ///
  /// In ru, this message translates to:
  /// **'Вес (кг)'**
  String get exerciseParamsWeightKg;

  /// No description provided for @exerciseParamsDurationSeconds.
  ///
  /// In ru, this message translates to:
  /// **'Время (сек)'**
  String get exerciseParamsDurationSeconds;

  /// No description provided for @exerciseParamsDurationMinutes.
  ///
  /// In ru, this message translates to:
  /// **'Время (мин)'**
  String get exerciseParamsDurationMinutes;

  /// No description provided for @exerciseParamsDistanceKm.
  ///
  /// In ru, this message translates to:
  /// **'Дистанция (км)'**
  String get exerciseParamsDistanceKm;

  /// No description provided for @exerciseParamsRestSeconds.
  ///
  /// In ru, this message translates to:
  /// **'Отдых (сек)'**
  String get exerciseParamsRestSeconds;

  /// No description provided for @exerciseParamsRequired.
  ///
  /// In ru, this message translates to:
  /// **'Заполните поле'**
  String get exerciseParamsRequired;

  /// No description provided for @exerciseParamsPositive.
  ///
  /// In ru, this message translates to:
  /// **'Значение должно быть больше нуля'**
  String get exerciseParamsPositive;

  /// No description provided for @exerciseParamsNotNegative.
  ///
  /// In ru, this message translates to:
  /// **'Значение не может быть отрицательным'**
  String get exerciseParamsNotNegative;

  /// No description provided for @exerciseParamsHoldHint.
  ///
  /// In ru, this message translates to:
  /// **'Пусто — время удержания со счётчика'**
  String get exerciseParamsHoldHint;

  /// No description provided for @workoutPrepare.
  ///
  /// In ru, this message translates to:
  /// **'Подготовка к тренировке'**
  String get workoutPrepare;

  /// No description provided for @workoutRun.
  ///
  /// In ru, this message translates to:
  /// **'Тренировка'**
  String get workoutRun;

  /// No description provided for @workoutWakelockWarning.
  ///
  /// In ru, this message translates to:
  /// **'Экран может выключаться во время тренировки — блокировка сна недоступна на этой платформе.'**
  String get workoutWakelockWarning;

  /// No description provided for @workoutPrepareStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать тренировку'**
  String get workoutPrepareStart;

  /// No description provided for @workoutWarmup.
  ///
  /// In ru, this message translates to:
  /// **'Разминка'**
  String get workoutWarmup;

  /// No description provided for @workoutWarmupDone.
  ///
  /// In ru, this message translates to:
  /// **'Разминка завершена'**
  String get workoutWarmupDone;

  /// No description provided for @workoutWarmupSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get workoutWarmupSkip;

  /// Оставшееся время разминки
  ///
  /// In ru, this message translates to:
  /// **'осталось {seconds} с'**
  String workoutWarmupSecondsLeft(int seconds);

  /// No description provided for @workoutWarmupStartWorkout.
  ///
  /// In ru, this message translates to:
  /// **'Начать тренировку'**
  String get workoutWarmupStartWorkout;

  /// No description provided for @workoutPrepareNotFound.
  ///
  /// In ru, this message translates to:
  /// **'День не найден'**
  String get workoutPrepareNotFound;

  /// Время отдыха в карточке упражнения подготовки
  ///
  /// In ru, this message translates to:
  /// **'Отдых {seconds} с'**
  String workoutPrepareRest(int seconds);

  /// No description provided for @workoutUnitReps.
  ///
  /// In ru, this message translates to:
  /// **'повт'**
  String get workoutUnitReps;

  /// No description provided for @workoutUnitSeconds.
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get workoutUnitSeconds;

  /// No description provided for @workoutUnitMinutes.
  ///
  /// In ru, this message translates to:
  /// **'мин'**
  String get workoutUnitMinutes;

  /// No description provided for @workoutUnitKg.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get workoutUnitKg;

  /// No description provided for @workoutUnitKm.
  ///
  /// In ru, this message translates to:
  /// **'км'**
  String get workoutUnitKm;

  /// No description provided for @workoutRunLastWorkout.
  ///
  /// In ru, this message translates to:
  /// **'Последняя тренировка'**
  String get workoutRunLastWorkout;

  /// Счётчик упражнений во время тренировки
  ///
  /// In ru, this message translates to:
  /// **'Упражнение {current} из {total}'**
  String workoutRunExerciseOf(int current, int total);

  /// Счётчик подходов текущего упражнения
  ///
  /// In ru, this message translates to:
  /// **'Подход {current} из {total}'**
  String workoutRunSetOf(int current, int total);

  /// No description provided for @workoutRunApproachDone.
  ///
  /// In ru, this message translates to:
  /// **'Подход выполнен'**
  String get workoutRunApproachDone;

  /// No description provided for @workoutRunRest.
  ///
  /// In ru, this message translates to:
  /// **'Отдых'**
  String get workoutRunRest;

  /// No description provided for @workoutRunSkipRest.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить отдых'**
  String get workoutRunSkipRest;

  /// No description provided for @workoutRunSideRest.
  ///
  /// In ru, this message translates to:
  /// **'Отдых между сторонами'**
  String get workoutRunSideRest;

  /// No description provided for @workoutSideLeft.
  ///
  /// In ru, this message translates to:
  /// **'левая'**
  String get workoutSideLeft;

  /// No description provided for @workoutSideRight.
  ///
  /// In ru, this message translates to:
  /// **'правая'**
  String get workoutSideRight;

  /// No description provided for @workoutRunFinish.
  ///
  /// In ru, this message translates to:
  /// **'Завершить тренировку'**
  String get workoutRunFinish;

  /// No description provided for @workoutRunFinished.
  ///
  /// In ru, this message translates to:
  /// **'Тренировка завершена'**
  String get workoutRunFinished;

  /// Текущее время удержания планки
  ///
  /// In ru, this message translates to:
  /// **'Удержание {seconds} с'**
  String workoutRunHold(int seconds);

  /// Целевая длительность удержания планки
  ///
  /// In ru, this message translates to:
  /// **'Цель: {seconds} с'**
  String workoutRunHoldTarget(int seconds);

  /// Кнопка запуска отсчёта удержания планки
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get workoutRunHoldStart;

  /// No description provided for @workoutRunExitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из тренировки?'**
  String get workoutRunExitTitle;

  /// No description provided for @workoutRunExitBody.
  ///
  /// In ru, this message translates to:
  /// **'Тренировка не будет сохранена. Выйти?'**
  String get workoutRunExitBody;

  /// No description provided for @workoutRunExit.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get workoutRunExit;

  /// No description provided for @workoutRunFinishEarly.
  ///
  /// In ru, this message translates to:
  /// **'Завершить и сохранить'**
  String get workoutRunFinishEarly;

  /// Длительность завершённой тренировки
  ///
  /// In ru, this message translates to:
  /// **'Время: {minutes} мин'**
  String workoutRunTime(int minutes);

  /// Количество выполненных подходов
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{1 подход} few{{count} подхода} other{{count} подходов}}'**
  String workoutRunSetsCount(int count);

  /// No description provided for @workoutRunSaved.
  ///
  /// In ru, this message translates to:
  /// **'Тренировка сохранена'**
  String get workoutRunSaved;

  /// No description provided for @workoutRunGoProgress.
  ///
  /// In ru, this message translates to:
  /// **'К прогрессу'**
  String get workoutRunGoProgress;

  /// No description provided for @workoutRunExercises.
  ///
  /// In ru, this message translates to:
  /// **'Упражнения'**
  String get workoutRunExercises;

  /// No description provided for @workoutRunMuscles.
  ///
  /// In ru, this message translates to:
  /// **'Задействованные мышцы'**
  String get workoutRunMuscles;

  /// No description provided for @workoutRunEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В этом дне нет упражнений'**
  String get workoutRunEmpty;

  /// No description provided for @progressPeriodWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get progressPeriodWeek;

  /// No description provided for @progressPeriodMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get progressPeriodMonth;

  /// No description provided for @progressPeriodYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get progressPeriodYear;

  /// No description provided for @progressWorkouts.
  ///
  /// In ru, this message translates to:
  /// **'Тренировок'**
  String get progressWorkouts;

  /// No description provided for @progressDistance.
  ///
  /// In ru, this message translates to:
  /// **'Дистанция'**
  String get progressDistance;

  /// No description provided for @progressPlankTime.
  ///
  /// In ru, this message translates to:
  /// **'Время планки'**
  String get progressPlankTime;

  /// No description provided for @progressWorkoutsChart.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки по срезам'**
  String get progressWorkoutsChart;

  /// No description provided for @progressMetricChart.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс метрики'**
  String get progressMetricChart;

  /// No description provided for @progressMuscleLoad.
  ///
  /// In ru, this message translates to:
  /// **'Нагрузка на мышцы'**
  String get progressMuscleLoad;

  /// No description provided for @progressEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет тренировок за период'**
  String get progressEmpty;

  /// No description provided for @progressProgression.
  ///
  /// In ru, this message translates to:
  /// **'Динамика упражнения'**
  String get progressProgression;

  /// No description provided for @progressProgressionOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть динамику'**
  String get progressProgressionOpen;

  /// No description provided for @progressProgressionEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Ещё нет тренировок с этим упражнением'**
  String get progressProgressionEmpty;

  /// No description provided for @progressProgressionMax.
  ///
  /// In ru, this message translates to:
  /// **'Максимум'**
  String get progressProgressionMax;

  /// No description provided for @progressDayDetail.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки за день'**
  String get progressDayDetail;

  /// No description provided for @progressDayEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет тренировок за этот день'**
  String get progressDayEmpty;

  /// No description provided for @monthShortJan.
  ///
  /// In ru, this message translates to:
  /// **'Янв'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In ru, this message translates to:
  /// **'Фев'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In ru, this message translates to:
  /// **'Мар'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In ru, this message translates to:
  /// **'Апр'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In ru, this message translates to:
  /// **'Май'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In ru, this message translates to:
  /// **'Июн'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In ru, this message translates to:
  /// **'Июл'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In ru, this message translates to:
  /// **'Авг'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In ru, this message translates to:
  /// **'Сен'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In ru, this message translates to:
  /// **'Окт'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In ru, this message translates to:
  /// **'Ноя'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In ru, this message translates to:
  /// **'Дек'**
  String get monthShortDec;

  /// No description provided for @history.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get history;

  /// No description provided for @historyDetail.
  ///
  /// In ru, this message translates to:
  /// **'Детали тренировки'**
  String get historyDetail;

  /// No description provided for @historyEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет тренировок'**
  String get historyEmpty;

  /// No description provided for @historySessionNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Тренировка не найдена'**
  String get historySessionNotFound;

  /// No description provided for @homeActiveProgram.
  ///
  /// In ru, this message translates to:
  /// **'Активная программа'**
  String get homeActiveProgram;

  /// No description provided for @homeUpcomingDay.
  ///
  /// In ru, this message translates to:
  /// **'Ближайший день'**
  String get homeUpcomingDay;

  /// No description provided for @homeUpcomingDayNotAssigned.
  ///
  /// In ru, this message translates to:
  /// **'не назначен'**
  String get homeUpcomingDayNotAssigned;

  /// No description provided for @homeRecentWorkouts.
  ///
  /// In ru, this message translates to:
  /// **'Последние тренировки'**
  String get homeRecentWorkouts;

  /// No description provided for @homeNoProgramsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет программ'**
  String get homeNoProgramsTitle;

  /// No description provided for @homeNoProgramsHint.
  ///
  /// In ru, this message translates to:
  /// **'Создайте программу тренировок, чтобы видеть её здесь.'**
  String get homeNoProgramsHint;

  /// No description provided for @homeGoToPrograms.
  ///
  /// In ru, this message translates to:
  /// **'К программам'**
  String get homeGoToPrograms;

  /// No description provided for @homeNoActiveProgramHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите активную программу, чтобы начать тренировку.'**
  String get homeNoActiveProgramHint;

  /// No description provided for @homeNoWorkoutsHint.
  ///
  /// In ru, this message translates to:
  /// **'Выполните первую тренировку — она появится здесь.'**
  String get homeNoWorkoutsHint;

  /// No description provided for @homeViewAll.
  ///
  /// In ru, this message translates to:
  /// **'Вся история'**
  String get homeViewAll;

  /// No description provided for @homeGoToHistory.
  ///
  /// In ru, this message translates to:
  /// **'К истории'**
  String get homeGoToHistory;

  /// No description provided for @historyCopyJson.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать JSON'**
  String get historyCopyJson;

  /// No description provided for @historyCopyJsonTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать историю в JSON'**
  String get historyCopyJsonTooltip;

  /// Количество упражнений в сессии истории
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{1 упражнение} few{{count} упражнения} other{{count} упражнений}}'**
  String historyExercisesCount(int count);

  /// Длительность сессии в истории
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String historyDuration(int minutes);

  /// No description provided for @sync.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация'**
  String get sync;

  /// No description provided for @syncCloudHint.
  ///
  /// In ru, this message translates to:
  /// **'Переносите данные между устройствами через файл резервной копии базы данных.'**
  String get syncCloudHint;

  /// No description provided for @syncCloudComing.
  ///
  /// In ru, this message translates to:
  /// **'Облачная синхронизация появится позже.'**
  String get syncCloudComing;

  /// No description provided for @syncShare.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get syncShare;

  /// No description provided for @syncSaveFile.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить в файлы'**
  String get syncSaveFile;

  /// No description provided for @syncImport.
  ///
  /// In ru, this message translates to:
  /// **'Импортировать БД'**
  String get syncImport;

  /// No description provided for @syncImportSuccess.
  ///
  /// In ru, this message translates to:
  /// **'База данных импортирована'**
  String get syncImportSuccess;

  /// No description provided for @syncRestartHint.
  ///
  /// In ru, this message translates to:
  /// **'Для полного применения изменений приложение будет перезапущено.'**
  String get syncRestartHint;

  /// No description provided for @syncImportWarningTitle.
  ///
  /// In ru, this message translates to:
  /// **'Импорт базы данных'**
  String get syncImportWarningTitle;

  /// No description provided for @syncImportWarningBody.
  ///
  /// In ru, this message translates to:
  /// **'Все текущие данные будут перезаписаны. Это действие необратимо.'**
  String get syncImportWarningBody;

  /// No description provided for @syncImportConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Согласен'**
  String get syncImportConfirm;

  /// No description provided for @contraindications.
  ///
  /// In ru, this message translates to:
  /// **'Противопоказания'**
  String get contraindications;

  /// No description provided for @contraindicationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Моё здоровье'**
  String get contraindicationsTitle;

  /// No description provided for @contraindicationsHint.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте свои противопоказания. Упражнения с ними будут отмечены предупреждением.'**
  String get contraindicationsHint;

  /// No description provided for @contraindicationsSaved.
  ///
  /// In ru, this message translates to:
  /// **'Настройки сохранены'**
  String get contraindicationsSaved;

  /// No description provided for @contraindicationWarningForYou.
  ///
  /// In ru, this message translates to:
  /// **'Есть противопоказания для вас'**
  String get contraindicationWarningForYou;

  /// No description provided for @workoutWarningsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Противопоказания'**
  String get workoutWarningsTitle;

  /// No description provided for @workoutWarningsBody.
  ///
  /// In ru, this message translates to:
  /// **'В программе есть упражнения с противопоказаниями:'**
  String get workoutWarningsBody;

  /// No description provided for @workoutWarningsProceed.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get workoutWarningsProceed;

  /// No description provided for @workoutWarningsDontShow.
  ///
  /// In ru, this message translates to:
  /// **'Больше не показывать для этой программы'**
  String get workoutWarningsDontShow;

  /// No description provided for @contraindicationDescKnees.
  ///
  /// In ru, this message translates to:
  /// **'Избегайте приседаний и прыжков.'**
  String get contraindicationDescKnees;

  /// No description provided for @contraindicationDescBack.
  ///
  /// In ru, this message translates to:
  /// **'Избегайте осевых нагрузок на позвоночник.'**
  String get contraindicationDescBack;

  /// No description provided for @contraindicationDescNeck.
  ///
  /// In ru, this message translates to:
  /// **'Избегайте нагрузки на шейный отдел.'**
  String get contraindicationDescNeck;

  /// No description provided for @contraindicationDescShoulders.
  ///
  /// In ru, this message translates to:
  /// **'Избегайте жимов и махов над головой.'**
  String get contraindicationDescShoulders;

  /// No description provided for @contraindicationDescElbows.
  ///
  /// In ru, this message translates to:
  /// **'Избегайте ударной нагрузки на локти.'**
  String get contraindicationDescElbows;

  /// No description provided for @contraindicationDescWrists.
  ///
  /// In ru, this message translates to:
  /// **'Избегайте упоров и отжиманий на запястьях.'**
  String get contraindicationDescWrists;

  /// No description provided for @contraindicationDescHeart.
  ///
  /// In ru, this message translates to:
  /// **'Проконсультируйтесь с врачом перед тренировками.'**
  String get contraindicationDescHeart;

  /// No description provided for @contraindicationDescPregnancy.
  ///
  /// In ru, this message translates to:
  /// **'Умеренные нагрузки, без упражнений на пресс.'**
  String get contraindicationDescPregnancy;

  /// No description provided for @profileCurrentValues.
  ///
  /// In ru, this message translates to:
  /// **'Текущие значения'**
  String get profileCurrentValues;

  /// No description provided for @profileMetricChart.
  ///
  /// In ru, this message translates to:
  /// **'Динамика'**
  String get profileMetricChart;

  /// No description provided for @profileMeasurementsHistory.
  ///
  /// In ru, this message translates to:
  /// **'История замеров'**
  String get profileMeasurementsHistory;

  /// No description provided for @profileYearFilter.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get profileYearFilter;

  /// No description provided for @profileYearAll.
  ///
  /// In ru, this message translates to:
  /// **'Все годы'**
  String get profileYearAll;

  /// No description provided for @profileEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет замеров тела'**
  String get profileEmpty;

  /// No description provided for @profileChartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте замеры, чтобы увидеть динамику'**
  String get profileChartEmpty;

  /// No description provided for @profileAddMeasurement.
  ///
  /// In ru, this message translates to:
  /// **'Добавить замер'**
  String get profileAddMeasurement;

  /// No description provided for @profileDeleteMeasurementConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить замер?'**
  String get profileDeleteMeasurementConfirm;

  /// No description provided for @profileUnitCm.
  ///
  /// In ru, this message translates to:
  /// **'см'**
  String get profileUnitCm;

  /// No description provided for @measurementFormTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый замер'**
  String get measurementFormTitle;

  /// No description provided for @measurementFormDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get measurementFormDate;

  /// No description provided for @measurementFormNumberError.
  ///
  /// In ru, this message translates to:
  /// **'Введите число'**
  String get measurementFormNumberError;

  /// No description provided for @updateCheckErrorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка проверки версии. Проверьте подключение к интернету.'**
  String get updateCheckErrorNetwork;

  /// No description provided for @updateCheckError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка проверки версии.'**
  String get updateCheckError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
