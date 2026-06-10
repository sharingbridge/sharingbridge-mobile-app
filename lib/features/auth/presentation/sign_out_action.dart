import 'package:flutter/material.dart';

import '../../donor_setup/data/donor_setup_local_storage.dart';
import '../data/auth_logout.dart';
import '../data/google_sign_in_helper.dart';
import 'auth_gate.dart';

const String _googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: '',
);

Future<void> _leaveSessionAndReturnToLogin(BuildContext context) async {
  await clearDonorSetupPresetsCache();
  await clearAuthSession();
  if (!context.mounted) {
    return;
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthGate()),
    (Route<dynamic> route) => false,
  );
}

/// Clears auth and returns to the sign-in screen (new [AuthGate] root).
Future<void> signOutAndReturnToLogin(BuildContext context) async {
  await _leaveSessionAndReturnToLogin(context);
}

/// Disconnects Google and returns to sign-in so another account can be chosen.
Future<void> switchGoogleAccountAndReturnToLogin(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Switch Google account?'),
      content: const Text(
        'You will return to the sign-in screen and can choose a different '
        'Google account.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Switch account'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await disconnectGoogleSignIn(googleClientId: _googleClientId);
  await _leaveSessionAndReturnToLogin(context);
}
