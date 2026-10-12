import 'package:material_ui/material_ui.dart';

// ── Custom Theme Extension ────────────────────────────────────

class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.listWatching,
    required this.listCompleted,
    required this.listOnHold,
    required this.listDropped,
    required this.listPlanToWatch,
    required this.star,
    required this.airingContainer,
    required this.onAiringContainer,
    required this.finishedContainer,
    required this.onFinishedContainer,
    required this.upcomingContainer,
    required this.onUpcomingContainer,
    required this.droppedContainer,
    required this.onDroppedContainer,
    required this.planContainer,
    required this.onPlanContainer,
  });

  /// The theme's status colours, or the palette of the current brightness
  /// when the app theme is not installed (plain `MaterialApp` in tests).
  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ??
        (theme.brightness == Brightness.dark
            ? AppColors.darkStatus
            : AppColors.lightStatus);
  }

  /// Solid marks for charts, legends and dots. Validated for colour-vision
  /// deficiency as a set, so every list status keeps its own hue.
  final Color listWatching;
  final Color listCompleted;
  final Color listOnHold;
  final Color listDropped;
  final Color listPlanToWatch;
  final Color star;

  /// Tonal pairs for chips. Each `on*` colour reads at 7:1 or better on its
  /// container. Watching shares the airing pair, completed the finished
  /// pair, on hold the upcoming pair and the "aired" badge the plan pair.
  final Color airingContainer;
  final Color onAiringContainer;
  final Color finishedContainer;
  final Color onFinishedContainer;
  final Color upcomingContainer;
  final Color onUpcomingContainer;
  final Color droppedContainer;
  final Color onDroppedContainer;
  final Color planContainer;
  final Color onPlanContainer;

  @override
  ThemeExtension<StatusColors> copyWith({
    Color? listWatching,
    Color? listCompleted,
    Color? listOnHold,
    Color? listDropped,
    Color? listPlanToWatch,
    Color? star,
    Color? airingContainer,
    Color? onAiringContainer,
    Color? finishedContainer,
    Color? onFinishedContainer,
    Color? upcomingContainer,
    Color? onUpcomingContainer,
    Color? droppedContainer,
    Color? onDroppedContainer,
    Color? planContainer,
    Color? onPlanContainer,
  }) {
    return StatusColors(
      listWatching: listWatching ?? this.listWatching,
      listCompleted: listCompleted ?? this.listCompleted,
      listOnHold: listOnHold ?? this.listOnHold,
      listDropped: listDropped ?? this.listDropped,
      listPlanToWatch: listPlanToWatch ?? this.listPlanToWatch,
      star: star ?? this.star,
      airingContainer: airingContainer ?? this.airingContainer,
      onAiringContainer: onAiringContainer ?? this.onAiringContainer,
      finishedContainer: finishedContainer ?? this.finishedContainer,
      onFinishedContainer: onFinishedContainer ?? this.onFinishedContainer,
      upcomingContainer: upcomingContainer ?? this.upcomingContainer,
      onUpcomingContainer: onUpcomingContainer ?? this.onUpcomingContainer,
      droppedContainer: droppedContainer ?? this.droppedContainer,
      onDroppedContainer: onDroppedContainer ?? this.onDroppedContainer,
      planContainer: planContainer ?? this.planContainer,
      onPlanContainer: onPlanContainer ?? this.onPlanContainer,
    );
  }

  @override
  ThemeExtension<StatusColors> lerp(
    covariant ThemeExtension<StatusColors>? other,
    double t,
  ) {
    if (other is! StatusColors) return this;
    return StatusColors(
      listWatching: Color.lerp(listWatching, other.listWatching, t)!,
      listCompleted: Color.lerp(listCompleted, other.listCompleted, t)!,
      listOnHold: Color.lerp(listOnHold, other.listOnHold, t)!,
      listDropped: Color.lerp(listDropped, other.listDropped, t)!,
      listPlanToWatch: Color.lerp(listPlanToWatch, other.listPlanToWatch, t)!,
      star: Color.lerp(star, other.star, t)!,
      airingContainer: Color.lerp(airingContainer, other.airingContainer, t)!,
      onAiringContainer: Color.lerp(
        onAiringContainer,
        other.onAiringContainer,
        t,
      )!,
      finishedContainer: Color.lerp(
        finishedContainer,
        other.finishedContainer,
        t,
      )!,
      onFinishedContainer: Color.lerp(
        onFinishedContainer,
        other.onFinishedContainer,
        t,
      )!,
      upcomingContainer: Color.lerp(
        upcomingContainer,
        other.upcomingContainer,
        t,
      )!,
      onUpcomingContainer: Color.lerp(
        onUpcomingContainer,
        other.onUpcomingContainer,
        t,
      )!,
      droppedContainer: Color.lerp(
        droppedContainer,
        other.droppedContainer,
        t,
      )!,
      onDroppedContainer: Color.lerp(
        onDroppedContainer,
        other.onDroppedContainer,
        t,
      )!,
      planContainer: Color.lerp(planContainer, other.planContainer, t)!,
      onPlanContainer: Color.lerp(onPlanContainer, other.onPlanContainer, t)!,
    );
  }
}

