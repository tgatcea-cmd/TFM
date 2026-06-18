// ponytail: Centralized stylesheet with dynamic system colors and theme accents
import 'package:flutter/material.dart';

class AppStyles {
  // Brand & Semantic Colors - Dynamically resolved from Theme (System Settings)
  static Color primaryTeal(BuildContext context) => Theme.of(context).colorScheme.primary;
  
  static Color darkSlate(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  
  static Color accentOrange(BuildContext context) => Theme.of(context).colorScheme.secondary;
  
  static Color dangerRed(BuildContext context) => Theme.of(context).colorScheme.error;
  
  // Light tints for containers dynamically adapted
  static Color bgTealLight(BuildContext context) => Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15);
  static Color borderTealLight(BuildContext context) => Theme.of(context).colorScheme.primary.withValues(alpha: 0.3);
  
  static Color dangerRedBg(BuildContext context) => Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.15);
  static Color dangerRedBorder(BuildContext context) => Theme.of(context).colorScheme.error.withValues(alpha: 0.3);

  // Border Radii (Remain constant layout metrics)
  static const double radiusLarge = 36.0;
  static const double radiusMedium = 12.0;
  static const double radiusSmall = 8.0;

  // Shadow Defaults
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];

  // Premium Typography TextStyles (Dynamic based on theme)
  static TextStyle appBarTitleStyle(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkSlate(context),
  );

  static TextStyle headerLabelStyle(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: primaryTeal(context),
  );

  static TextStyle titleStyle(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkSlate(context),
  );

  static TextStyle subTitleStyle(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
  );

  static TextStyle bodyStyle(BuildContext context) => TextStyle(
    fontSize: 13,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
  );

  // Recommendations use brand colors directly
  static TextStyle recSafeStyle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: primaryTeal(context),
  );

  static TextStyle recDangerStyle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: dangerRed(context),
  );

  // Cards & Containers Custom Decoration
  static BoxDecoration headerDecoration(BuildContext context) => BoxDecoration(
    color: bgTealLight(context),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: borderTealLight(context)),
  );

  static BoxDecoration dropdownDecoration(Color bgColor, Color borderColor) => BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: borderColor),
    boxShadow: softShadow,
  );
}
