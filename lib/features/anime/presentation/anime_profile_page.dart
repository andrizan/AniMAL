import 'dart:async';

import 'package:animal/core/theme/theme_provider.dart';
import 'package:animal/features/anime/presentation/anime_profile_controller.dart';
import 'package:animal/features/auth/presentation/auth_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.error, color: Colors.white),
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
                      onPressed: () =>
                          ref.invalidate(userInfoProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (user) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      backgroundImage: user.picture != null
                          ? CachedNetworkImageProvider(user.picture!)
                          : null,
                      child: user.picture == null
                          ? Icon(
                              Icons.person,
                              size: 32,
                              color:
                                  theme.colorScheme.onPrimaryContainer,
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
                              color: Colors.green,
                            ),
                          ),
                          if (user.location != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: theme
                                      .colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.location!,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant,
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
                      onPressed: () =>
                          ref.invalidate(userInfoProvider),
                    ),
                  ],
                ),
              ),
            ),
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
                final stats = user.animeStatistics;
                if (stats == null) return const SizedBox.shrink();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _StatRow(
                          label: 'Days Watched',
                          value: stats.numDaysWatched
                                  ?.toStringAsFixed(1) ??
                              '0',
                        ),
                        _StatRow(
                          label: 'Mean Score',
                          value: stats.meanScore
                                  ?.toStringAsFixed(2) ??
                              '-',
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
                          color: Colors.green,
                        ),
                        _StatRow(
                          label: 'Completed',
                          value: '${stats.numItemsCompleted ?? 0}',
                          color: Colors.blue,
                        ),
                        _StatRow(
                          label: 'On Hold',
                          value: '${stats.numItemsOnHold ?? 0}',
                          color: Colors.orange,
                        ),
                        _StatRow(
                          label: 'Dropped',
                          value: '${stats.numItemsDropped ?? 0}',
                          color: Colors.red,
                        ),
                        _StatRow(
                          label: 'Plan to Watch',
                          value:
                              '${stats.numItemsPlanToWatch ?? 0}',
                          color: Colors.purple,
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
                      ? const Icon(Icons.check_circle,
                          color: Colors.green)
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
                    themeMode == ThemeMode.system
                        ? Icons.brightness_auto
                        : themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(
                    themeMode == ThemeMode.system
                        ? 'System'
                        : themeMode == ThemeMode.dark
                            ? 'Dark'
                            : 'Light',
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox.shrink(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('AniMAL v1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'AniMAL',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Unofficial MyAnimeList client',
                    );
                  },
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
                  await ref
                      .read(authControllerProvider.notifier)
                      .logout();
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
