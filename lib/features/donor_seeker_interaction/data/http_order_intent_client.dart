import '../../auth/data/auth_session_holder.dart';
import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../donor_setup/domain/models/donor_preset.dart';
import '../domain/models/donation_intent.dart';
import '../domain/models/order_intent_registration.dart';

class HttpOrderIntentClient {
  HttpOrderIntentClient({
    required this.baseUrl,
    AuthContext? authContext,
    HttpDonorSetupApiClient? api,
  })  : _authOverride = authContext,
        _api = api ??
            HttpDonorSetupApiClient(
              baseUrl: baseUrl,
              authContext: authContext,
            );

  final String baseUrl;
  final AuthContext? _authOverride;
  final HttpDonorSetupApiClient _api;

  /// Same JWT as sign-in; reads [AuthSessionHolder] when [_authOverride] is null.
  AuthContext get _auth => _authOverride ?? AuthSessionHolder.resolve();

  Future<OrderIntentRegistration> registerInstructionsCopied({
    required String packId,
    required List<DonorPreset> presets,
    required bool hasReferencePhoto,
    String? referencePhotoArtifactId,
    String? referencePhotoViewUrl,
    String? referencePhotoThumbnailUrl,
    String? verbalHandoverNotes,
    DonorPreset? selectedPreset,
    String? existingOrderIntentId,
  }) async {
    final decoded = await _api.postDonorSeekerJson(
      path: '/v1/donor-seeker/order-intents',
      body: _auth.withOptionalUserId(<String, dynamic>{
        'pack_id': packId,
        if (existingOrderIntentId != null &&
            existingOrderIntentId.trim().isNotEmpty)
          'order_intent_id': existingOrderIntentId.trim(),
        'status': 'instructions_copied',
        'has_reference_photo': hasReferencePhoto,
        if (referencePhotoArtifactId != null &&
            referencePhotoArtifactId.trim().isNotEmpty)
          'reference_photo_artifact_id': referencePhotoArtifactId.trim(),
        if (referencePhotoViewUrl != null &&
            referencePhotoViewUrl.trim().isNotEmpty)
          'reference_photo_view_url': referencePhotoViewUrl.trim(),
        if (referencePhotoThumbnailUrl != null &&
            referencePhotoThumbnailUrl.trim().isNotEmpty)
          'reference_photo_thumbnail_url': referencePhotoThumbnailUrl.trim(),
        if (verbalHandoverNotes != null && verbalHandoverNotes.trim().isNotEmpty)
          'verbal_handover_notes': verbalHandoverNotes.trim(),
        'presets_snapshot': presets
            .map(
              (DonorPreset p) => <String, dynamic>{
                'restaurant_name': p.restaurantName,
                'menu_items': p.menuItems,
                'app_name': p.appName,
                'order_url': p.orderUrl,
              },
            )
            .toList(),
        if (selectedPreset != null)
          'selected_preset': <String, dynamic>{
            'restaurant_name': selectedPreset.restaurantName,
            'app_name': selectedPreset.appName,
            'order_url': selectedPreset.orderUrl,
          },
      }),
    );

    final id = decoded['order_intent_id']?.toString();
    if (id == null || id.isEmpty) {
      throw const DonorSetupResponseException(
        'order_intent_id must be a non-empty string',
      );
    }
    return OrderIntentRegistration(
      orderIntentId: id,
      packId: decoded['pack_id']?.toString() ?? packId,
      status: decoded['status']?.toString() ?? 'instructions_copied',
      createdAt: decoded['created_at']?.toString() ?? '',
      updated: decoded['created'] == false,
    );
  }

  Future<List<DonationIntent>> listDonationIntents() async {
    final decoded = await _api.getDonorSeekerJson(
      path: '/v1/donor-seeker/order-intents',
      queryParameters: _auth.userIdQueryParameters(),
    );
    final raw = decoded['order_intents'];
    if (raw is! List) {
      throw const DonorSetupResponseException(
        'order_intents must be a list',
      );
    }
    return raw
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> row) =>
              DonationIntent.fromJson(Map<String, dynamic>.from(row)),
        )
        .where((DonationIntent intent) => intent.orderIntentId.isNotEmpty)
        .toList();
  }
}
