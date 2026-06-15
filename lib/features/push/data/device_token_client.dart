import '../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../donor_setup/data/auth_context.dart';
import '../../auth/data/auth_session_holder.dart';

/// Registers this device's FCM token with integration-service.
class DeviceTokenClient {
  DeviceTokenClient({
    required this.baseUrl,
    AuthContext? authContext,
    HttpDonorSetupApiClient? api,
  })  : _authOverride = authContext,
        _api = api ??
            HttpDonorSetupApiClient(
              baseUrl: baseUrl,
              authContext: authContext,
              requestTimeout: donorSeekerWriteRequestTimeout,
            );

  final String baseUrl;
  final AuthContext? _authOverride;
  final HttpDonorSetupApiClient _api;

  AuthContext get _auth => _authOverride ?? AuthSessionHolder.resolve();

  Future<void> upsertFcmToken({
    required String fcmToken,
    String platform = 'android',
  }) async {
    await _api.putDonorSeekerJson(
      path: '/v1/device-tokens',
      body: _auth.withOptionalUserId(<String, dynamic>{
        'fcm_token': fcmToken.trim(),
        'platform': platform,
      }),
    );
  }
}