// ── Color Palette ─────────────────────────────────────────────
//
// Lavender-tinted neutrals with one indigo accent. Every text pair in the
// schemes and the status pairs below was checked against WCAG 2.2: 4.5:1 or
// better for text, 3:1 for icons, borders and chart marks.

abstract final class AppColors {
  // ── Theme Extensions ──
  static const lightStatus = StatusColors(
    listWatching: Color(0xFF14A5A0),
    listCompleted: Color(0xFF4F46C8),
    listOnHold: Color(0xFFC98100),
    listDropped: Color(0xFFC93A55),
    listPlanToWatch: Color(0xFF667089),
    star: Color(0xFF9A5B00),
    airingContainer: Color(0xFFDAF3EA),
    onAiringContainer: Color(0xFF0B5140),
    finishedContainer: Color(0xFFDCE9FF),
    onFinishedContainer: Color(0xFF17407F),
    upcomingContainer: Color(0xFFFFE8C7),
    onUpcomingContainer: Color(0xFF6A3B00),
    droppedContainer: Color(0xFFFFE0E4),
    onDroppedContainer: Color(0xFF8A1B2B),
    planContainer: Color(0xFFE6E8F0),
    onPlanContainer: Color(0xFF3F4457),
  );

  static const darkStatus = StatusColors(
    listWatching: Color(0xFF45D6C6),
    listCompleted: Color(0xFF8A80F5),
    listOnHold: Color(0xFFF5BE55),
    listDropped: Color(0xFFFF6F8C),
    listPlanToWatch: Color(0xFF9AA1BC),
    star: Color(0xFFF5B544),
    airingContainer: Color(0xFF134538),
    onAiringContainer: Color(0xFF9BE9CF),
    finishedContainer: Color(0xFF1B3563),
    onFinishedContainer: Color(0xFFBBD4FF),
    upcomingContainer: Color(0xFF5A3A0A),
    onUpcomingContainer: Color(0xFFFFD99A),
    droppedContainer: Color(0xFF5E1D2A),
    onDroppedContainer: Color(0xFFFFC4CC),
    planContainer: Color(0xFF323649),
    onPlanContainer: Color(0xFFCDD2E4),
  );

  /// Categorical chart colours in a fixed order, one set per brightness.
  /// Five is the most the palette can keep apart under colour-vision
  /// deficiency; later series fall back to a neutral.
  static const chartPalette = <Color>[
    Color(0xFF4F46C8),
    Color(0xFF14A5A0),
    Color(0xFFC98100),
    Color(0xFFC93A55),
    Color(0xFF667089),
  ];

