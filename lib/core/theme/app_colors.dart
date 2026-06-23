import 'package:flutter/material.dart';

// ── Custom Theme Extension ────────────────────────────────────

class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.airing,
    required this.finished,
    required this.upcoming,
    required this.star,
    required this.listWatching,
    required this.listCompleted,
    required this.listOnHold,
    required this.listDropped,
    required this.listPlanToWatch,
    required this.overlayDark,
    required this.overlayDarker,
    required this.barrier,
  });

  final Color airing;
  final Color finished;
  final Color upcoming;
  final Color star;
  final Color listWatching;
  final Color listCompleted;
  final Color listOnHold;
  final Color listDropped;
  final Color listPlanToWatch;
  final Color overlayDark;
  final Color overlayDarker;
  final Color barrier;

  @override
  ThemeExtension<StatusColors> copyWith({
    Color? airing,
    Color? finished,
    Color? upcoming,
    Color? star,
    Color? listWatching,
    Color? listCompleted,
    Color? listOnHold,
    Color? listDropped,
    Color? listPlanToWatch,
    Color? overlayDark,
    Color? overlayDarker,
    Color? barrier,
  }) {
    return StatusColors(
      airing: airing ?? this.airing,
      finished: finished ?? this.finished,
      upcoming: upcoming ?? this.upcoming,
      star: star ?? this.star,
      listWatching: listWatching ?? this.listWatching,
      listCompleted: listCompleted ?? this.listCompleted,
      listOnHold: listOnHold ?? this.listOnHold,
      listDropped: listDropped ?? this.listDropped,
      listPlanToWatch: listPlanToWatch ?? this.listPlanToWatch,
      overlayDark: overlayDark ?? this.overlayDark,
      overlayDarker: overlayDarker ?? this.overlayDarker,
      barrier: barrier ?? this.barrier,
    );
  }

  @override
  ThemeExtension<StatusColors> lerp(
    covariant ThemeExtension<StatusColors>? other,
    double t,
  ) {
    if (other is! StatusColors) return this;
    return StatusColors(
      airing: Color.lerp(airing, other.airing, t)!,
      finished: Color.lerp(finished, other.finished, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      star: Color.lerp(star, other.star, t)!,
      listWatching: Color.lerp(listWatching, other.listWatching, t)!,
      listCompleted: Color.lerp(listCompleted, other.listCompleted, t)!,
      listOnHold: Color.lerp(listOnHold, other.listOnHold, t)!,
      listDropped: Color.lerp(listDropped, other.listDropped, t)!,
      listPlanToWatch: Color.lerp(listPlanToWatch, other.listPlanToWatch, t)!,
      overlayDark: Color.lerp(overlayDark, other.overlayDark, t)!,
      overlayDarker: Color.lerp(overlayDarker, other.overlayDarker, t)!,
      barrier: Color.lerp(barrier, other.barrier, t)!,
    );
  }
}

// ── Color Palette ─────────────────────────────────────────────

abstract final class AppColors {
  // ── Theme Extensions ──
  static const lightStatus = StatusColors(
    airing: Color(0xFF10B981), // Soft Emerald
    finished: Color(0xFF3B82F6), // Soft Blue
    upcoming: Color(0xFFF59E0B), // Soft Amber
    star: Color(0xFFFBBF24), // Warm Gold
    listWatching: Color(0xFF10B981), // Senada dengan Airing
    listCompleted: Color(0xFF3B82F6), // Senada dengan Finished
    listOnHold: Color(0xFFF59E0B), // Senada dengan Upcoming
    listDropped: Color(0xFFEF4444), // Soft Red
    listPlanToWatch: Color(0xFF64748B), // Slate 500
    overlayDark: Color(0x660F172A), // 40% Slate Base (Bukan hitam pekat)
    overlayDarker: Color(0x990F172A), // 60% Slate Base
    barrier: Color(0xCC0F172A), // 80% Slate Base
  );

  static const darkStatus = StatusColors(
    airing: Color(0xFF34D399), // Emerald lebih cerah untuk kontras dark mode
    finished: Color(0xFF60A5FA), // Blue lebih cerah
    upcoming: Color(0xFFFBBF24), // Amber lebih cerah
    star: Color(0xFFFBBF24),
    listWatching: Color(0xFF34D399),
    listCompleted: Color(0xFF60A5FA),
    listOnHold: Color(0xFFFBBF24),
    listDropped: Color(0xFFF87171), // Soft Red terang
    listPlanToWatch: Color(0xFF94A3B8), // Slate 400
    overlayDark: Color(0x660F172A),
    overlayDarker: Color(0x990F172A),
    barrier: Color(0xCC0F172A),
  );

  // ── Static fallbacks (untuk kode tanpa BuildContext) ──
  // Disamakan nilainya dengan lightStatus agar konsisten jika dipanggil statis
  static const starColor = Color(0xFFFBBF24);
  static const statusAiring = Color(0xFF10B981);
  static const statusFinished = Color(0xFF3B82F6);
  static const statusUpcoming = Color(0xFFF59E0B);
  static const statusDefault = Color(0xFF64748B);

  static const listWatching = Color(0xFF10B981);
  static const listCompleted = Color(0xFF3B82F6);
  static const listOnHold = Color(0xFFF59E0B);
  static const listDropped = Color(0xFFEF4444);
  static const listPlanToWatch = Color(0xFF64748B);

  static const transparent = Color(0x00000000);
  static const overlayDark = Color(0x660F172A);
  static const overlayDarker = Color(0x990F172A);
  static const barrier = Color(0xCC0F172A);
  static const iconLight = Color(0xFFF8FAFC);
  static const iconSubtle = Color(0x8AF8FAFC);

  // ── Light ColorScheme ──
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6366F1),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E7FF),
    onPrimaryContainer: Color(0xFF1E1B4B),
    secondary: Color(0xFF14B8A6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCCFBF1),
    onSecondaryContainer: Color(0xFF134E4A),
    tertiary: Color(0xFFF59E0B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF78350F),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF475569),
    surfaceDim: Color(0xFFE2E8F0),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFCBD5E1),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Color(0xFF0F172A),
    scrim: Color(0xFF0F172A),
    surfaceTint: Color(0xFF6366F1),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFFA5B4FC),
  );

  // ── Dark ColorScheme ──
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF818CF8),
    onPrimary: Color(0xFF1E1B4B),
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF2DD4BF),
    onSecondary: Color(0xFF134E4A),
    secondaryContainer: Color(0xFF115E59),
    onSecondaryContainer: Color(0xFFCCFBF1),
    tertiary: Color(0xFFFBBF24),
    onTertiary: Color(0xFF451A03),
    tertiaryContainer: Color(0xFF78350F),
    onTertiaryContainer: Color(0xFFFDE68A),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFF8FAFC),
    onSurfaceVariant: Color(0xFF94A3B8),
    surfaceDim: Color(0xFF020617),
    surfaceBright: Color(0xFF1E293B),
    surfaceContainerLowest: Color(0xFF020617),
    surfaceContainerLow: Color(0xFF0F172A),
    surfaceContainer: Color(0xFF1E293B),
    surfaceContainerHigh: Color(0xFF334155),
    surfaceContainerHighest: Color(0xFF475569),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFF334155),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF818CF8),
    inverseSurface: Color(0xFFF1F5F9),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: Color(0xFF4338CA),
  );
}
