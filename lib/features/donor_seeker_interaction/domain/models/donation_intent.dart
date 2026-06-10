/// Donor donation intent returned by GET /v1/donor-seeker/order-intents.
class DonationIntent {
  const DonationIntent({
    required this.orderIntentId,
    required this.packId,
    required this.status,
    required this.hasReferencePhoto,
    required this.verbalHandoverNotes,
    required this.presetsSnapshot,
    this.referencePhotoArtifactId,
    this.referencePhotoViewUrl,
    this.referencePhotoThumbnailUrl,
    this.selectedPreset,
    this.locationLabel,
    this.localityKey,
    this.createdAt,
    this.updatedAt,
    this.paymentStatus = 'pending',
    this.deliveryStatus = 'pending',
  });

  factory DonationIntent.fromJson(Map<String, dynamic> json) {
    final presetsRaw = json['presets_snapshot'];
    final presets = presetsRaw is List
        ? presetsRaw
            .whereType<Map>()
            .map((Map<dynamic, dynamic> row) => Map<String, dynamic>.from(row))
            .toList()
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? selected;
    final selectedRaw = json['selected_preset'];
    if (selectedRaw is Map) {
      selected = Map<String, dynamic>.from(selectedRaw);
    }

    return DonationIntent(
      orderIntentId: json['order_intent_id']?.toString() ?? '',
      packId: json['pack_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'instructions_copied',
      hasReferencePhoto: json['has_reference_photo'] == true,
      referencePhotoArtifactId:
          json['reference_photo_artifact_id']?.toString(),
      referencePhotoViewUrl: json['reference_photo_view_url']?.toString(),
      referencePhotoThumbnailUrl:
          json['reference_photo_thumbnail_url']?.toString(),
      verbalHandoverNotes: json['verbal_handover_notes']?.toString() ?? '',
      presetsSnapshot: presets,
      selectedPreset: selected,
      locationLabel: json['location_label']?.toString(),
      localityKey: json['locality_key']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      deliveryStatus: json['delivery_status']?.toString() ?? 'pending',
    );
  }

  final String orderIntentId;
  final String packId;
  final String status;
  final bool hasReferencePhoto;
  final String? referencePhotoArtifactId;
  final String? referencePhotoViewUrl;
  final String? referencePhotoThumbnailUrl;
  final String verbalHandoverNotes;
  final List<Map<String, dynamic>> presetsSnapshot;
  final Map<String, dynamic>? selectedPreset;
  final String? locationLabel;
  final String? localityKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String paymentStatus;
  final String deliveryStatus;

  String get statusLabel {
    return status.replaceAll('_', ' ');
  }

  String? get primaryRestaurantName {
    if (selectedPreset != null) {
      final name = selectedPreset!['restaurant_name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    for (final Map<String, dynamic> row in presetsSnapshot) {
      final name = row['restaurant_name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    return null;
  }

  DateTime? get sortTime => updatedAt ?? createdAt;

  String get paymentStatusLabel => paymentStatus.replaceAll('_', ' ');

  bool get canMarkPaymentDone => paymentStatus != 'paid_externally';

  bool get hasDisplayableReferencePhoto {
    final thumb = referencePhotoThumbnailUrl?.trim();
    final view = referencePhotoViewUrl?.trim();
    return (thumb != null && thumb.isNotEmpty) ||
        (view != null && view.isNotEmpty);
  }
}
