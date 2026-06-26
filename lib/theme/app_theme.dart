import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean greyscale palette.
abstract final class AppColors {
  static const white = Color(0xFFEFEEE7);
  static const gray100 = Color(0xFFE5E4DD);
  static const gray200 = Color(0xFFDBDAD3);
  static const gray300 = Color(0xFFD1D0C9);
  static const gray400 = Color(0xFFA1A1AA);
  static const gray500 = Color(0xFF71717A);
  static const gray600 = Color(0xFF52525B);
  static const gray700 = Color(0xFF3F3F46);
  static const gray800 = Color(0xFF27272A);
  static const gray900 = Color(0xFF18181B);
  static const black = Color(0xFF000000);

  static const background = white;
  static const surface = white;
  static const elevated = gray100;
  static const border = gray200;
  static const borderStrong = gray300;
  static const muted = gray500;
  static const textSecondary = gray600;
  static const text = black;

  static const accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [black, gray600],
  );

  /// Legacy aliases used across the app.
  static const ink = black;
  static const navy = white;
  static const fog = black;
  static const mist = gray800;
  static const steel = gray200;
  static const void_ = black;
  static const slate = white;
  static const cream = black;
  static const tan = gray800;
  static const brown = gray200;
  static const offWhite = gray100;
  static const cobalt = Color(0xFF0055FF);
  static const cobaltLight = Color(0xFF00AAFF);
  static const wine = white;
  static const crimson = gray200;
  static const ruby = Color(0xFFE63946);
  static const peach = Color(0xFFF4A261);
  static const emerald = Color(0xFF2A9D8F);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: AppColors.black,
    onPrimary: AppColors.white,
    secondary: AppColors.gray800,
    onSecondary: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.black,
    error: AppColors.black,
    onError: AppColors.white,
    outline: AppColors.gray200,
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
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.white;
        return AppColors.gray400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.black;
        }
        return AppColors.gray200;
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        side: const BorderSide(color: AppColors.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.black,
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
      backgroundColor: AppColors.black,
      contentTextStyle: GoogleFonts.inter(color: AppColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppColors.gray800),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
