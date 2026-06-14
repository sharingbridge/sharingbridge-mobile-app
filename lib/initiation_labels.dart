/// Payment / fulfilment routes (mobile will expose all three; two ship today).
///
/// - [directOrder] — initiator pays at a chosen vendor.
/// - [forPledging] — others fund the need.
/// - [communityKitchens] — open vendors commit to a standard menu for
///   crowd-scale preparation (nutrition, hygiene, economical).
abstract final class InitiationRouteLabels {
  static const directOrder = 'Direct order';
  static const forPledging = 'For pledging';
  static const communityKitchens = 'Community kitchens';
}

enum InitiationFeedKind { vendorOrder, mealNeed }

String initiationKindLabel(InitiationFeedKind kind) {
  switch (kind) {
    case InitiationFeedKind.vendorOrder:
      return InitiationRouteLabels.directOrder;
    case InitiationFeedKind.mealNeed:
      return InitiationRouteLabels.forPledging;
  }
}
