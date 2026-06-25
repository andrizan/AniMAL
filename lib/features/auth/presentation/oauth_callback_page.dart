import 'dart:async';

import 'package:animal/core/providers.dart';
import 'package:animal/core/storage/secure_token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Handles the OAuth callback from MyAnimeList.
///
/// Receives the authorization [code] and [state] from the redirect URL,
/// validates the state, exchanges the code for tokens, then navigates to home.
class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({super.key, this.code, this.state});

  final String? code;
  final String? state;

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
      if (mounted) _showErrorAndReturn('No authorization code received');
      return;
    }

    final tokenStorage = ref.read(tokenStorageProvider);
    final validState = await _validateState(tokenStorage);
    if (!validState) {
      if (mounted) _showErrorAndReturn('Invalid OAuth state');
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).exchangeCode(code);
      await tokenStorage.clearOAuthState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        context.go('/home');
      }
    } on Exception catch (e) {
      if (mounted) _showErrorAndReturn('Login failed: $e');
    }
  }

  Future<bool> _validateState(SecureTokenStorage tokenStorage) async {
    final returnedState = widget.state;
    if (returnedState == null || returnedState.isEmpty) return false;
    final storedState = await tokenStorage.getOAuthState();
    if (storedState == null || storedState.isEmpty) return false;
    return returnedState == storedState;
  }

  void _showErrorAndReturn(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    context.go('/login');
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