  static const chartPaletteDark = <Color>[
    Color(0xFF8A80F5),
    Color(0xFF45D6C6),
    Color(0xFFF5BE55),
    Color(0xFFFF6F8C),
    Color(0xFF9AA1BC),
  ];

  // ── Brand mark (same in both themes; white reads at 4:1+ on both ends) ──
  static const brandGradient = <Color>[Color(0xFF7B6CF0), Color(0xFF4B3FC0)];

  // ── Overlays on imagery (same in both themes) ──
  static const transparent = Color(0x00000000);
  static const overlayDark = Color(0x6614121F);
  static const overlayDarker = Color(0xB814121F);
  static const barrier = Color(0xCC14121F);
  static const iconLight = Color(0xFFFFFFFF);
  static const iconSubtle = Color(0x8AFFFFFF);

  // ── Light ColorScheme ──
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF5144C9),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE5E2FF),
    onPrimaryContainer: Color(0xFF2B2378),
    secondary: Color(0xFF117C76),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE4E1F1),
    onSecondaryContainer: Color(0xFF1D1B2E),
    tertiary: Color(0xFF9A5B00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFE8C7),
    onTertiaryContainer: Color(0xFF6A3B00),
    error: Color(0xFFA61E35),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFE0E4),
    onErrorContainer: Color(0xFF8A1B2B),
    surface: Color(0xFFF7F6FB),
    onSurface: Color(0xFF1D1B2E),
    onSurfaceVariant: Color(0xFF55536E),
    surfaceDim: Color(0xFFE4E1F1),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFEFEDF7),
    surfaceContainerHigh: Color(0xFFE4E1F1),
    surfaceContainerHighest: Color(0xFFD9D5EA),
    outline: Color(0xFF8582A0),
    outlineVariant: Color(0xFFE7E4F2),
    shadow: Color(0xFF2D236E),
    scrim: Color(0xFF14121F),
    surfaceTint: Color(0xFF5144C9),
    inverseSurface: Color(0xFF2A2740),
    onInverseSurface: Color(0xFFF7F6FB),
    inversePrimary: Color(0xFFB7AEFF),
  );

  // ── Dark ColorScheme ──
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB7AEFF),
    onPrimary: Color(0xFF241B6E),
    primaryContainer: Color(0xFF3A3390),
    onPrimaryContainer: Color(0xFFE5E2FF),
    secondary: Color(0xFF45D6C6),
    onSecondary: Color(0xFF0B3A33),
    secondaryContainer: Color(0xFF322D49),
    onSecondaryContainer: Color(0xFFECEAF8),
    tertiary: Color(0xFFF5B544),
    onTertiary: Color(0xFF3D2600),
    tertiaryContainer: Color(0xFF5A3A0A),
    onTertiaryContainer: Color(0xFFFFD99A),
    error: Color(0xFFFF8DA1),
    onError: Color(0xFF4A0E1A),
    errorContainer: Color(0xFF5E1D2A),
    onErrorContainer: Color(0xFFFFC4CC),
    surface: Color(0xFF14121F),
    onSurface: Color(0xFFECEAF8),
    onSurfaceVariant: Color(0xFFB7B4D0),
    surfaceDim: Color(0xFF0F0D18),
    surfaceBright: Color(0xFF322D49),
    surfaceContainerLowest: Color(0xFF0F0D18),
    surfaceContainerLow: Color(0xFF1D1A2C),
    surfaceContainer: Color(0xFF272339),
    surfaceContainerHigh: Color(0xFF322D49),
    surfaceContainerHighest: Color(0xFF3E3858),
    outline: Color(0xFF8C89AA),
    outlineVariant: Color(0xFF2C2840),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFFB7AEFF),
    inverseSurface: Color(0xFFECEAF8),
    onInverseSurface: Color(0xFF1D1B2E),
    inversePrimary: Color(0xFF5144C9),
  );
}
