# Unified UI Design System & Style Guidelines
**System Architecture & Agronomic Dashboard Visual Framework**

---

## Executive Summary & Design Vision

This document establishes the official visual and architectural style guidelines for the IoT Agronomic Dashboard (`lib/screens` & `lib/core/theme/app_styles.dart`). It resolves the historical design fragmentation by harmonizing **Domain Ergonomics** (cognitive status mapping, water-action semantics, UI scannability) with **Architectural System Discipline** (centralized tokens, strict 8dp spatial grid, component shell standardization).

By enforcing these guidelines, developers and UI designers ensure that the dashboard maintains technical rigor from the legacy Command Line Interface (CLI) while offering a fluid, modern Material 3 visual experience.

---

## I. Architectural Foundations & Token Hierarchy

To maintain code hygiene, scalable theme switching, and predictable visual output, all visual property definitions are consolidated into a single source of truth: `app_styles.dart`.

### 1. Zero-Inline-Color & Zero-Inline-Style Mandate
* **Strict Token Centralization:** Screens and individual widgets are prohibited from declaring inline colors (e.g., `Colors.greenAccent`, `Colors.yellowAccent`, `Color(0xFF1E1E1E)`), inline text styles, or ad-hoc border radii.
* **Property Reference Rule:** All design properties must be referenced directly through `AppStyles.<token>` or `Theme.of(context).colorScheme.<token>`.
* **Refactoring Metric:** Centralizing tokens into `AppStyles` eliminates ~150 lines of redundant visual code across screens while enforcing application-wide visual coherence.

### 2. The 8dp Spatial Rhythm & Layout Grid System
All margins, padding, card dimensions, container gaps, and layout offsets must strictly align with a base-8 scaling rhythm. 

| Token Name | Value | Purpose & Architectural Usage |
| :--- | :--- | :--- |
| `spaceXS` | `4.0dp` | Micro-padding inside chips, status dot offsets, tight badge gaps |
| `spaceSM` | `8.0dp` | Standard internal element spacing, card inner list gaps, icon-text spacing |
| `spaceMD` | `16.0dp` | Global screen padding, card internal container padding, primary grid gaps |
| `spaceLG` | `24.0dp` | Major visual section gaps, vertical spacing between distinct panels |
| `spaceXL` | `32.0dp` | Hero headers, main navigation tab separation, modal overlay top margins |

---

## II. Semantic Color Palette & Domain Mapping

Color serves a functional purpose: communicating hardware connectivity, network integrity, telemetry phases, and AI agronomic decisions. The system maps distinct color tokens to explicit system states.

```
       ┌─────────────────────────────────────────────────────────────────┐
       │                     SEMANTIC COLOR MAPPING                      │
       ├─────────────────┬───────────────────┬───────────────────────────┤
       │ Color Token     │ Theme Reference   │ Hardware / Domain Trigger │
       ├─────────────────┼───────────────────┼───────────────────────────┤
       │ Green Accent    │ successAccent     │ BLE Active, API 200, Safe │
       │ Blue Accent     │ waterActionAccent │ "IRRIGATE" Verdict Only   │
       │ Cyan Accent     │ techSecAccent     │ Clock Sync, Period Config │
       │ Amber Accent    │ warningAccent     │ Yellow Zone, Unsynced Dev │
       │ Red Accent      │ errorAccent       │ Override, API Fail, Clear │
       │ Dark Grey Tint  │ surfaceColor      │ Card & Panel Backgrounds  │
       └─────────────────┴───────────────────┴───────────────────────────┘
```

### Color Token Reference Table

