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
