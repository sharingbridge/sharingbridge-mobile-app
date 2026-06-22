import '../../../../connection_copy.dart';

class OrderConnectionDemand {
  const OrderConnectionDemand({
    required this.seekerDemandId,
    required this.status,
    required this.needDescription,
    required this.verbalNotes,
    required this.locationLabel,
    this.standardOfferId,
    required this.recordedAt,
  });

  factory OrderConnectionDemand.fromJson(Map<String, dynamic> json) {
    return OrderConnectionDemand(
      seekerDemandId: json['seeker_demand_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      needDescription: json['need_description']?.toString() ?? '',
      verbalNotes: json['verbal_notes']?.toString() ?? '',
      locationLabel: json['location_label']?.toString() ?? '',
      standardOfferId: json['standard_offer_id']?.toString(),
      recordedAt: json['recorded_at']?.toString() ?? '',
    );
  }

  final String seekerDemandId;
  final String status;
  final String needDescription;
  final String verbalNotes;
  final String locationLabel;
  final String? standardOfferId;
  final String recordedAt;
}

class OrderConnectionKitchen {
  const OrderConnectionKitchen({
    required this.displayName,
    this.loginEmail,
    this.commitmentStatus,
  });

  factory OrderConnectionKitchen.fromJson(Map<String, dynamic> json) {
    return OrderConnectionKitchen(
      displayName: json['display_name']?.toString() ?? '',
      loginEmail: json['login_email']?.toString(),
      commitmentStatus: json['commitment_status']?.toString(),
    );
  }

  final String displayName;
  final String? loginEmail;
  final String? commitmentStatus;
}

class OrderConnectionPledger {
  const OrderConnectionPledger({
    this.pledgedByUserId,
    required this.mealUnits,
    this.loginEmail,
  });

  factory OrderConnectionPledger.fromJson(Map<String, dynamic> json) {
    return OrderConnectionPledger(
      pledgedByUserId: json['pledged_by_user_id']?.toString(),
      mealUnits: _parseInt(json['meal_units'], fallback: 1),
      loginEmail: json['login_email']?.toString(),
    );
  }

  final String? pledgedByUserId;
  final int mealUnits;
  final String? loginEmail;
}

class OrderConnection {
  const OrderConnection({
    required this.orderCode,
    required this.status,
    required this.initiationRoute,
    required this.viewerRole,
    required this.safetyCopy,
    required this.menuLabel,
    this.mealUnits,
    this.priceInr,
    required this.localityKey,
    this.seekerDemandId,
    this.demand,
    this.kitchen,
    this.counterpartyEmail,
    this.initiatorEmail,
    this.pledgers = const <OrderConnectionPledger>[],
  });

  factory OrderConnection.fromJson(Map<String, dynamic> json) {
    final demandRaw = json['demand'];
    final kitchenRaw = json['kitchen'];
    final initiatorRaw = json['initiator'];
    final pledgersRaw = json['pledgers'];

    return OrderConnection(
      orderCode: json['order_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      initiationRoute: json['initiation_route']?.toString() ?? '',
      viewerRole: json['viewer_role']?.toString() ?? '',
      safetyCopy: json['safety_copy']?.toString() ?? ConnectionCopy.safety,
      menuLabel: json['menu_label']?.toString() ?? '',
      mealUnits: _parseNullableInt(json['meal_units']),
      priceInr: _parseNullableInt(json['price_inr']),
      localityKey: json['locality_key']?.toString() ?? '',
      seekerDemandId: json['seeker_demand_id']?.toString(),
      demand: demandRaw is Map<String, dynamic>
          ? OrderConnectionDemand.fromJson(demandRaw)
          : null,
      kitchen: kitchenRaw is Map<String, dynamic>
          ? OrderConnectionKitchen.fromJson(kitchenRaw)
          : null,
      counterpartyEmail: json['counterparty_email']?.toString(),
      initiatorEmail: initiatorRaw is Map<String, dynamic>
          ? initiatorRaw['login_email']?.toString()
          : null,
      pledgers: pledgersRaw is List
          ? pledgersRaw
              .whereType<Map<String, dynamic>>()
              .map(OrderConnectionPledger.fromJson)
              .toList()
          : const <OrderConnectionPledger>[],
    );
  }

  final String orderCode;
  final String status;
  final String initiationRoute;
  final String viewerRole;
  final String safetyCopy;
  final String menuLabel;
  final int? mealUnits;
  final int? priceInr;
  final String localityKey;
  final String? seekerDemandId;
  final OrderConnectionDemand? demand;
  final OrderConnectionKitchen? kitchen;
  final String? counterpartyEmail;
  final String? initiatorEmail;
  final List<OrderConnectionPledger> pledgers;

  bool get contactsReady => status == 'ready';

  String? get kitchenLoginEmail =>
      counterpartyEmail?.trim().isNotEmpty == true
          ? counterpartyEmail
          : kitchen?.loginEmail;
}

int _parseInt(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _parseNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value.toString());
}
