import '../../auth/data/auth_session_holder.dart';
import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../donor_setup/domain/models/donor_preset.dart';
import '../domain/models/instruction_pack_result.dart';

/// Calls integration-service instruction-pack API (orchestration when enabled).
class HttpInstructionPackClient {
  HttpInstructionPackClient({
    required this.baseUrl,
    AuthContext? authContext,
    HttpDonorSetupApiClient? donorSetupClient,
  })  : _authContext = authContext ?? AuthSessionHolder.resolve(),
        _api = donorSetupClient ??
            HttpDonorSetupApiClient(
              baseUrl: baseUrl,
              authContext: authContext,
            );

  final String baseUrl;
  final AuthContext _authContext;
  final HttpDonorSetupApiClient _api;

  Future<InstructionPackResult> requestDeliveryInstructions({
    required List<DonorPreset> presets,
    required bool hasReferencePhoto,
    String? verbalHandoverNotes,
    double? lat,
    double? lng,
    String? locationLabel,
  }) async {
    final decoded = await _api.requestInstructionPack(
      body: _authContext.withOptionalUserId(<String, dynamic>{
        'has_reference_photo': hasReferencePhoto,
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
    );
  }
}
