import 'package:flutter/material.dart';

import '../../../presentation/donor_navigator_shell.dart';
import '../data/auth_logout.dart';
import '../data/auth_session_holder.dart';
import '../data/auth_session_store.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const String _userServiceBaseUrl = String.fromEnvironment(
    'USER_SERVICE_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  bool _ready = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    var signedIn = false;
    try {
      if (await hasExplicitSignOut()) {
        return;
      }
      final stored = await AuthSessionStore().load();
      if (stored != null &&
          stored.role == 'donor' &&
          stored.token.trim().isNotEmpty) {
        await clearExplicitSignOutFlag();
        AuthSessionHolder.setSession(
          userId: stored.userId,
          token: stored.token,
        );
        signedIn = true;
        return;
      }
      if (stored != null &&
          (stored.role != 'donor' || stored.token.trim().isEmpty)) {
        await AuthSessionStore().clear();
      }
      if (stored != null && stored.role != 'donor') {
        await AuthSessionStore().clear();
      }
      final envAuth = AuthSessionHolder.resolve();
      if (envAuth.bearerToken.isNotEmpty) {
        signedIn = true;
      }
    } finally {
      if (mounted) {
        setState(() {
          _signedIn = signedIn;
          _ready = true;
        });
      }
    }
  }

  void _handleSignedIn() {
    setState(() => _signedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_signedIn) {
      return SignInPage(
        userServiceBaseUrl: _userServiceBaseUrl,
        googleClientId: _googleClientId,
        onSignedIn: _handleSignedIn,
      );
    }
    return const DonorNavigatorShell();
  }
}
