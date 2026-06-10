import 'package:shared_preferences/shared_preferences.dart';

import '../../../presentation/handoff_gate_ack_store.dart';
import 'auth_session_holder.dart';
import 'auth_session_store.dart';

/// When true, [AuthGate] skips `--dart-define=AUTH_TOKEN` auto-login until the
/// user signs in with Google again.
const String kExplicitSignOutKey = 'sharingbridge_explicit_sign_out_v1';

/// Clears Google/dev session from memory and device storage.
///
/// [recordExplicitSignOut] blocks dev-token auto-login on the next app start.
Future<void> clearAuthSession({bool recordExplicitSignOut = true}) async {
  await AuthSessionStore().clear();
  await HandoffGateAckStore().clear();
  AuthSessionHolder.clear();
  if (recordExplicitSignOut) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kExplicitSignOutKey, true);
  }
}

Future<bool> hasExplicitSignOut() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kExplicitSignOutKey) ?? false;
}

/// Call after a successful Google sign-in (or valid restored donor session).
Future<void> clearExplicitSignOutFlag() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kExplicitSignOutKey);
}
