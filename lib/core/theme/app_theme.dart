import 'package:flutter/material.dart';

class AppTheme {
  // Primary Brand Colors
  static const Color primaryColor = Color(0xFF6750A4);    // Purple
  static const Color secondaryColor = Color(0xFF7BDAA0);  // Green
  static const Color tertiaryColor = Color(0xFF7BDAA0);   // Green (same as secondary)
  static const Color errorColor = Color(0xFFB3261E);      // Red

  // Light Theme Surface Colors
  static const Color backgroundColor = Color(0xFFFFFBFE);
  static const Color surfaceColor = Color(0xFFFFFBFE);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color surfaceTint = Color(0xFF6750A4);

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF1C1B1F);
  static const Color darkSurfaceColor = Color(0xFF1C1B1F);
  static const Color darkSurfaceVariant = Color(0xFF49454F);
  static const Color darkSurfaceTint = Color(0xFFD0BCFF);
  static const Color darkPrimaryColor = Color(0xFFD0BCFF);

  // Spacing Scale (8/12/16)
  static const double spacingXS = 8.0;
  static const double spacingSM = 12.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // Corner Radius
  static const double cornerRadius = 16.0;
  static const double cornerRadiusSM = 12.0;
  static const double cornerRadiusLG = 20.0;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      surfaceVariant: surfaceVariant,
      surfaceTint: surfaceTint,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Color(0xFF006E2A),
      onTertiary: Color(0xFF006E2A),
      onBackground: Color(0xFF1C1B1F),
      onSurface: Color(0xFF1C1B1F),
      onSurfaceVariant: Color(0xFF49454F),
      onError: Colors.white,
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFCAC4D0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        side: const BorderSide(color: primaryColor),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      color: surfaceColor,
      margin: const EdgeInsets.all(spacingXS),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cornerRadiusSM),
      ),
      filled: true,
      fillColor: surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingMD),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      background: darkBackgroundColor,
      surface: darkSurfaceColor,
      surfaceVariant: darkSurfaceVariant,
      surfaceTint: darkSurfaceTint,
      error: errorColor,
      onPrimary: Color(0xFF1C1B1F),
      onSecondary: Color(0xFF006E2A),
      onTertiary: Color(0xFF006E2A),
      onBackground: Color(0xFFE6E1E5),
      onSurface: Color(0xFFE6E1E5),
      onSurfaceVariant: Color(0xFFCAC4D0),
      onError: Colors.white,
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Color(0xFF1C1B1F),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        side: const BorderSide(color: darkPrimaryColor),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      color: darkSurfaceColor,
      margin: const EdgeInsets.all(spacingXS),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cornerRadiusSM),
      ),
      filled: true,
      fillColor: darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingMD),
    ),
  );
}
