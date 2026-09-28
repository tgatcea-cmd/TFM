# C4 Code-Level Documentation: Core Theme

## 1. Overview Section
- **Name:** Core Theme Module (`lib/core/theme`)
- **Description:** Centralized styling definitions and tokens for the application. Contains colors, typography, spacing, and component themes.
- **Location:** `lib/core/theme/`
- **Language:** Dart
- **Purpose:** To provide a single source of truth for the application's visual identity, encapsulating dark theme configurations, semantic color and spacing tokens, reusable container decorations, and text styles in a cohesive and accessible way.

## 2. Code Elements Section

### Class: `AppStyles`
- **Description:** Centralized styling definitions and tokens for the application. Contains constants for colors, typography, spacing, and component themes, along with helper methods to generate complex UI decorations.
- **Location:** `lib/core/theme/app_styles.dart`
- **Dependencies:** `package:flutter/material.dart`

#### Properties (Styling Tokens)
- **Spacing Tokens (8dp Grid):** `spaceXS`, `spaceSM`, `spaceMD`, `spaceLG`, `spaceXL`
- **Semantic Color Tokens:** `consoleBackground`, `surfaceColor`, `successAccent`, `waterActionAccent`, `techSecondaryAccent`, `warningAccent`, `errorAccent`, `dividerColor`, `textSecondary`, `textMuted`, `errorDarkAccent`
- **Typography Tokens:** `consoleFontFamily`, `displayHeader`, `sectionTitle`, `bodyText`, `consoleBody`, `captionStatus`
- **Component Styles:** `destructiveButtonStyle` (Pre-configured `ButtonStyle` for destructive or high-risk actions)

#### Methods / Getters
- **Method `cardShell`**
  - **Signature:** `static BoxDecoration cardShell({bool isSelected = false, Color borderAccent = dividerColor})`
  - **Description:** Creates a standard card decoration with an optional selection state. `isSelected` highlights the border with `successAccent` when true. `borderAccent` defines the default border color when not selected.
  - **Location:** `lib/core/theme/app_styles.dart`
  - **Dependencies:** Flutter Framework (`BoxDecoration`, `Color`, `BorderRadius`, `Border`)

- **Method `aiRecommendationCard`**
  - **Signature:** `static BoxDecoration aiRecommendationCard(Color stateAccent)`
  - **Description:** Creates a specialized card decoration for AI recommendations. Uses `stateAccent` to define the background and border color scheme, typically reflecting the urgency or status of the recommendation.
  - **Location:** `lib/core/theme/app_styles.dart`
  - **Dependencies:** Flutter Framework (`BoxDecoration`, `Color`, `BorderRadius`, `Border`)

- **Getter `darkTheme`**
  - **Signature:** `static ThemeData get darkTheme`
  - **Description:** Provides the global dark theme configuration for the application. Includes color schemes, text themes, navigation rail themes, card themes, and component styles.
  - **Location:** `lib/core/theme/app_styles.dart`
  - **Dependencies:** Flutter Framework (`ThemeData`, `ColorScheme`, `TextTheme`, `NavigationRailThemeData`, `ElevatedButtonThemeData`, `CardThemeData`)

## 3. Dependencies Section
- **Internal Dependencies:**
  - None. The theme module sits at the foundational core of the architecture and relies on no other internal modules.
- **External Dependencies:**
  - `package:flutter/material.dart`: Flutter UI toolkit and material design library. Used to define UI tokens, colors, themes, text styles, and layout elements.

## 4. Relationships Section
- **Incoming Dependencies:** Various feature and presentation layers across the application import and depend on `AppStyles` (e.g., `AppStyles.darkTheme` for the root `MaterialApp`, `AppStyles.cardShell()` for custom widgets, and semantic tokens for raw styling). 
- **Outgoing Dependencies:** `AppStyles` acts as a pure configuration struct dependent entirely on the Flutter framework. It uses Material design primitives to construct its overarching design language.
