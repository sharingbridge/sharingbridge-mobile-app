import 'auth_session_holder.dart';
import 'auth_session_store.dart';

/// Clears Google/dev session from memory and device storage.
Future<void> clearAuthSession() async {
  await AuthSessionStore().clear();
  AuthSessionHolder.clear();
}
