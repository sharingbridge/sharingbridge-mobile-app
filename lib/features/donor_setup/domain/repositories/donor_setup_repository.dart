import '../models/donor_preset.dart';
import '../models/suggest_vendors_result.dart';

abstract class DonorSetupRepository {
  Future<SuggestVendorsResult> suggestVendors({
    required String queryText,
    required double? lat,
    required double? lng,
    String? manualArea,
  });

  Future<List<DonorPreset>> loadPresets({required String userId});

  Future<void> savePresets({
    required String userId,
    required List<DonorPreset> presets,
  });

  Future<void> clearPresets({required String userId});

  Future<void> removePreset({
    required String userId,
    required DonorPreset preset,
  });
}
