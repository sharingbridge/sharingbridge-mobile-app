import '../../auth/data/auth_session_holder.dart';
import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/data/http_donor_setup_api_client.dart';

class SeekerDemandRegistration {
  const SeekerDemandRegistration({
    required this.seekerDemandId,
  });

  final String seekerDemandId;
}

/// Records a seeker demand on integration-service.
class HttpSeekerDemandClient {
  HttpSeekerDemandClient({
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

  AuthContext get _auth => _authOverride ?? AuthSessionHolder.resolve();

  Future<SeekerDemandRegistration> recordSeekerDemand({
    required String needDescription,
    int mealUnits = 1,
    String? verbalNotes,
    double? locationLat,
    double? locationLng,
    String? locationLabel,
  }) async {
    final decoded = await _api.postDonorSeekerJson(
      path: '/v1/seeker-demands',
      body: _auth.withOptionalUserId(<String, dynamic>{
        'need_description': needDescription.trim(),
        'meal_units': mealUnits,
        if (verbalNotes != null && verbalNotes.trim().isNotEmpty)
          'verbal_notes': verbalNotes.trim(),
        if (locationLat != null && locationLng != null) ...<String, dynamic>{
          'location_lat': locationLat,
          'location_lng': locationLng,
          if (locationLabel != null && locationLabel.trim().isNotEmpty)
            'location_label': locationLabel.trim(),
        },
      }),
    );

    final demand = decoded['seeker_demand'];
    if (demand is! Map<String, dynamic>) {
      throw const DonorSetupResponseException(
        'seeker_demand missing from response',
      );
    }
    final id = demand['seeker_demand_id']?.toString();
    if (id == null || id.isEmpty) {
      throw const DonorSetupResponseException(
        'seeker_demand_id missing from response',
      );
    }
    return SeekerDemandRegistration(seekerDemandId: id);
  }
}
