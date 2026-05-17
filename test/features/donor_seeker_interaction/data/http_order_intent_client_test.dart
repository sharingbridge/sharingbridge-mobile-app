import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/auth_context.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/http_donor_setup_api_client.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/donor_preset.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/data/http_order_intent_client.dart';

typedef _Handler = FutureOr<void> Function(HttpRequest request);

class _ScriptedServer {
  _ScriptedServer(this._handler);

  final _Handler _handler;
  late final HttpServer _server;

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((HttpRequest request) async {
      await _handler(request);
    });
    return 'http://${_server.address.host}:${_server.port}';
  }

  Future<void> stop() => _server.close(force: true);
}

DonorPreset _samplePreset() {
  return DonorPreset(
    restaurantName: 'Ratna Cafe',
    orderUrl: 'https://example.com/order',
    menuItems: const <String>['Filter Coffee'],
    appName: 'Swiggy',
    source: 'test',
    confidence: 0.9,
  );
}

Map<String, dynamic> _orderIntentPostResponse() {
  return <String, dynamic>{
    'order_intent_id': 'oi-test-1',
    'pack_id': 'pack-1',
    'status': 'instructions_copied',
    'created_at': '2026-05-15T00:00:00Z',
    'created': true,
  };
}

void main() {
  group('HttpOrderIntentClient auth payload', () {
    test('registerInstructionsCopied omits user_id when Bearer is set', () async {
      String? bodyText;
      String? authHeader;
      final server = _ScriptedServer((HttpRequest request) async {
        authHeader = request.headers.value('authorization');
        bodyText = await utf8.decoder.bind(request).join();
        request.response
          ..statusCode = 201
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_orderIntentPostResponse()));
        await request.response.close();
      });
      final baseUrl = await server.start();
      addTearDown(server.stop);

      const auth = AuthContext(userId: 'alice', authToken: 'jwt-demo-user');
      final client = HttpOrderIntentClient(
        baseUrl: baseUrl,
        authContext: auth,
        api: HttpDonorSetupApiClient(
          baseUrl: baseUrl,
          authContext: auth,
          savePresetsRetryPolicy: const RetryPolicy(maxAttempts: 1),
        ),
      );

      await client.registerInstructionsCopied(
        packId: 'pack-1',
        presets: <DonorPreset>[_samplePreset()],
        hasReferencePhoto: false,
        verbalHandoverNotes: 'notes',
        existingOrderIntentId: 'oi-existing',
      );

      expect(authHeader, 'Bearer jwt-demo-user');
      final decoded = jsonDecode(bodyText!) as Map<String, dynamic>;
      expect(decoded.containsKey('user_id'), isFalse);
      expect(decoded['pack_id'], 'pack-1');
      expect(decoded['order_intent_id'], 'oi-existing');
      expect(decoded['verbal_handover_notes'], 'notes');
    });

    test('registerInstructionsCopied includes user_id when Bearer is empty',
        () async {
      String? bodyText;
      final server = _ScriptedServer((HttpRequest request) async {
        bodyText = await utf8.decoder.bind(request).join();
        request.response
          ..statusCode = 201
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_orderIntentPostResponse()));
        await request.response.close();
      });
      final baseUrl = await server.start();
      addTearDown(server.stop);

      const auth = AuthContext(userId: 'demo-user', authToken: '');
      final client = HttpOrderIntentClient(
        baseUrl: baseUrl,
        authContext: auth,
        api: HttpDonorSetupApiClient(
          baseUrl: baseUrl,
          authContext: auth,
          savePresetsRetryPolicy: const RetryPolicy(maxAttempts: 1),
        ),
      );

      await client.registerInstructionsCopied(
        packId: 'pack-1',
        presets: <DonorPreset>[_samplePreset()],
        hasReferencePhoto: true,
      );

      final decoded = jsonDecode(bodyText!) as Map<String, dynamic>;
      expect(decoded['user_id'], 'demo-user');
    });

    test('listDonationIntents omits user_id query when Bearer is set', () async {
      Uri? requestUri;
      final server = _ScriptedServer((HttpRequest request) async {
        requestUri = request.uri;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'user_id': 'demo-user',
              'order_intents': <dynamic>[],
            }),
          );
        await request.response.close();
      });
      final baseUrl = await server.start();
      addTearDown(server.stop);

      const auth = AuthContext(userId: 'alice', authToken: 'jwt-demo-user');
      final client = HttpOrderIntentClient(
        baseUrl: baseUrl,
        authContext: auth,
        api: HttpDonorSetupApiClient(
          baseUrl: baseUrl,
          authContext: auth,
          retryPolicy: const RetryPolicy(maxAttempts: 1),
        ),
      );

      final rows = await client.listDonationIntents();

      expect(requestUri!.query, isEmpty);
      expect(rows, isEmpty);
    });

    test('listDonationIntents adds user_id query when Bearer is empty', () async {
      Uri? requestUri;
      final server = _ScriptedServer((HttpRequest request) async {
        requestUri = request.uri;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'user_id': 'demo-user',
              'order_intents': <dynamic>[
                <String, dynamic>{
                  'order_intent_id': 'oi-1',
                  'pack_id': 'p1',
                  'status': 'instructions_copied',
                  'created_at': '2026-05-15T00:00:00Z',
                },
              ],
            }),
          );
        await request.response.close();
      });
      final baseUrl = await server.start();
      addTearDown(server.stop);

      const auth = AuthContext(userId: 'demo-user', authToken: '');
      final client = HttpOrderIntentClient(
        baseUrl: baseUrl,
        authContext: auth,
        api: HttpDonorSetupApiClient(
          baseUrl: baseUrl,
          authContext: auth,
          retryPolicy: const RetryPolicy(maxAttempts: 1),
        ),
      );

      final rows = await client.listDonationIntents();

      expect(requestUri!.queryParameters['user_id'], 'demo-user');
      expect(rows.single.orderIntentId, 'oi-1');
    });
  });
}