| Semantic Token | Underlying Color Value | Domain Role & Functional Triggers | UI Component Application |
| :--- | :--- | :--- | :--- |
| `AppStyles.successAccent` | `Colors.greenAccent` (`#64FFDA` / `#00E676`) | Active BLE connections, successful API pings, synced cloud status, and **"DO NOT IRRIGATE"** AI verdicts. | Status indicators, active icons, affirmative badge borders. |
| `AppStyles.waterActionAccent` | `Colors.blueAccent` (`#448AFF`) | **Strictly reserved for water execution.** Used exclusively when AI recommends **"IRRIGATE"**. | AI recommendation cards, primary action callouts for manual watering. |
| `AppStyles.techSecondaryAccent` | `Colors.cyanAccent` (`#18FFFF`) | Secondary technical telemetry, clock sync drift gaps, and Irrigation Period configuration UI. | Configuration form highlights, sync offset counters, secondary metric ticks. |
| `AppStyles.warningAccent` | `Colors.amberAccent` (`#FFAB40`) | Warning states, pending actions, agronomic "Yellow Zone", Prediction Period setup, unsynced local devices. | Pending chips, agronomic warning cards, un-synced indicators. |
| `AppStyles.errorAccent` | `Colors.redAccent` / `shade900` | Destructive actions, system errors, API timeouts, manual safety overrides, debug "Danger Zone". | Disconnect buttons, database clear actions, critical error banners. |
| `AppStyles.surfaceColor` | `Color(0xFF1E1E1E)` | Standard container surface tone across dark UI elements. | Base card fill, status log container fills, modal popups. |
| `AppStyles.dividerColor` | `Colors.white12` (`Color(0x1FFFFFFF)`) | Structure division and default card boundaries. | Card borders, horizontal rules, console box outlines. |
| `AppStyles.textMuted` | `Colors.white54` (`Color(0x8AFFFFFF)`) | Inactive labels, secondary text, timestamps, empty state indicators. | Subtitles, disabled action text, telemetry units. |

---

## III. Dual-Typography Contract

To maintain high scannability for human operators while retaining the technical precision required for hardware telemetry, the typography system adopts a dual-font strategy split across 4 strict functional tiers.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          TYPOGRAPHY CONTRACT                            │
├─────────────────┬──────────────┬──────────────┬─────────────────────────┤
│ Tier            │ Font Family  │ Size & Weight│ Target Usage            │
├─────────────────┼──────────────┼──────────────┼─────────────────────────┤
│ Display Header  │ System Sans  │ 20pt Bold    │ Screen Titles           │
│ Section Title   │ System Sans  │ 16pt Bold    │ Card Headers, Panels    │
│ Body Text       │ System Sans  │ 13pt Regular │ Buttons, Standard Labels│
│ Console Body    │ Monospace    │ 13pt Regular │ MAC, Telemetry, Logs    │
│ Caption Status  │ Monospace    │ 11pt Regular │ Timestamps, Endpoints   │
└─────────────────┴──────────────┴──────────────┴─────────────────────────┤
```

### 1. Font Family Allocation
* **Standard System Sans-Serif:** Used for standard UI labels, buttons, dialog titles, navigation rails, and section titles to ensure quick visual parsing during field operations.
* **Monospace (`AppStyles.consoleFontFamily`):** Used exclusively for raw hardware data: MAC addresses, timestamps, sensor measurements, API routes, SQL row counts, and console output.

### 2. Tier Specifications

1. **Display Header (`AppStyles.displayHeader`):**
   * *Style:* 20pt, Bold, Primary Accent (`successAccent`), System Sans.
   * *Usage:* Top-level screen titles (e.g., "Telemetry Control", "Device Scanner").
2. **Section Title (`AppStyles.sectionTitle`):**
   * *Style:* 16pt, Bold, White (`#FFFFFF`), System Sans.
   * *Usage:* Card group headers, settings group titles, configuration panels.
3. **Body Text (`AppStyles.bodyText`):**
   * *Style:* 13pt, Regular, White/White87, System Sans.
   * *Usage:* Button titles, explanatory UI prose, field descriptors.
4. **Console / Technical Body (`AppStyles.consoleBody`):**
   * *Style:* 13pt, Regular, White70, Monospace Font Family.
   * *Usage:* Raw data metrics (`24.5°C`, `78% VWC`), device MAC IDs (`AA:BB:CC:11:22:33`), console logs.
5. **Caption / Status (`AppStyles.captionStatus`):**
   * *Style:* 11pt, Regular, White54 (`textMuted`), Monospace Font Family.
   * *Usage:* Ping latencies (`45ms`), record creation timestamps, API status codes.

---

## IV. Component Design Rules & Standardized Shells

### 1. Global Screen Layout Structure
Every primary screen in the application must adhere to the following outer structure:
* **Global Padding:** Wrapped in `Padding(padding: EdgeInsets.all(AppStyles.spaceMD))`.
* **Header Pattern:** Top element must be a `Row` with `MainAxisAlignment.spaceBetween`:
  * Left: Screen Title using `AppStyles.displayHeader`.
  * Right: Primary Action Buttons (e.g., "Scan", "Sync Now", "Refresh").
* **Vertical Gaps:** Separate top header and content blocks using `SizedBox(height: AppStyles.spaceMD)`. Use `SizedBox(height: AppStyles.spaceLG)` for major section breaks.

