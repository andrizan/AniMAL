import 'dart:async';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/providers/theme_providers.dart';
import 'package:animal/features/profile/providers/profile_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile page showing real user info from MyAnimeList.
class AnimeProfilePage extends ConsumerWidget {
  const AnimeProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authControllerProvider);
    final asyncUser = ref.watch(userInfoProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with real data
          asyncUser.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(radius: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loading...'),
                          SizedBox(height: 4),
                          Text('Fetching profile'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.error,
                      child: const Icon(
                        Icons.error,
                        color: AppColors.iconLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Failed to load profile',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check your connection',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(userInfoProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: user.picture != null
                            ? CachedNetworkImageProvider(user.picture!)
                            : null,
                        child: user.picture == null
                            ? Icon(
                                Icons.person,
                                size: 32,
                                color: theme.colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connected to MyAnimeList',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.statusAiring,
                              ),
                            ),
                            if (user.location != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.location!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => ref.invalidate(userInfoProvider),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Statistics section
          if (authStatus == AuthStatus.authenticated) ...[
            Text(
              'Statistics',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            asyncUser.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, _) => const SizedBox.shrink(),
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                final stats = user.animeStatistics;
                if (stats == null) return const SizedBox.shrink();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _StatRow(
                          label: 'Days Watched',
                          value:
                              stats.numDaysWatched?.toStringAsFixed(1) ?? '0',
                        ),
                        _StatRow(
                          label: 'Mean Score',
                          value: stats.meanScore?.toStringAsFixed(2) ?? '-',
                        ),
                        _StatRow(
                          label: 'Total Anime',
                          value: '${stats.numItems ?? 0}',
                        ),
                        _StatRow(
                          label: 'Episodes',
                          value: '${stats.numEpisodes ?? 0}',
                        ),
                        const Divider(),
                        _StatRow(
                          label: 'Watching',
                          value: '${stats.numItemsWatching ?? 0}',
                          color: AppColors.statusAiring,
                        ),
                        _StatRow(
                          label: 'Completed',
                          value: '${stats.numItemsCompleted ?? 0}',
                          color: AppColors.statusFinished,
                        ),
                        _StatRow(
                          label: 'On Hold',
                          value: '${stats.numItemsOnHold ?? 0}',
                          color: theme.colorScheme.tertiary,
                        ),
                        _StatRow(
                          label: 'Dropped',
                          value: '${stats.numItemsDropped ?? 0}',
                          color: theme.colorScheme.error,
                        ),
                        _StatRow(
                          label: 'Plan to Watch',
                          value: '${stats.numItemsPlanToWatch ?? 0}',
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Settings section
          Text(
            'Settings',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('MyAnimeList Account'),
                  subtitle: Text(
                    authStatus == AuthStatus.authenticated
                        ? 'Connected'
                        : 'Tap to login',
                  ),
                  trailing: authStatus == AuthStatus.authenticated
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.statusAiring,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    if (authStatus != AuthStatus.authenticated) {
                      unawaited(context.pushNamed('login'));
                    }
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
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('GitHub'),
                  subtitle: const Text('View source code'),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _launchGitHub(),
                ),
                ListTile(
                  leading: const Icon(Icons.system_update),
                  title: const Text('Check for Update'),
                  subtitle: const Text('Check latest release'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _checkForUpdate(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout button
          if (authStatus == AuthStatus.authenticated)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out')),
                    );
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
}

Future<void> _launchGitHub() async {
  final url = Uri.parse(Env.githubRepoUrl);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

Future<void> _checkForUpdate(BuildContext context) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final dio = Dio();
    try {
      final response = await dio.get<Map<String, dynamic>>(
        Env.githubReleasesUrl(Env.githubRepo),
      );

      final data = response.data ?? {};
      final tagName = (data['tag_name'] as String?) ?? '';
      final latestVersion = tagName.replaceFirst('v', '');
      final htmlUrl = (data['html_url'] as String?) ?? '';
      final body = (data['body'] as String?) ?? '';

      if (!context.mounted) return;

      if (latestVersion == currentVersion) {
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
    } finally {
      dio.close();
    }
  } on Exception catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to check update: $e')),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
