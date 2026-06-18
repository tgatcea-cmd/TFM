// ponytail: Centralized stylesheet with reduced, unified color palette
import 'package:flutter/material.dart';

class AppStyles {
  // Brand & Semantic Colors (Reduced to 4 key colors)
  static const Color primaryTeal = Colors.teal;
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color accentOrange = Colors.orange;
  static const Color dangerRed = Color(0xFFD32F2F); // Red 700
  
  // Light tints for containers
  static const Color bgTealLight = Color(0xFFE0F2F1); // Teal 50
  static const Color borderTealLight = Color(0xFF80CBC4); // Teal 200
  
  static const Color dangerRedBg = Color(0xFFFFEBEE); // Red 50
  static const Color dangerRedBorder = Color(0xFFEF9A9A); // Red 200

  // Border Radii
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

  // Premium Typography TextStyles
  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: darkSlate,
  );

  static const TextStyle headerLabelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: primaryTeal,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkSlate,
  );

  static const TextStyle subTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 13,
    color: Colors.black54,
  );

  // Recommendations use brand colors directly
  static const TextStyle recSafeStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: primaryTeal,
  );

  static const TextStyle recDangerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: dangerRed,
  );

  // Cards & Containers Custom Decoration
  static BoxDecoration get headerDecoration => BoxDecoration(
    color: bgTealLight,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: borderTealLight),
  );

  static BoxDecoration dropdownDecoration(Color bgColor, Color borderColor) => BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: borderColor),
    boxShadow: softShadow,
  );
}
