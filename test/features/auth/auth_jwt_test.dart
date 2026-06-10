import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/auth/data/auth_jwt.dart';

String _jwtWithExp(int expUnix) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode('{"sub":"u1","exp":$expUnix}'),
  );
  return '$header.$payload.sig';
}

void main() {
  test('isAuthJwtExpired is false for future exp', () {
    final exp = DateTime.now().toUtc().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    expect(isAuthJwtExpired(_jwtWithExp(exp)), isFalse);
  });

  test('isAuthJwtExpired is true for past exp', () {
    final exp = DateTime.now().toUtc().subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000;
    expect(isAuthJwtExpired(_jwtWithExp(exp)), isTrue);
  });

  test('isAuthJwtExpired is true for malformed token', () {
    expect(isAuthJwtExpired('not-a-jwt'), isTrue);
  });
}
