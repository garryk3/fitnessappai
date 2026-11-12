import 'package:material_ui/material_ui.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';

/// Делегаты локализаций приложения (62.1, Flutter 3.50).
///
/// Локали Material/Cupertino/Widgets — из `material_ui`: после выноса
/// дизайн-библиотек в отдельный пакет виджеты ищут в контексте
/// `MaterialLocalizations` именно пакета `material_ui`, а делегаты
/// `flutter_localizations` (ген-l10n) дают framework-типы, которые
/// поиск не находит. `AppLocalizations.delegate` — собственные строки.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      ...GlobalMaterialLocalizations.delegates,
      AppLocalizations.delegate,
    ];
