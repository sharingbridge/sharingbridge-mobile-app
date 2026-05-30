import '../../donor_setup/data/auth_context.dart';

/// In-memory session after Google sign-in (user-service JWT). Falls back to
/// [AuthContext.fromEnvironment] when unset (dev `--dart-define=AUTH_TOKEN`).
class AuthSessionHolder {
  AuthSessionHolder._();

  static AuthContext? _session;

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
