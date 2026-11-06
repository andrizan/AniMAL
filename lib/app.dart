import 'dart:async';

import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:animal/core/router/deep_links.dart';
import 'package:animal/core/theme/app_theme.dart';
import 'package:animal/core/utils/update_check.dart';
import 'package:animal/shared/providers/theme_providers.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<int>? _notificationSubscription;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  Uri? _lastLink;
  DateTime? _lastLinkAt;

  static const _linkRepeatWindow = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    unawaited(_initDeepLinks());
    _initNotificationListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_announceUpdate());
    });
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel() ?? Future<void>.value());
    unawaited(_notificationSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) _handleLink(initialLink);

    _linkSubscription = appLinks.uriLinkStream.listen(_handleLink);
  }

  /// Tells the user, once per launch, when a newer release is published.
  Future<void> _announceUpdate() async {
    final update = await findNewerRelease(
      fetchRelease: ref.read(latestReleaseProvider),
      currentVersion: ref.read(appVersionProvider),
    );
    if (update == null || !mounted) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('AniMAL v${update.version} is available'),
        duration: const Duration(seconds: 12),
        persist: false,
        showCloseIcon: true,
        action: SnackBarAction(
          label: 'Download',
          onPressed: () => unawaited(
            launchUrl(
              Uri.parse(update.url),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ),
      ),
    );
  }

  void _handleLink(Uri uri) {
    if (!mounted) return;
    final location = oauthCallbackLocation(uri);
    if (location != null) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (mounted) ref.read(routerProvider).go(location);
        })
        ..ensureVisualUpdate();
      return;
    }
    if (malAnimeId(uri) case final animeId? when !_isRepeat(uri)) {
      unawaited(_openAnime(animeId));
    }
  }

  /// The link that launched the app reaches [_handleLink] twice: from
  /// `getInitialLink` and again from the stream. Opening it twice would stack
  /// two detail pages.
  bool _isRepeat(Uri uri) {
    final now = DateTime.now();
    final repeat =
        uri == _lastLink &&
        now.difference(_lastLinkAt ?? now) < _linkRepeatWindow;
    _lastLink = uri;
    _lastLinkAt = now;
    return repeat;
  }

  void _initNotificationListener() {
    final service = ref.read(notificationServiceProvider);
    final launchId = service.consumeLaunchAnimeId();
    if (launchId != null) unawaited(_openAnime(launchId));
    _notificationSubscription = service.onNotificationTapped.listen(
      (animeId) => unawaited(_openAnime(animeId)),
    );
  }

  Future<void> _openAnime(int animeId) async {
    if (!mounted) return;
    final router = ref.read(routerProvider);
    var status = ref.read(authControllerProvider);
    if (status == AuthStatus.unknown) status = await _signInResolved();
    if (!mounted || status != AuthStatus.authenticated) return;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          router.pushNamed('animeDetail', pathParameters: {'id': '$animeId'}),
        );
      })
      ..ensureVisualUpdate();
  }

  /// A link or notification that launches the app arrives before the stored
  /// sign-in has been read. Until then the auth guard treats the user as
  /// signed out and would send the page to login, then home.
  Future<AuthStatus> _signInResolved() {
    final done = Completer<AuthStatus>();
    final subscription = ref.listenManual(authControllerProvider, (_, status) {
      if (status != AuthStatus.unknown && !done.isCompleted) {
        done.complete(status);
      }
    });
    return done.future.whenComplete(subscription.close);
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
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
    );
  }
}
