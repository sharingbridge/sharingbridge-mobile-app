import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/data/http_donor_setup_api_client.dart';

class StandardOfferOption {
  const StandardOfferOption({
    required this.standardOfferId,
    required this.localityKey,
    required this.menuLabel,
    this.priceInr,
  });

  final String standardOfferId;
  final String localityKey;
  final String menuLabel;
  final int? priceInr;
}

/// Lists pilot standard menu items for a GPS area bucket.
class HttpStandardOffersClient {
  HttpStandardOffersClient({
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

  Future<List<StandardOfferOption>> listForLocation({
    required double locationLat,
    required double locationLng,
  }) async {
    final decoded = await _api.getDonorSeekerJson(
      path:
          '/v1/standard-offers?location_lat=$locationLat&location_lng=$locationLng',
    );
    final rows = decoded['standard_offers'];
    if (rows is! List<dynamic>) {
      throw const DonorSetupResponseException(
        'standard_offers missing from response',
      );
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => StandardOfferOption(
            standardOfferId: row['standard_offer_id']?.toString() ?? '',
            localityKey: row['locality_key']?.toString() ?? '',
            menuLabel: row['menu_label']?.toString() ?? 'Menu item',
            priceInr: row['price_inr'] is num
                ? (row['price_inr'] as num).round()
                : null,
          ),
        )
        .where((offer) => offer.standardOfferId.isNotEmpty)
        .toList(growable: false);
  }
}
