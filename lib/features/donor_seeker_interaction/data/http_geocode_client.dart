import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/data/http_donor_setup_api_client.dart';

class ReverseGeocodeResult {
  const ReverseGeocodeResult({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    required this.localityKey,
  });

  final double lat;
  final double lng;
  final String formattedAddress;
  final String localityKey;

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      lat: (json['location_lat'] as num).toDouble(),
      lng: (json['location_lng'] as num).toDouble(),
      formattedAddress: json['formatted_address']?.toString() ?? '',
      localityKey: json['locality_key']?.toString() ?? '',
    );
  }
}

/// Reverse geocode via integration-service (Nominatim on server).
class HttpGeocodeClient {
  HttpGeocodeClient({
    required this.baseUrl,
    AuthContext? authContext,
    HttpDonorSetupApiClient? api,
  })  : _api = api ??
            HttpDonorSetupApiClient(
              baseUrl: baseUrl,
              authContext: authContext,
            );

  final String baseUrl;
  final HttpDonorSetupApiClient _api;

  Future<ReverseGeocodeResult> reverseGeocode({
    required double locationLat,
    required double locationLng,
  }) async {
    final decoded = await _api.getDonorSeekerJson(
      path:
          '/v1/geocode/reverse?location_lat=$locationLat&location_lng=$locationLng',
    );
    if (decoded['location_lat'] is! num || decoded['location_lng'] is! num) {
      throw const DonorSetupResponseException(
        'reverse geocode response missing coordinates',
      );
    }
    return ReverseGeocodeResult.fromJson(decoded);
  }
}
