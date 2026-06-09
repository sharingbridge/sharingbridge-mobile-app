import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/application/clear_presets_usecase.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/donor_preset.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/ai_content_source.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/suggest_vendors_result.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/vendor_suggestion.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/repositories/donor_setup_repository.dart';

class _SpyRepo implements DonorSetupRepository {
  String? clearedUserId;

  @override
  Future<void> clearPresets({required String userId}) async {
    clearedUserId = userId;
  }

  @override
  Future<List<DonorPreset>> loadPresets({required String userId}) async =>
      <DonorPreset>[];

  @override
  Future<void> savePresets({
    required String userId,
    required List<DonorPreset> presets,
  }) async {}

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
  }) async =>
      const SuggestVendorsResult(
        suggestions: <VendorSuggestion>[],
        source: AiContentSource(null),
      );
}

void main() {
  test('delegates to repository with userId', () async {
    final repo = _SpyRepo();
    final useCase = ClearPresetsUseCase(repo);
    await useCase(userId: 'alice');
    expect(repo.clearedUserId, 'alice');
  });
}
