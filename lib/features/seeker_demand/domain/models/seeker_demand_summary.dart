class SeekerDemandSummary {
  const SeekerDemandSummary({
    required this.seekerDemandId,
    required this.mealUnits,
    required this.status,
    required this.createdAt,
    this.menuLabel,
    this.localityKey,
    this.verbalNotes,
    this.orderCode,
    this.initiationRoute,
  });

  factory SeekerDemandSummary.fromJson(Map<String, dynamic> json) {
    return SeekerDemandSummary(
      seekerDemandId: json['seeker_demand_id']?.toString() ?? '',
      mealUnits: (json['meal_units'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'open',
      createdAt: json['created_at']?.toString() ?? '',
      menuLabel: json['menu_label']?.toString(),
      localityKey: json['locality_key']?.toString(),
      verbalNotes: json['verbal_notes']?.toString(),
      orderCode: json['order_code']?.toString(),
      initiationRoute: json['initiation_route']?.toString(),
    );
  }

  final String seekerDemandId;
  final int mealUnits;
  final String status;
  final String createdAt;
  final String? menuLabel;
  final String? localityKey;
  final String? verbalNotes;
  final String? orderCode;
  final String? initiationRoute;
}