### 2. Standard Container Shells & Cards
All cards, status panels, console boxes, and debug panels must utilize standardized card shells:
* **Corner Radius:** Fixed at `BorderRadius.circular(8.0)`. Sharp edges (0dp) and circular edges (>12dp) are banned for structural panels.
* **Base Fill:** `AppStyles.surfaceColor` (`0xFF1E1E1E`).
* **Default Border:** 1px solid `AppStyles.dividerColor` (`Colors.white12`).

### 3. Interactive & Selectable List Cards
* **Unselected State:** Faint 1px border (`AppStyles.dividerColor`), background `AppStyles.surfaceColor`.
* **Selected State:** Border width scales to **2.0px** using `AppStyles.successAccent`. Card fill remains `AppStyles.surfaceColor`.

### 4. AI Recommendation Cards
AI Output cards (e.g., Irrigation Decisions) must feature elevated styling to communicate urgency and confidence:
* **Background Tint:** Translucent fill using the status accent with 10% opacity (`accentColor.withValues(alpha: 0.1)`).
* **Border:** 2.0px solid border using the status accent color.
* **Verdict Icon Mapping:**
  * **"IRRIGATE":** `Icons.water_drop` colored with `AppStyles.waterActionAccent`.
  * **"DO NOT IRRIGATE":** `Icons.eco` colored with `AppStyles.successAccent`.

### 5. Button Taxonomy
* **Primary Actions:** Use `ElevatedButton.icon` with standard theme foreground and elevation.
* **Destructive Actions:** Must override standard theme button styles explicitly:
  * Foreground / Text Color: `AppStyles.errorAccent` (`Colors.redAccent`).
  * Border / Outline: 1px solid `AppStyles.errorAccent`.
  * Splash / Highlight: `Colors.redAccent.withValues(alpha: 0.1)`.

---

## V. Reference Implementation (`app_styles.dart`)

Below is the complete, centralized production code for `lib/core/theme/app_styles.dart`.

```dart
import 'package:flutter/material.dart';

/// Centralized Design System Tokens and Component Shell Builders
abstract class AppStyles {
  // ---------------------------------------------------------------------------
  // I. SPACING TOKENS (Base-8 Layout Grid)
  // ---------------------------------------------------------------------------
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;

  // ---------------------------------------------------------------------------
  // II. SEMANTIC COLOR TOKENS
  // ---------------------------------------------------------------------------
  static const Color surfaceColor        = Color(0xFF1E1E1E);
  static const Color successAccent       = Colors.greenAccent;
  static const Color waterActionAccent   = Colors.blueAccent;
  static const Color techSecondaryAccent = Colors.cyanAccent;
  static const Color warningAccent       = Colors.amberAccent;
  static const Color errorAccent         = Colors.redAccent;
  static const Color errorDarkAccent     = Color(0xFFB71C1C); // Colors.red.shade900
  static const Color dividerColor        = Colors.white12;
  static const Color textMuted           = Colors.white54;
  static const Color textSecondary       = Colors.white70;

  // ---------------------------------------------------------------------------
  // III. TYPOGRAPHY CONTRACT
  // ---------------------------------------------------------------------------
  static const String consoleFontFamily = 'Courier'; // Fallback to standard platform monospace

  /// Display Header: Screen Titles (20pt, Bold, Primary Accent, Sans-Serif)
  static const TextStyle displayHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: successAccent,
  );

  /// Section Title: Panel & Card Headers (16pt, Bold, White, Sans-Serif)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Body Text: Buttons & Standard UI Prose (13pt, Regular, Sans-Serif)
  static const TextStyle bodyText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  /// Console Body: Technical Data, Telemetry, MAC IDs (13pt, Monospace)
  static const TextStyle consoleBody = TextStyle(
    fontFamily: consoleFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  /// Caption Status: Timestamps, Pings, Technical Subtitles (11pt, Monospace)
  static const TextStyle captionStatus = TextStyle(
    fontFamily: consoleFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textMuted,
  );

  // ---------------------------------------------------------------------------
  // IV. REUSABLE CONTAINER DECORATIONS & SHELLS
  // ---------------------------------------------------------------------------

  /// Standard Base Card Decoration
  static BoxDecoration cardShell({
    bool isSelected = false,
    Color borderAccent = dividerColor,
  }) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
        color: isSelected ? successAccent : borderAccent,
        width: isSelected ? 2.0 : 1.0,
      ),
    );
  }

  /// AI Recommendation Highlight Card Decoration
  static BoxDecoration aiRecommendationCard(Color stateAccent) {
    return BoxDecoration(
      color: stateAccent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
        color: stateAccent,
        width: 2.0,
      ),
    );
  }

  /// Destructive Button Style Override
  static ButtonStyle destructiveButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: errorAccent,
    side: const BorderSide(color: errorAccent, width: 1.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );
}
```

