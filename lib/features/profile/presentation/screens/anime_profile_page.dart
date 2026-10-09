import 'dart:async';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/utils/version_utils.dart';
import 'package:animal/features/profile/presentation/widgets/api_status_section.dart';
import 'package:animal/features/profile/presentation/widgets/profile_header.dart';
import 'package:animal/features/profile/presentation/widgets/profile_sections.dart';
import 'package:animal/features/profile/providers/profile_providers.dart';
import 'package:animal/shared/providers/theme_providers.dart';
import 'package:animal/shared/widgets/section_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile page showing real user info from MyAnimeList.
class AnimeProfilePage extends ConsumerWidget {
  const AnimeProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn =
        ref.watch(authControllerProvider) == AuthStatus.authenticated;
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (signedIn) ..._accountSections(ref) else const _SignInCard(),
          const ApiStatusSection(),
          const SizedBox(height: 24),
          const SectionHeader('Settings'),
          ProfileCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('MyAnimeList Account'),
                  subtitle: Text(signedIn ? 'Connected' : 'Tap to login'),
                  trailing: signedIn
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.statusAiring,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    if (!signedIn) unawaited(context.pushNamed('login'));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(
                    themeMode == ThemeMode.dark ? 'Dark' : 'Light',
                  ),
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('AniMAL'),
                  onTap: () async {
                    final packageInfo = await PackageInfo.fromPlatform();
                    if (!context.mounted) return;
                    showAboutDialog(
                      context: context,
                      applicationName: 'AniMAL',
                      applicationVersion: 'v${packageInfo.version}',
                      applicationLegalese: 'Unofficial MyAnimeList client',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('GitHub'),
                  subtitle: const Text('View source code'),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _launchGitHub(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.system_update),
                  title: const Text('Check for Update'),
                  subtitle: const Text('Check latest release'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _checkForUpdate(context, ref.read(latestReleaseProvider)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (signedIn)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Logged out')));
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _accountSections(WidgetRef ref) {
    final asyncUser = ref.watch(userInfoProvider);
    final user = asyncUser.value;
    final stats = user?.animeStatistics;

    return [
      asyncUser.when(
        skipLoadingOnReload: true,
        loading: () => const ProfileHeaderPlaceholder(),
        error: (error, _) =>
            ProfileHeaderError(onRetry: () => ref.invalidate(userInfoProvider)),
        data: (user) => user == null
            ? const SizedBox.shrink()
            : ProfileHeader(
                user: user,
                onRefresh: () => ref.invalidate(userInfoProvider),
              ),
      ),
      if (stats != null) ...[
        const SizedBox(height: 12),
        LibrarySection(stats: stats),
        const SizedBox(height: 12),
        TimeInvestedSection(stats: stats),
      ],
      if (user != null) ...[
        const SizedBox(height: 12),
        const InsightsSection(),
      ],
      const SizedBox(height: 24),
    ];
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ProfileCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Connect MyAnimeList',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Log in to see your library stats and charts.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => unawaited(context.pushNamed('login')),
                child: const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _launchGitHub() async {
  final url = Uri.parse(Env.githubRepoUrl);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

Future<void> _checkForUpdate(
  BuildContext context,
  Future<Map<String, dynamic>?> Function() fetchRelease,
) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final data = await fetchRelease();
    if (!context.mounted) return;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates')),
      );
      return;
    }

    final tagName = (data['tag_name'] as String?) ?? '';
    final latestVersion = tagName.replaceFirst('v', '');
    final htmlUrl = (data['html_url'] as String?) ?? '';
    final body = (data['body'] as String?) ?? '';

    if (!context.mounted) return;

    if (!isNewerVersion(latestVersion, currentVersion)) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Up to Date'),
          content: Text(
            'You are running the latest version (v$currentVersion).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update Available'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('v$currentVersion → v$latestVersion'),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(body, style: Theme.of(ctx).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(
                  launchUrl(
                    Uri.parse(htmlUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                );
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );
    }
  } on Exception catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Failed to check update: $e')));
  }
}
