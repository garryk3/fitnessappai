/// Library URI prefixes whose design-system widgets and colors are restricted
/// outside of designated directories.
///
/// Extends the original `package:flutter/` check with the standalone
/// `package:material_ui/` package (Flutter 3.50 migration): raw widgets are
/// now imported from `material_ui`, and the rules must keep matching them.
const List<String> restrictedLibraryUriPrefixes = <String>[
  'package:flutter/',
  'package:material_ui/',
];

/// Whether [libraryUri] belongs to a restricted design library.
bool isRestrictedLibraryUri(String libraryUri) => restrictedLibraryUriPrefixes
    .any((String prefix) => libraryUri.startsWith(prefix));

/// Whether an import URI (e.g. `package:material_ui/material_ui.dart`)
/// pulls a restricted design library into a compilation unit.
bool isRestrictedImportUri(String importUri) => restrictedLibraryUriPrefixes
    .any((String prefix) => importUri.startsWith(prefix));
