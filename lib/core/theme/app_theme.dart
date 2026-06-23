import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildLightTheme() {
  const scheme = AppColors.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: const [AppColors.lightStatus],
    textTheme: AppTextStyles.build(Brightness.light, scheme),
    fontFamily: GoogleFonts.inter().fontFamily,
    fontFamilyFallback: const ['Noto Sans JP'],
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
    ),
  );
}

ThemeData buildDarkTheme() {
  const scheme = AppColors.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: const [AppColors.darkStatus],
    textTheme: AppTextStyles.build(Brightness.dark, scheme),
    fontFamily: GoogleFonts.inter().fontFamily,
    fontFamilyFallback: const ['Noto Sans JP'],
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
    ),
  );
}
