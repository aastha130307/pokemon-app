import 'package:flutter/material.dart';

/// Centralized design tokens and theme configuration for the Pokédex app.
class AppTheme {
  // Brand Colors
  static const Color primaryRed = Color(0xFFDC0A2D); // Iconic Pokédex Red
  static const Color darkRed = Color(0xFFB00824);
  static const Color backgroundLight = Color(0xFFF6F8FC);
  static const Color surfaceWhite = Colors.white;
  static const Color textPrimary = Color(0xFF1E232A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;

  /// Complete light theme definition for MaterialApp.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryRed,
      primary: primaryRed,
      surface: surfaceWhite,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        indicatorColor: primaryRed.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryRed, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
