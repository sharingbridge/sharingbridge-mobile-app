import '../../donor_setup/data/auth_context.dart';

/// Runtime session after Google sign-in (overrides compile-time defines).
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
