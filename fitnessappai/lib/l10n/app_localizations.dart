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

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

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

  /// No description provided for @exerciseTypePlank.
  ///
  /// In ru, this message translates to:
  /// **'Планка'**
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

  /// Подтверждение удаления упражнения
  ///
  /// In ru, this message translates to:
  /// **'Удалить упражнение «{name}»?'**
  String exerciseDetailDeleteConfirm(String name);

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
  /// **'Анимация'**
  String get exerciseFormAnimation;

  /// No description provided for @exerciseFormAnimationPick.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать анимацию'**
  String get exerciseFormAnimationPick;

  /// No description provided for @exerciseFormAnimationRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать анимацию'**
  String get exerciseFormAnimationRemove;

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

  /// No description provided for @programBuilderSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get programBuilderSave;

  /// No description provided for @programBuilderAddExercise.
  ///
  /// In ru, this message translates to:
  /// **'Добавить упражнение'**
  String get programBuilderAddExercise;

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

  /// No description provided for @programBuilderFillAllDays.
  ///
  /// In ru, this message translates to:
  /// **'Заполните все дни программы перед сохранением'**
  String get programBuilderFillAllDays;

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

  /// No description provided for @sync.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация'**
  String get sync;

  /// No description provided for @contraindications.
  ///
  /// In ru, this message translates to:
  /// **'Противопоказания'**
  String get contraindications;
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
