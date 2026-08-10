import 'dart:io';

import '../../../config/integration_api_paths.dart';

/// User id plus the integration-service Bearer JWT for API calls.
///
/// In the app, use [AuthSessionHolder.resolve] so HTTP clients pick up the JWT
/// saved at sign-in. The JWT is minted once per sign-in (user-service), not per
/// API request. Dev fallback: `--dart-define=AUTH_TOKEN=...` (JWT signed with
/// the same AUTH_TOKEN_SECRET — see user-service `tools/MintDevJwt`).
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
    final uri = Uri.parse('$baseUrl${IntegrationApiPaths.preferences}');
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
