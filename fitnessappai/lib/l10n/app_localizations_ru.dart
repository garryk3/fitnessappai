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
  String get commonDelete => 'Удалить';

  @override
  String get commonEdit => 'Редактировать';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get exerciseTypeStrength => 'Силовые';

  @override
  String get exerciseTypePlank => 'Планка';

  @override
  String get exerciseTypeRunning => 'Бег';

  @override
  String get schedulePerformed => 'Выполнено';

  @override
  String get scheduleRescheduled => 'Перенесено';

  @override
  String get scheduleSkipped => 'Пропущено';

  @override
  String get schedulePending => 'Запланировано';

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
}
