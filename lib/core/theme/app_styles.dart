import 'package:flutter/material.dart';

class AppStyles {
  // --- SPACING TOKENS (8dp Grid) ---
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;

  // --- SEMANTIC COLOR TOKENS ---
  static const Color consoleBackground = Colors.black;
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color successAccent = Colors.greenAccent;
  static const Color waterActionAccent = Colors.blueAccent;
  static const Color techSecondaryAccent = Colors.cyanAccent;
  static const Color warningAccent = Colors.amberAccent;
  static const Color errorAccent = Colors.redAccent;
  static const Color dividerColor = Colors.white12;
  static const Color textSecondary       = Colors.white70;
  static const Color textMuted           = Colors.white54;
  static const Color errorDarkAccent     = Color(0xFFB71C1C);



  // --- TYPOGRAPHY CONTRACT ---
  static const String consoleFontFamily = 'monospace'; 

  // Standard UI Prose (Sans-Serif for high scannability)
  static const TextStyle displayHeader = TextStyle(
    fontSize: 20, fontWeight: FontWeight.bold, color: successAccent,
  );
  
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 13, fontWeight: FontWeight.normal, color: Colors.white,
  );

  // Technical Data Tokens (Monospace console font)
  static const TextStyle consoleBody = TextStyle(
    fontFamily: consoleFontFamily, fontSize: 13, color: textSecondary,
  );

  static const TextStyle captionStatus = TextStyle(
    fontFamily: consoleFontFamily, fontSize: 11, color: textMuted,
  );

  // --- REUSABLE CONTAINER DECORATIONS ---
  static BoxDecoration cardShell({bool isSelected = false, Color borderAccent = dividerColor}) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
        color: isSelected ? successAccent : borderAccent,
        width: isSelected ? 2.0 : 1.0,
      ),
    );
  }

  static BoxDecoration aiRecommendationCard(Color stateAccent) {
    return BoxDecoration(
      color: stateAccent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: stateAccent, width: 2.0),
    );
  }

  static ButtonStyle destructiveButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: errorAccent,
    side: const BorderSide(color: errorAccent, width: 1.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // --- MAIN THEME DATA ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: consoleBackground,
      colorScheme: const ColorScheme.dark(
        primary: successAccent,
        secondary: techSecondaryAccent,
        surface: surfaceColor,
        error: errorAccent,
      ),
      textTheme: const TextTheme(
        headlineSmall: displayHeader,
        titleMedium: sectionTitle,
        bodyMedium: bodyText,
        bodySmall: captionStatus,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: consoleBackground,
        selectedIconTheme: IconThemeData(color: successAccent),
        unselectedIconTheme: IconThemeData(color: textMuted),
        selectedLabelTextStyle: TextStyle(color: successAccent, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceColor,
          foregroundColor: successAccent,
          side: const BorderSide(color: successAccent),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: dividerColor),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}