import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bootstrap gray scale — light surfaces, dark type.
abstract final class AppColors {
  static const gray100 = Color(0xFFF8F9FA);
  static const gray200 = Color(0xFFE9ECEF);
  static const gray300 = Color(0xFFDEE2E6);
  static const gray400 = Color(0xFFCED4DA);
  static const gray500 = Color(0xFFADB5BD);
  static const gray600 = Color(0xFF6C757D);
  static const gray700 = Color(0xFF495057);
  static const gray800 = Color(0xFF343A40);
  static const gray900 = Color(0xFF212529);

  static const background = gray100;
  static const surface = Color(0xFFFFFFFF);
  static const elevated = gray200;
  static const border = gray300;
  static const borderStrong = gray400;
  static const muted = gray600;
  static const textSecondary = gray700;
  static const text = gray900;

  static const accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gray400, gray700, gray900],
  );
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: AppColors.gray900,
    onPrimary: AppColors.gray100,
    secondary: AppColors.gray700,
    onSecondary: AppColors.gray100,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.gray800,
    onError: AppColors.gray100,
    outline: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.gray900;
        return AppColors.gray500;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.gray400;
        }
        return AppColors.gray300;
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gray900,
        foregroundColor: AppColors.gray100,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.outfit(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: -0.4,
        height: 1.15,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: -0.2,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.55,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: -0.1,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.muted,
        height: 1.45,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.muted,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.muted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.gray900,
      contentTextStyle: GoogleFonts.inter(color: AppColors.gray100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
