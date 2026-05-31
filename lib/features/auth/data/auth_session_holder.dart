import '../../donor_setup/data/auth_context.dart';

/// Holds the signed-in user's JWT in memory after Google sign-in.
///
/// The token is minted once by user-service (`POST /v1/auth/google`) and stored
/// here (and on disk via [AuthSessionStore]). [resolve] returns that same JWT
/// until [clear]; it does not contact the server again.
///
/// Falls back to [AuthContext.fromEnvironment] when unset (dev
/// `--dart-define=AUTH_TOKEN=...`).
class AuthSessionHolder {
  AuthSessionHolder._();

  static AuthContext? _session;

  /// Current credentials (same JWT string until [clear] or a new sign-in).
  static AuthContext resolve() =>
      _session ?? AuthContext.fromEnvironment();

  static void setSession({
    required String userId,
    required String token,
  }) {
    _session = AuthContext(userId: userId, authToken: token);
  }

  static void clear() {
    _session = null;
  }
}
