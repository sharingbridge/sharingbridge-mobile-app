/// Payment / fulfilment routes (three initiation options; two ship today).
///
/// - [directOrder] — initiator pays in a vendor app.
/// - [ecoKitchenSelfPay] — initiator pays eco kitchen after commit (off-platform).
/// - [ecoKitchenPledge] — pledgers fund; eco kitchen fulfils (off-platform payment).
abstract final class InitiationRouteLabels {
  static const directOrder = 'Direct order';
  static const forPledging = 'For pledging';
  static const ecoKitchens = 'Eco kitchens';
  static const ecoKitchenSelfPay = 'Eco kitchen · I pay';
  static const ecoKitchenPledge = 'Eco kitchen · open for pledging';
}

enum InitiationFeedKind { vendorOrder, mealNeed }

String initiationKindLabel(InitiationFeedKind kind) {
  switch (kind) {
    case InitiationFeedKind.vendorOrder:
      return InitiationRouteLabels.directOrder;
    case InitiationFeedKind.mealNeed:
      return InitiationRouteLabels.ecoKitchenPledge;
  }
}

/// User-facing label from API `initiation_route` (seeker demands).
String initiationApiRouteLabel(String? route) {
  switch (route) {
    case 'eco_kitchen_self_pay':
      return InitiationRouteLabels.ecoKitchenSelfPay;
    case 'eco_kitchen_pledge':
      return InitiationRouteLabels.ecoKitchenPledge;
    default:
      return InitiationRouteLabels.ecoKitchenPledge;
  }
}
