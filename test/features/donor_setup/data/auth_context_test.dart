import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/auth_context.dart';

void main() {
  group('withOptionalUserId', () {
    test('omits user_id when Bearer token is set', () {
      const ctx = AuthContext(userId: 'alice', authToken: 'signed.jwt');
      final body = ctx.withOptionalUserId(<String, dynamic>{'pack_id': 'p1'});
      expect(body.containsKey('user_id'), isFalse);
      expect(body['pack_id'], 'p1');
    });

    test('includes user_id when no Bearer token', () {
      const ctx = AuthContext(userId: 'demo-user', authToken: '');
      final body = ctx.withOptionalUserId(<String, dynamic>{'pack_id': 'p1'});
      expect(body['user_id'], 'demo-user');
    });

    test('uses explicitUserId when no Bearer token', () {
      const ctx = AuthContext(userId: 'alice', authToken: '');
      final body = ctx.withOptionalUserId(
        <String, dynamic>{'pack_id': 'p1'},
        explicitUserId: 'bob',
      );
      expect(body['user_id'], 'bob');
    });

    test('ignores mismatched explicitUserId when Bearer token is set', () {
      const ctx = AuthContext(userId: 'alice', authToken: 'signed.jwt');
      final body = ctx.withOptionalUserId(
        <String, dynamic>{
          'pack_id': 'p1',
          if (true) 'status': 'instructions_copied',
          if (false) 'order_intent_id': 'skip',
        },
        explicitUserId: 'bob',
      );
      expect(body.containsKey('user_id'), isFalse);
      expect(body['status'], 'instructions_copied');
      expect(body.containsKey('order_intent_id'), isFalse);
    });
  });

  group('userIdQueryParameters', () {
    test('empty when Bearer token is set', () {
      const ctx = AuthContext(userId: 'alice', authToken: 'signed.jwt');
      expect(ctx.userIdQueryParameters(), isEmpty);
    });

    test('includes user_id when no Bearer token', () {
      const ctx = AuthContext(userId: 'demo-user', authToken: '');
      expect(ctx.userIdQueryParameters(), <String, String>{'user_id': 'demo-user'});
    });
  });

  group('donorSetupPreferencesUri', () {
    test('omits query when Bearer token is set', () {
      const ctx = AuthContext(userId: 'alice', authToken: 'signed.jwt');
      final uri = ctx.donorSetupPreferencesUri('http://localhost:8080');
      expect(uri.query, isEmpty);
      expect(uri.path, '/v1/donor-setup/preferences');
    });

    test('adds user_id query when no Bearer token', () {
      const ctx = AuthContext(userId: 'demo-user', authToken: '');
      final uri = ctx.donorSetupPreferencesUri(
        'http://localhost:8080',
        explicitUserId: 'demo-user',
      );
      expect(uri.queryParameters['user_id'], 'demo-user');
    });
  });
}