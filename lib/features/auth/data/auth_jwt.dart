import 'dart:convert';

/// True when the JWT is missing, malformed, or past `exp` (with optional leeway).
bool isAuthJwtExpired(
  String token, {
  Duration leeway = const Duration(seconds: 30),
}) {
  final parts = token.split('.');
  if (parts.length != 3) {
    return true;
  }
  try {
    final normalized = base64Url.normalize(parts[1]);
    final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
    if (decoded is! Map<String, dynamic>) {
      return true;
    }
    final exp = decoded['exp'];
    if (exp is! num) {
      return true;
    }
    final expiryMs = exp.toInt() * 1000;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return nowMs >= expiryMs - leeway.inMilliseconds;
  } catch (_) {
    return true;
  }
}
