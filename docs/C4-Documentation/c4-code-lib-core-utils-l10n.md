# 1. Overview Section
- **Name:** App Localizations (lib/core/utils/l10n)
- **Description:** Internationalization (i18n) and localization (l10n) classes for providing multi-language support across the application. Provides string keys and translations for English and Spanish.
- **Location:** `lib/core/utils/l10n/`
- **Language:** Dart
- **Purpose:** To manage localized strings and format messages for the Terralink Dashboard application, ensuring UI elements can be dynamically translated based on the user's selected locale.

# 2. Code Elements Section

## Classes

### `AppLocalizations`
- **Description:** Abstract base class that defines all the localized strings and methods required by the application. Provides a static `of(BuildContext)` method to retrieve the appropriate localized instance.
- **Location:** `lib/core/utils/l10n/app_localizations.dart`
- **Dependencies:** 
  - `package:flutter/widgets.dart`
  - `package:flutter_localizations/flutter_localizations.dart`
  - `package:intl/intl.dart`
  - `app_localizations_en.dart`
  - `app_localizations_es.dart`
- **Methods:**
  - `static AppLocalizations? of(BuildContext context)`: Retrieves the `AppLocalizations` instance for the given context.
  - Dozens of getters and methods for translation keys (e.g., `String get appTitle`, `String statusLabel(String msg)`, `String get verdictAvoidable`, etc.).

### `AppLocalizationsEn`
- **Description:** English translation implementation of `AppLocalizations`.
- **Location:** `lib/core/utils/l10n/app_localizations_en.dart`
- **Dependencies:** 
  - `app_localizations.dart`
  - `package:intl/intl.dart`
- **Methods:**
  - Implements all abstract getters and methods from `AppLocalizations` returning English (`en`) strings.

### `AppLocalizationsEs`
- **Description:** Spanish translation implementation of `AppLocalizations`.
- **Location:** `lib/core/utils/l10n/app_localizations_es.dart`
- **Dependencies:** 
  - `app_localizations.dart`
  - `package:intl/intl.dart`
- **Methods:**
  - Implements all abstract getters and methods from `AppLocalizations` returning Spanish (`es`) strings.

# 3. Dependencies Section
- **Internal Dependencies:**
  - `AppLocalizations` references `AppLocalizationsEn` and `AppLocalizationsEs` to make them easily accessible.
- **External Dependencies:**
  - `package:flutter/foundation.dart`
  - `package:flutter/widgets.dart`
  - `package:flutter_localizations/flutter_localizations.dart`: For integrating with Flutter's localization system and delegates.
  - `package:intl/intl.dart`: For internal string canonicalization and localization utilities.

# 4. Relationships Section
- **UI Components:** Flutter widgets throughout the application rely on `AppLocalizations` to render localized text via `AppLocalizations.of(context)`.
- **Implementations:** `AppLocalizationsEn` and `AppLocalizationsEs` inherit from `AppLocalizations` and are loaded depending on the active locale.
- **`MaterialApp` Configuration:** The application's entry point requires `AppLocalizations.delegate` and `AppLocalizations.supportedLocales` in order to initialize the translation engine.
