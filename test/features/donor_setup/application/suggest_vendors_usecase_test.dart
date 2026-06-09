import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/application/suggest_vendors_usecase.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/donor_preset.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/ai_content_source.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/suggest_vendors_result.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/vendor_suggestion.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/repositories/donor_setup_repository.dart';

class _FakeRepository implements DonorSetupRepository {
  @override
  Future<List<DonorPreset>> loadPresets({required String userId}) async {
    return <DonorPreset>[];
  }

  @override
  Future<void> savePresets({
    required String userId,
    required List<DonorPreset> presets,
  }) async {}

  @override
  Future<void> clearPresets({required String userId}) async {}

  @override
  Future<void> removePreset({
    required String userId,
    required DonorPreset preset,
  }) async {}

  @override
  Future<SuggestVendorsResult> suggestVendors({
    required String queryText,
    required double? lat,
    required double? lng,
    String? manualArea,
  }) async {
    return SuggestVendorsResult(
      suggestions: List<VendorSuggestion>.generate(
        6,
        (int index) => VendorSuggestion(
          restaurantName: 'R$index',
          menuItems: const <String>['Meals'],
          orderUrl: 'https://example.com/$index',
          appName: 'VendorApp',
          confidence: 0.8,
        ),
      ),
      source: const AiContentSource('groq'),
    );
  }
}

void main() {
  test('returns top 5 suggestions when repository gives more', () async {
    final useCase = SuggestVendorsUseCase(_FakeRepository());
    final result = await useCase(
      queryText: 'zomato meals',
      locationPermissionGranted: true,
      lat: 12.9,
      lng: 80.2,
    );
    expect(result.suggestions.length, 5);
    expect(result.source.isLive, isTrue);
  });

  test('allows suggest without location when manual area omitted', () async {
    final useCase = SuggestVendorsUseCase(_FakeRepository());
    final result = await useCase(
      queryText: 'swiggy',
      locationPermissionGranted: false,
    );
    expect(result.suggestions.length, 5);
  });
}
