import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../config/integration_api_paths.dart';
import 'data/device_token_client.dart';

/// Registers FCM after sign-in. Requires `google-services.json` on Android.
class PushRegistration {
  static bool _firebaseReady = false;

  static const String _apiBaseUrl = IntegrationApiPaths.baseUrl;

  static Future<void> bootstrap() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      _firebaseReady = false;
    }
  }

  static Future<void> tryRegisterAfterAuth() async {
    if (!_firebaseReady) {
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }
      await DeviceTokenClient(baseUrl: _apiBaseUrl).upsertFcmToken(
        fcmToken: token,
      );
      messaging.onTokenRefresh.listen((next) async {
        if (next.trim().isEmpty) {
          return;
        }
        try {
          await DeviceTokenClient(baseUrl: _apiBaseUrl).upsertFcmToken(
            fcmToken: next,
          );
        } catch (_) {
          // Best-effort refresh upload.
        }
      });
    } catch (_) {
      // Push is optional until Firebase is fully configured.
    }
  }
}
