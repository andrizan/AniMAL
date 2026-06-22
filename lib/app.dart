import 'dart:async';

import 'package:animal/core/router/app_router.dart';
import 'package:animal/core/theme/theme_provider.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Root application widget.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_initDeepLinks());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Handle initial link (app opened via deep link)
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // Handle incoming links while app is running
    _linkSubscription = appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'animal' &&
        uri.host == 'oauth' &&
        uri.path == '/callback') {
      final code = uri.queryParameters['code'];
      if (code != null && mounted) {
        // Delay navigation until after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(routerProvider).go('/oauth/callback?code=$code');
          }
        });
      }
    }
  }

  static final _lightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
  );

  static final _darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );

  /// Base text theme using Inter with Noto Sans JP fallback.
  static TextTheme _baseTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? _darkColorScheme.onSurface
        : _lightColorScheme.onSurface;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AniMAL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: _lightColorScheme,
        textTheme: _baseTextTheme(Brightness.light),
        fontFamily: GoogleFonts.inter().fontFamily,
        fontFamilyFallback: const ['Noto Sans JP'],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: _darkColorScheme,
        textTheme: _baseTextTheme(Brightness.dark),
        fontFamily: GoogleFonts.inter().fontFamily,
        fontFamilyFallback: const ['Noto Sans JP'],
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
