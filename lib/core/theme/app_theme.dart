import 'package:flutter/material.dart';

import 'brand_colors.dart';

/// Light ("white mode") and night ("dark mode") themes for Afzal Opportunities.
///
/// Night theme: night blue-black backgrounds, white typography, mint-green
/// highlights and elegant cards with subtle borders and 16dp rounded corners.
/// Light theme: white backgrounds, night-blue typography, mint accents and
/// light-grey cards.
class AppTheme {
  const AppTheme._();

  static const double cardRadius = 16;

  /// Night theme: dark streaming-style browsing experience.
  static ThemeData nightTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: BrandColors.nightBlack,
      colorScheme: const ColorScheme.dark(
        primary: BrandColors.mint,
        onPrimary: BrandColors.nightBlack,
        secondary: BrandColors.mint,
        onSecondary: BrandColors.nightBlack,
        surface: BrandColors.nightBlue,
        onSurface: BrandColors.white,
        error: Color(0xFFE5484D),
        onError: BrandColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandColors.nightBlack,
        foregroundColor: BrandColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: BrandColors.nightBlue,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: BrandColors.white.withValues(alpha: 0.08)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: BrandColors.nightBlue,
        selectedColor: BrandColors.mint,
        labelStyle: const TextStyle(color: BrandColors.white),
        secondaryLabelStyle: const TextStyle(color: BrandColors.nightBlack),
        side: BorderSide(color: BrandColors.white.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BrandColors.nightBlue,
        selectedItemColor: BrandColors.mint,
        unselectedItemColor: BrandColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.mint,
          foregroundColor: BrandColors.nightBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.mint,
          side: const BorderSide(color: BrandColors.mint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: BrandColors.mint),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BrandColors.mint,
      ),
      dividerColor: BrandColors.white.withValues(alpha: 0.08),
      dialogTheme: const DialogThemeData(
        backgroundColor: BrandColors.nightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BrandColors.nightBlue,
        contentTextStyle: TextStyle(color: BrandColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: BrandColors.white,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: BrandColors.white,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: BrandColors.white,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: BrandColors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: BrandColors.white,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: BrandColors.white,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: BrandColors.white,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: BrandColors.muted,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: BrandColors.white,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: BrandColors.muted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Light theme: clean white browsing experience.
  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: BrandColors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2E9E76),
        onPrimary: BrandColors.white,
        secondary: Color(0xFF2E9E76),
        onSecondary: BrandColors.white,
        surface: BrandColors.lightBackground,
        onSurface: BrandColors.nightBlue,
        error: Color(0xFFC62828),
        onError: BrandColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandColors.white,
        foregroundColor: BrandColors.nightBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: BrandColors.lightBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(
            color: BrandColors.nightBlue.withValues(alpha: 0.06),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: BrandColors.lightBackground,
        selectedColor: BrandColors.mint,
        labelStyle: const TextStyle(color: BrandColors.nightBlue),
        secondaryLabelStyle: const TextStyle(color: BrandColors.nightBlack),
        side: BorderSide(color: BrandColors.nightBlue.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BrandColors.white,
        selectedItemColor: Color(0xFF2E9E76),
        unselectedItemColor: BrandColors.mutedOnLight,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.mint,
          foregroundColor: BrandColors.nightBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E9E76),
          side: const BorderSide(color: Color(0xFF2E9E76)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E9E76)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF2E9E76),
      ),
      dividerColor: BrandColors.nightBlue.withValues(alpha: 0.08),
      dialogTheme: const DialogThemeData(
        backgroundColor: BrandColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BrandColors.nightBlue,
        contentTextStyle: TextStyle(color: BrandColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: BrandColors.nightBlue,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: BrandColors.nightBlue,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: BrandColors.nightBlue,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: BrandColors.nightBlue,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: BrandColors.nightBlue,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: BrandColors.nightBlue,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: BrandColors.nightBlue,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: BrandColors.mutedOnLight,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: BrandColors.nightBlue,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: BrandColors.mutedOnLight,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
