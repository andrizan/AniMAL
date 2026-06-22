import 'dart:async';

import 'package:animal/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Login page with MyAnimeList OAuth.
///
/// Launches the MAL consent screen in the browser. After the user
/// authorizes, MAL redirects to the app's callback URL which
/// exchanges the code for tokens.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.movie_outlined,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'AniMAL',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unofficial MyAnimeList client',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final controller = ref.read(
                        authControllerProvider.notifier,
                      );
                      final url = await controller.getAuthorizationUrl();

                      try {
                        final launched = await launchUrl(
                          url,
                        );
                        if (!launched && context.mounted) {
                          _showUrlDialog(context, url.toString());
                        }
                      } on Exception {
                        if (context.mounted) {
                          _showUrlDialog(context, url.toString());
                        }
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Login with MyAnimeList'),
                  ),
                ),
                const SizedBox(height: 16),

                // Info text
                Text(
                  'You will be redirected to MyAnimeList to authorize '
                  'this app. After authorization, you will be '
                  'redirected back here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Manual code entry (fallback)
                OutlinedButton(
                  onPressed: () => _showCodeInputDialog(context, ref),
                  child: const Text('Enter code manually'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUrlDialog(BuildContext context, String url) {
    unawaited(showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Copy and open this URL in your browser:'),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    ));
  }

  void _showCodeInputDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();

    unawaited(showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Authorization Code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: 'Paste the code from MAL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .exchangeCode(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login successful!'),
                      ),
                    );
                  }
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    ));
  }
}
