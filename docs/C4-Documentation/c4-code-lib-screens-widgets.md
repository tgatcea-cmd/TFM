# C4 Code-Level Documentation: `lib/screens/widgets`

## 1. Overview Section
- **Name**: Core UI Widgets
- **Description**: Reusable presentation components that display specialized domain data across different screens.
- **Location**: `lib/screens/widgets`
- **Language**: Dart
- **Purpose**: Provides encapsulated UI fragments, such as the `InferenceCard`, which translate raw ML logic responses into user-friendly graphical alerts.

## 2. Code Elements Section

### Classes

#### `InferenceCard`
- **Description**: A stateless widget designed to visually present AI irrigation recommendations and predictions using localized strings. It color-codes the output based on urgency and irrigation restrictions.
- **Location**: `lib/screens/widgets/inference_card.dart`
- **Dependencies**: `flutter/material.dart`, localized strings, utility date formatters.
- **Methods**:
  - `const InferenceCard({super.key, required this.data, required this.l10n, this.formatDate})`: Constructor accepting the payload map and localization context.
  - `String _translateVerdict(String v, AppLocalizations l10n)`: Translates internal verdict strings to localized user-facing copy.
  - `String _defaultFormatDate(int ms)`: Formats timestamps correctly if no custom formatter is provided.
  - `Widget build(BuildContext context)`: Main render method handling the conditional layout for "No Data", "Restricted", "Irrigation Needed", and "Irrigation Avoidable" states.

## 3. Dependencies Section
- **Internal dependencies**:
  - Requires localized string dictionaries and general app styling constants (`AppStyles`).
- **External dependencies**:
  - `flutter/material.dart` for rendering.

## 4. Relationships Section
Used heavily in `home_screen.dart` to summarize the result of the ML Inference pipelines (`InferenceBridge`) to the end user.
