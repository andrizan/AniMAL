import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

ThemeData buildLightTheme() =>
    _buildTheme(AppColors.light, AppColors.lightStatus);

ThemeData buildDarkTheme() => _buildTheme(AppColors.dark, AppColors.darkStatus);

/// A 3px ring drawn inside a control while it has keyboard focus.
WidgetStateProperty<BorderSide?> _focusRing(Color color) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? BorderSide(color: color, width: 3)
          : null,
    );

ThemeData _buildTheme(ColorScheme scheme, StatusColors status) {
  final textTheme = AppTextStyles.build(scheme);
  final dark = scheme.brightness == Brightness.dark;
  final pill = BorderRadius.circular(AppRadius.pill);
  final focusTint = scheme.primary.withValues(alpha: 0.16);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: [status],
    textTheme: textTheme,
    fontFamily: GoogleFonts.figtree().fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    focusColor: focusTint,
    cardTheme: CardThemeData(
      elevation: dark ? 0 : 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.35),
      surfaceTintColor: AppColors.transparent,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      toolbarHeight: 64,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 76,
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall!.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        );
      }),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(color: scheme.primary, borderRadius: pill),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
      labelColor: scheme.onPrimary,
      unselectedLabelColor: scheme.onSurface,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? focusTint
            : scheme.primary.withValues(alpha: 0.08),
      ),
      splashBorderRadius: pill,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: scheme.primary, width: 3)
            : BorderSide.none,
      ),
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primary,
      disabledColor: scheme.surfaceContainer,
      checkmarkColor: scheme.onPrimary,
      showCheckmark: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      labelStyle: WidgetStateTextStyle.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        final disabled = states.contains(WidgetState.disabled);
        return textTheme.labelLarge!.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected
              ? scheme.onPrimary
              : disabled
              ? scheme.onSurfaceVariant
              : scheme.onSurface,
        );
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: _focusRing(scheme.primary),
        visualDensity: VisualDensity.compact,
        minimumSize: const WidgetStatePropertyAll(Size(64, 40)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium!.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.surfaceContainer,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: const StadiumBorder(),
        textStyle: textTheme.titleMedium,
      ).copyWith(side: _focusRing(scheme.primaryContainer)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(64, 52),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            shape: const StadiumBorder(),
            textStyle: textTheme.titleMedium,
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? scheme.primary
                    : scheme.outline,
                width: states.contains(WidgetState.focused) ? 3 : 1.5,
              ),
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ).copyWith(side: _focusRing(scheme.primary)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(side: _focusRing(scheme.primary)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      border: _inputBorder(scheme.outline, 1.5),
      enabledBorder: _inputBorder(scheme.outline, 1.5),
      focusedBorder: _inputBorder(scheme.primary, 2),
      errorBorder: _inputBorder(scheme.error, 1.5),
      focusedErrorBorder: _inputBorder(scheme.error, 2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      modalBackgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: AppColors.transparent,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      dragHandleSize: const Size(40, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHigh,
      linearMinHeight: 8,
    ),
  );
}

OutlineInputBorder _inputBorder(Color color, double width) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
