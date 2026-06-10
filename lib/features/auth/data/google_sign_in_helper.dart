import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// `google_sign_in` supports Android, iOS, and macOS — not Windows or Linux.
bool googleSignInSupportedOnPlatform() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS =>
      true,
    _ => false,
  };
}

GoogleSignIn createGoogleSignIn({required String googleClientId}) {
  return GoogleSignIn(
    scopes: const <String>['email', 'profile'],
    clientId: googleClientId.isNotEmpty ? googleClientId : null,
    serverClientId: googleClientId.isNotEmpty ? googleClientId : null,
  );
}

/// Clears the cached Google account so the next sign-in can pick another user.
Future<void> disconnectGoogleSignIn({required String googleClientId}) async {
  if (!googleSignInSupportedOnPlatform()) {
    return;
  }
  final googleSignIn = createGoogleSignIn(googleClientId: googleClientId);
  try {
    await googleSignIn.disconnect();
  } on MissingPluginException {
    return;
  } catch (_) {
    try {
      await googleSignIn.signOut();
    } on MissingPluginException {
      return;
    } catch (_) {
      // Best-effort — local session is still cleared.
    }
  }
}
