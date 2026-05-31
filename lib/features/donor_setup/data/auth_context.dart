import 'dart:io';

/// Bearer JWT and user id for integration-service API calls.
///
/// Prefer [AuthSessionHolder.resolve]: after Google sign-in, the token comes
/// from user-service (`POST /v1/auth/google`). Dev fallback:
/// `--dart-define=AUTH_TOKEN=...` from `POST /v1/auth/token`.
class AuthContext {
  const AuthContext({required this.userId, required this.authToken});

  /// Builds the AuthContext from compile-time defines. The default keeps
  /// existing local-dev behavior backward compatible.
  factory AuthContext.fromEnvironment() {
    const userId = String.fromEnvironment(
      'USER_ID',
      defaultValue: 'demo-user',
    );
    const authToken = String.fromEnvironment('AUTH_TOKEN', defaultValue: '');
    return const AuthContext(userId: userId, authToken: authToken);
  }

  final String userId;
  final String authToken;

  String get bearerToken => authToken.trim();

  /// When a Bearer token is present, integration-service derives `user_id`
  /// from the JWT. Sending a different `user_id` in the body or query causes
  /// HTTP 403 `user_id_mismatch`.
  Map<String, String> userIdQueryParameters({String? explicitUserId}) {
    if (bearerToken.isNotEmpty) {
      return const <String, String>{};
    }
    return <String, String>{
      'user_id': (explicitUserId ?? userId).trim(),
    };
  }

  Uri donorSetupPreferencesUri(
    String baseUrl, {
    String? explicitUserId,
  }) {
    final uri = Uri.parse('$baseUrl/v1/donor-setup/preferences');
    final params = userIdQueryParameters(explicitUserId: explicitUserId);
    if (params.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: params);
  }

  Map<String, dynamic> withOptionalUserId(
    Map<String, dynamic> body, {
    String? explicitUserId,
  }) {
    if (bearerToken.isNotEmpty) {
      return body;
    }
    return <String, dynamic>{
      ...body,
      'user_id': (explicitUserId ?? userId).trim(),
    };
  }

  Map<String, String> toHeaders() {
    if (bearerToken.isEmpty) {
      return const <String, String>{};
    }
    return <String, String>{
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
    };
  }
}
