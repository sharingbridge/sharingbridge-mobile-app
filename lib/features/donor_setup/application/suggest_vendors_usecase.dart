import '../domain/models/suggest_vendors_result.dart';
import '../domain/repositories/donor_setup_repository.dart';

class SuggestVendorsUseCase {
  SuggestVendorsUseCase(this._repository);

  final DonorSetupRepository _repository;

  Future<SuggestVendorsResult> call({
    required String queryText,
    required bool locationPermissionGranted,
    double? lat,
    double? lng,
    String? manualArea,
  }) async {
    final trimmedArea = manualArea?.trim();
    final area =
        trimmedArea != null && trimmedArea.isNotEmpty ? trimmedArea : null;

    final result = await _repository.suggestVendors(
      queryText: queryText,
      lat: locationPermissionGranted ? lat : null,
      lng: locationPermissionGranted ? lng : null,
      manualArea: locationPermissionGranted ? null : area,
    );

    if (result.suggestions.length <= 5) {
      return result;
    }
    return SuggestVendorsResult(
      suggestions: result.suggestions.take(5).toList(),
      source: result.source,
    );
  }
}
