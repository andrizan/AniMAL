import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

CardThemeData _cardTheme(ColorScheme scheme) => CardThemeData(
  elevation: 0,
  color: scheme.surfaceContainer,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.card),
    side: BorderSide(color: scheme.outlineVariant),
  ),
);

TabBarThemeData _tabBarTheme(TextTheme textTheme) => TabBarThemeData(
  labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  unselectedLabelStyle: textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.w400,
  ),
);

ThemeData buildLightTheme() {
  const scheme = AppColors.light;
  final textTheme = AppTextStyles.build(Brightness.light, scheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: const [AppColors.lightStatus],
    textTheme: textTheme,
    tabBarTheme: _tabBarTheme(textTheme),
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: _cardTheme(scheme),
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
    dialogTheme: DialogThemeData(backgroundColor: scheme.surfaceContainerLow),
  );
}

ThemeData buildDarkTheme() {
  const scheme = AppColors.dark;
  final textTheme = AppTextStyles.build(Brightness.dark, scheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: const [AppColors.darkStatus],
    textTheme: textTheme,
    tabBarTheme: _tabBarTheme(textTheme),
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: _cardTheme(scheme),
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
    dialogTheme: DialogThemeData(backgroundColor: scheme.surfaceContainerLow),
  );
}
