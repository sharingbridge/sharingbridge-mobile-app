import 'package:flutter/material.dart';

import '../data/auth_logout.dart';
import 'auth_gate.dart';

/// Clears auth and returns to the sign-in screen (new [AuthGate] root).
Future<void> signOutAndReturnToLogin(BuildContext context) async {
  await clearAuthSession();
  if (!context.mounted) {
    return;
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthGate()),
    (Route<dynamic> route) => false,
  );
}
