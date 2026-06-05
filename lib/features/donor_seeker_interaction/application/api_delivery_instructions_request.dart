import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/domain/models/donor_preset.dart';
import '../data/http_instruction_pack_client.dart';
import '../domain/models/instruction_pack_result.dart';
import 'delivery_instruction_stub.dart';

/// Default instruction request: integration API with local stub fallback.
Future<InstructionPackResult> requestDeliveryInstructionsFromApi({
  required String baseUrl,
  required List<DonorPreset> presets,
  required bool hasReferencePhoto,
  String? referencePhotoArtifactId,
  String? referencePhotoViewUrl,
  String? referencePhotoThumbnailUrl,
  String? verbalHandoverNotes,
  double? lat,
  double? lng,
  String? locationLabel,
  HttpInstructionPackClient? client,
}) async {
  final packClient =
      client ?? HttpInstructionPackClient(baseUrl: baseUrl);
  try {
    return await packClient.requestDeliveryInstructions(
      presets: presets,
      hasReferencePhoto: hasReferencePhoto,
      referencePhotoArtifactId: referencePhotoArtifactId,
      referencePhotoViewUrl: referencePhotoViewUrl,
      referencePhotoThumbnailUrl: referencePhotoThumbnailUrl,
      verbalHandoverNotes: verbalHandoverNotes,
      lat: lat,
      lng: lng,
      locationLabel: locationLabel,
    );
  } on DonorSetupApiException {
    return InstructionPackResult(
      deliveryInstructions: buildDeliveryInstructionsStub(
        presets,
        referencePhotoIncluded: hasReferencePhoto,
        verbalHandoverNotes: verbalHandoverNotes,
        lat: lat,
        lng: lng,
        locationLabel: locationLabel,
      ),
      packId: null,
    );
  }
}