---

## VI. Screen Refactoring Guidelines

To align existing screens with this unified style guide, complete the following migration actions across `lib/screens`:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       REFACTORING MIGRATION MATRIX                      │
├───────────────────┬─────────────────────────────────────────────────────┤
│ Target Screen     │ Required Refactoring Actions                        │
├───────────────────┼─────────────────────────────────────────────────────┤
│ home_screen.dart  │ Refactor debug panel & status console to use        │
│                   │ AppStyles.consoleBody and cardShell.               │
│ cloud_screen.dart │ Replace hardcoded card borders with cardShell. Map │
│                   │ cloud pings to successAccent and errorAccent.       │
│ config_screen.dart│ Convert form spacing to 8dp grid (spaceMD/spaceSM).│
│                   │ Apply techSecondaryAccent to Irrigation Period.     │
│ local_db_screen.  │ Update prediction stats box to use aiCard shell.   │
│ dart              │ Standardize list tile borders to cardShell.         │
│ nearby_screen.dart│ Refactor scan item lists: wrap in cardShell with    │
│                   │ dynamic selection state (2px successAccent border). │
│ main.dart         │ Ensure bottom status bar uses captionStatus and    │
│                   │ height adheres to 8dp rhythm.                       │
└───────────────────┴─────────────────────────────────────────────────────┘
```

### Refactoring Details by Screen

1. **`home_screen.dart`:**
   * Remove raw inline hex fills (`Color(0xFF1E1E1E)`). Replace with `AppStyles.cardShell()`.
   * Standardize status console output to use `AppStyles.consoleBody`.
   * Replace custom spacing blocks with `SizedBox(height: AppStyles.spaceMD)`.

2. **`cloud_screen.dart`:**
   * Refactor device cards and cloud emulation panel to use standard `AppStyles.cardShell()`.
   * Replace inline status text colors with `AppStyles.successAccent` (synced) and `AppStyles.warningAccent` (pending).

3. **`config_screen.dart`:**
   * Standardize schedule forms using 8dp spatial tokens (`spaceSM`, `spaceMD`).
   * Apply `AppStyles.techSecondaryAccent` to the Irrigation Period slider and clock drift indicators.
   * Apply `AppStyles.warningAccent` to the Prediction Period configuration.

4. **`local_db_screen.dart`:**
   * Refactor database list tiles to use `AppStyles.cardShell()`.
   * Refactor prediction statistics box to use `AppStyles.aiRecommendationCard()`.
   * Standardize database wipe action buttons using `AppStyles.destructiveButtonStyle`.

5. **`nearby_screen.dart`:**
   * Convert BLE scan result items into selectable cards.
   * Toggle selected card state using `AppStyles.cardShell(isSelected: item.isSelected)`.
   * Display hardware MAC addresses using `AppStyles.consoleBody`.

6. **`main.dart`:**
   * Verify bottom telemetry status bar styling.
   * Ensure status text uses `AppStyles.captionStatus`.

---

## VII. Code Governance & Compliance Checklist

During pull requests and code reviews, verify compliance against the following checklist:

* [ ] **Zero Hardcoded Colors:** No `Colors.*` or `Color(0x...)` exist in any file under `lib/screens/`.
* [ ] **Layout Grid Alignment:** All `Padding`, `Margin`, and `SizedBox` dimensions match `4.0`, `8.0`, `16.0`, `24.0`, or `32.0`.
* [ ] **Typography Rules:** Standard UI prose uses sans-serif styles (`displayHeader`, `sectionTitle`, `bodyText`), while hardware values, MAC addresses, and timestamps use monospace styles (`consoleBody`, `captionStatus`).
* [ ] **Card Shell Uniformity:** All cards utilize `AppStyles.cardShell()` or `AppStyles.aiRecommendationCard()`. All border radii are set to 8.0dp.
* [ ] **Domain Color Semantics:** "IRRIGATE" recommendations use `waterActionAccent` (Blue), while "DO NOT IRRIGATE" and active BLE use `successAccent` (Green).
