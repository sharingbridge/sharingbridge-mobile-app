import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/auth_api_client.dart';
import '../data/auth_session_store.dart';
import '../data/auth_session_holder.dart';

/// `google_sign_in` supports Android, iOS, and macOS — not Windows or Linux.
bool googleSignInSupportedOnPlatform() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS =>
      true,
    _ => false,
  };
}

String _unsupportedPlatformName() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => 'Windows',
    TargetPlatform.linux => 'Linux',
    _ => defaultTargetPlatform.name,
  };
}

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    required this.userServiceBaseUrl,
    required this.googleClientId,
    required this.onSignedIn,
  });

  final String userServiceBaseUrl;
  final String googleClientId;
  final VoidCallback onSignedIn;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    if (!googleSignInSupportedOnPlatform()) {
      setState(() => _error = _unsupportedPlatformMessage());
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const <String>['email', 'profile'],
        clientId: widget.googleClientId.isNotEmpty
            ? widget.googleClientId
            : null,
        serverClientId: widget.googleClientId.isNotEmpty
            ? widget.googleClientId
            : null,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _error = 'Google sign-in was cancelled.');
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        setState(() => _error = 'Google did not return an id token.');
        return;
      }
      final clientType = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => 'mobile',
      };
      final result = await AuthApiClient(
        userServiceBaseUrl: widget.userServiceBaseUrl,
      ).signInWithGoogle(idToken: idToken, clientType: clientType);
      if (result.role != 'donor') {
        setState(() {
          _error =
              'This Google account is a coordinator. Use the web dashboard instead.';
        });
        return;
      }
      await AuthSessionStore().save(
        StoredAuthSession(
          userId: result.userId,
          token: result.token,
          role: result.role,
          email: result.email,
          name: result.name,
        ),
      );
      AuthSessionHolder.setSession(
        userId: result.userId,
        token: result.token,
      );
      widget.onSignedIn();
    } on AuthApiException catch (e) {
      setState(() => _error = e.message);
    } on MissingPluginException {
      setState(() => _error = _unsupportedPlatformMessage());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _unsupportedPlatformMessage() {
    final platform = _unsupportedPlatformName();
    return 'Google Sign-In is not available on $platform. '
        'The mobile plugin supports Android, iOS, and macOS only. '
        'Use an Android emulator or device with an Android OAuth client from '
        'Google Cloud Console (package name + SHA-1), or pass '
        '--dart-define=AUTH_TOKEN=… for dev testing on desktop.';
  }

  @override
  Widget build(BuildContext context) {
    final googleSupported = googleSignInSupportedOnPlatform();
    return Scaffold(
      appBar: AppBar(title: const Text('SharingBridge')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Donor sign in',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in with Google to save presets and register order '
              'initiations. Coordinators must use the web dashboard.',
            ),
            const SizedBox(height: 24),
            if (!googleSupported) ...<Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _unsupportedPlatformMessage(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: (!googleSupported || _loading)
                  ? null
                  : () => _signInWithGoogle(),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_loading ? 'Signing in…' : 'Continue with Google'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (widget.googleClientId.isEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                'Set --dart-define=GOOGLE_CLIENT_ID=… from Google Cloud Console.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
