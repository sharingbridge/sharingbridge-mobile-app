import '../../auth/data/auth_session_holder.dart';
import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../donor_setup/domain/models/donor_preset.dart';
import '../domain/models/instruction_pack_result.dart';

/// Live instruction-pack target is under 30s server-side; allow modest buffer.
const Duration instructionPackRequestTimeout = Duration(seconds: 35);

/// Calls integration-service instruction-pack API (orchestration when enabled).
class HttpInstructionPackClient {
  HttpInstructionPackClient({
    required this.baseUrl,
    AuthContext? authContext,
    HttpDonorSetupApiClient? donorSetupClient,
  })  : _authOverride = authContext,
        _api = donorSetupClient ??
            HttpDonorSetupApiClient(
              baseUrl: baseUrl,
              authContext: authContext,
              requestTimeout: instructionPackRequestTimeout,
              savePresetsRetryPolicy: const RetryPolicy(maxAttempts: 1),
            );

  final String baseUrl;
  final AuthContext? _authOverride;
  final HttpDonorSetupApiClient _api;

  /// Same JWT as sign-in; reads [AuthSessionHolder] when [_authOverride] is null.
  AuthContext get _auth => _authOverride ?? AuthSessionHolder.resolve();

  Future<InstructionPackResult> requestDeliveryInstructions({
    required List<DonorPreset> presets,
    required bool hasReferencePhoto,
    String? referencePhotoArtifactId,
    String? referencePhotoViewUrl,
    String? referencePhotoThumbnailUrl,
    String? verbalHandoverNotes,
    double? lat,
    double? lng,
    String? locationLabel,
  }) async {
    final decoded = await _api.requestInstructionPack(
      body: _auth.withOptionalUserId(<String, dynamic>{
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
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (locationLabel != null && locationLabel.trim().isNotEmpty)
          'location_label': locationLabel.trim(),
        'presets': presets
            .map(
              (DonorPreset p) => <String, dynamic>{
                'restaurant_name': p.restaurantName,
                'menu_items': p.menuItems,
                'app_name': p.appName,
                'order_url': p.orderUrl,
              },
            )
            .toList(),
      }),
    );

    final instructions = decoded['delivery_instructions'];
    if (instructions is! String || instructions.trim().isEmpty) {
      throw const DonorSetupResponseException(
        'delivery_instructions must be a non-empty string',
      );
    }
    final packId = decoded['pack_id']?.toString();
    return InstructionPackResult(
      deliveryInstructions: instructions,
      packId: packId != null && packId.isNotEmpty ? packId : null,
      source: decoded['source']?.toString(),
      locationDescription: decoded['location_description']?.toString(),
      imageDescription: decoded['image_description']?.toString(),
      seekerAppearanceHints: decoded['seeker_appearance_hints']?.toString(),
      seekerHandoverHints: decoded['seeker_handover_hints']?.toString(),
    );
  }
}
