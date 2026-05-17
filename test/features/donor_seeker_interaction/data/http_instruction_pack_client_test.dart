import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/auth_context.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/http_donor_setup_api_client.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/donor_preset.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/data/http_instruction_pack_client.dart';

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

void main() {
  test('requestDeliveryInstructions omits user_id when Bearer is set', () async {
    String? bodyText;
    final server = _ScriptedServer((HttpRequest request) async {
      bodyText = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(<String, dynamic>{
            'delivery_instructions': 'Leave at gate.',
            'pack_id': 'pack-abc',
          }),
        );
      await request.response.close();
    });
    final baseUrl = await server.start();
    addTearDown(server.stop);

    const auth = AuthContext(userId: 'alice', authToken: 'jwt-demo-user');
    final client = HttpInstructionPackClient(
      baseUrl: baseUrl,
      authContext: auth,
      donorSetupClient: HttpDonorSetupApiClient(
        baseUrl: baseUrl,
        authContext: auth,
        savePresetsRetryPolicy: const RetryPolicy(maxAttempts: 1),
      ),
    );

    final result = await client.requestDeliveryInstructions(
      presets: <DonorPreset>[
        DonorPreset(
          restaurantName: 'Ratna Cafe',
          orderUrl: 'https://example.com/order',
          menuItems: const <String>['Coffee'],
          appName: 'Swiggy',
          source: 'test',
          confidence: 0.8,
        ),
      ],
      hasReferencePhoto: false,
      verbalHandoverNotes: ' ring bell ',
      lat: 12.9,
      lng: 80.2,
      locationLabel: ' Chennai ',
    );

    final decoded = jsonDecode(bodyText!) as Map<String, dynamic>;
    expect(decoded.containsKey('user_id'), isFalse);
    expect(decoded['verbal_handover_notes'], 'ring bell');
    expect(decoded['location_label'], 'Chennai');
    expect(result.deliveryInstructions, 'Leave at gate.');
    expect(result.packId, 'pack-abc');
  });

  test('requestDeliveryInstructions includes user_id when Bearer is empty',
      () async {
    String? bodyText;
    final server = _ScriptedServer((HttpRequest request) async {
      bodyText = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(<String, dynamic>{
            'delivery_instructions': 'Hand to seeker.',
          }),
        );
      await request.response.close();
    });
    final baseUrl = await server.start();
    addTearDown(server.stop);

    const auth = AuthContext(userId: 'demo-user', authToken: '');
    final client = HttpInstructionPackClient(
      baseUrl: baseUrl,
      authContext: auth,
      donorSetupClient: HttpDonorSetupApiClient(
        baseUrl: baseUrl,
        authContext: auth,
        savePresetsRetryPolicy: const RetryPolicy(maxAttempts: 1),
      ),
    );

    await client.requestDeliveryInstructions(
      presets: <DonorPreset>[
        DonorPreset(
          restaurantName: 'X',
          orderUrl: 'https://example.com/x',
          menuItems: const <String>['Y'],
          appName: 'Zomato',
          source: 'test',
          confidence: 0.5,
        ),
      ],
      hasReferencePhoto: true,
    );

    final decoded = jsonDecode(bodyText!) as Map<String, dynamic>;
    expect(decoded['user_id'], 'demo-user');
  });
}
