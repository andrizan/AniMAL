import 'dart:async';

import 'package:animal/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Handles the OAuth callback from MyAnimeList.
///
/// Receives the authorization [code] from the redirect URL,
/// exchanges it for tokens, then navigates to home.
class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({super.key, this.code});

  final String? code;

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_handleCallback());
  }

  Future<void> _handleCallback() async {
    final code = widget.code;

    if (code == null || code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No authorization code received')),
        );
        context.go('/login');
      }
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).exchangeCode(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        context.go('/');
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Logging in to MyAnimeList…'),
          ],
        ),
      ),
    );
  }
}
