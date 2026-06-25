import 'dart:async';

import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:animal/core/theme/app_theme.dart';
import 'package:animal/shared/providers/theme_providers.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<int>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_initDeepLinks());
    _initNotificationListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) _handleLink(initialLink);

    _linkSubscription = appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'animal' &&
        uri.host == 'oauth' &&
        uri.path == '/callback') {
      final code = uri.queryParameters['code'];
      if (code != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(routerProvider).go('/oauth/callback?code=$code');
          }
        });
      }
    }
  }

  void _initNotificationListener() {
    final service = ref.read(notificationServiceProvider);
    final launchId = service.consumeLaunchAnimeId();
    if (launchId != null) _openAnime(launchId);
    _notificationSubscription = service.onNotificationTapped.listen(_openAnime);
  }

  void _openAnime(int animeId) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(routerProvider)
          .pushNamed(
            'animeDetail',
            pathParameters: {'id': '$animeId'},
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AniMAL',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
