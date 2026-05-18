import 'dart:convert';
import 'dart:io';

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class AuthSignInResult {
  const AuthSignInResult({
    required this.token,
    required this.userId,
    required this.role,
    this.email,
    this.name,
  });

  final String token;
  final String userId;
  final String role;
  final String? email;
  final String? name;
}

class AuthApiClient {
  AuthApiClient({
    required this.userServiceBaseUrl,
    HttpClient? httpClient,
  }) : _http = httpClient ?? HttpClient();

  final String userServiceBaseUrl;
  final HttpClient _http;

  Future<AuthSignInResult> signInWithGoogle({
    required String idToken,
    String clientType = 'android',
  }) async {
    final base = userServiceBaseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/v1/auth/google');
    final request = await _http.postUrl(uri);
    request.headers.set('accept', 'application/json');
    request.headers.set('content-type', 'application/json');
    request.write(
      jsonEncode(<String, dynamic>{
        'id_token': idToken,
        'client_type': clientType,
      }),
    );
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    final Map<String, dynamic> body = _decodeBody(text);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        body['message']?.toString() ??
            'Sign-in failed (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
        code: body['code']?.toString(),
      );
    }

    final token = body['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw AuthApiException('Sign-in response missing token.');
    }
    final user = body['user'];
    final userMap =
        user is Map ? Map<String, dynamic>.from(user) : <String, dynamic>{};
    final userId =
        userMap['user_id']?.toString() ?? userMap['id']?.toString() ?? '';
    if (userId.isEmpty) {
      throw AuthApiException('Sign-in response missing user id.');
    }
    return AuthSignInResult(
      token: token,
      userId: userId,
      role: userMap['role']?.toString() ?? 'donor',
      email: userMap['email']?.toString(),
      name: userMap['name']?.toString(),
    );
  }

  Map<String, dynamic> _decodeBody(String text) {
    if (text.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw AuthApiException('Sign-in response was not valid JSON.');
    }
  }
}
