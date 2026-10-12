import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/features/auth/providers/auth_providers.dart';
import 'package:animal/shared/widgets/app_mark.dart';
import 'package:animal/shared/widgets/tonal_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
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
    final scheme = theme.colorScheme;
    final colors = StatusColors.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -110,
            child: _Blob(size: 320, color: scheme.primaryContainer),
          ),
          Positioned(
            bottom: -70,
            left: -120,
            child: _Blob(size: 340, color: colors.airingContainer),
          ),
          Positioned(
            top: 330,
            right: -140,
            child: _Blob(size: 220, color: colors.upcomingContainer),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl + AppSpacing.xs,
                AppSpacing.xxl,
                AppSpacing.xl + AppSpacing.xs,
                AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  // App mark
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.30),
                          blurRadius: 36,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: const AppMark(),
                  ),
                  const SizedBox(height: AppSpacing.xl + AppSpacing.xs),

                  // Title
                  Text('AniMAL', style: theme.textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Unofficial MyAnimeList client',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final controller = ref.read(
                          authControllerProvider.notifier,
                        );
                        final url = await controller.getAuthorizationUrl();

                        try {
                          final launched = await launchUrl(url);
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
                  const SizedBox(height: AppSpacing.md),

                  // Manual code entry (fallback)
                  SizedBox(
                    width: double.infinity,
                    child: TonalButton(
                      onPressed: () => _showCodeInputDialog(context, ref),
                      child: const Text('Enter code manually'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Info text
                  Text(
                    'You will be redirected to MyAnimeList to authorize '
                    'this app, then sent back here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog(BuildContext context, String url) {
    unawaited(
      showDialog<void>(
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
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
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
      ),
    );
  }

  Future<void> _showCodeInputDialog(BuildContext context, WidgetRef ref) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _CodeInputDialog(),
    );
    if (code == null) return;
    try {
      await ref.read(authControllerProvider.notifier).exchangeCode(code);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Login successful!')));
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    }
  }
}

/// A blurred colour blob behind the login content.
class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _CodeInputDialog extends StatefulWidget {
  const _CodeInputDialog();

  @override
  State<_CodeInputDialog> createState() => _CodeInputDialogState();
}

class _CodeInputDialogState extends State<_CodeInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Authorization Code'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Paste the code from MAL'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final code = _controller.text.trim();
            if (code.isNotEmpty) Navigator.pop(context, code);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
