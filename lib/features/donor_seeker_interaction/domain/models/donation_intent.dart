/// Donor donation intent returned by GET /v1/donor-seeker/order-intents.
class DonationIntent {
  const DonationIntent({
    required this.orderIntentId,
    required this.packId,
    required this.status,
    required this.hasReferencePhoto,
    required this.verbalHandoverNotes,
    required this.presetsSnapshot,
    this.selectedPreset,
    this.createdAt,
    this.updatedAt,
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
      verbalHandoverNotes: json['verbal_handover_notes']?.toString() ?? '',
      presetsSnapshot: presets,
      selectedPreset: selected,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  final String orderIntentId;
  final String packId;
  final String status;
  final bool hasReferencePhoto;
  final String verbalHandoverNotes;
  final List<Map<String, dynamic>> presetsSnapshot;
  final Map<String, dynamic>? selectedPreset;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
}
