import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/presentation/widgets/handover_location_confirm_card.dart';

void main() {
  group('HandoverLocationConfirmCardState', () {
    test('validateLabel requires a non-empty label', () {
      expect(
        HandoverLocationConfirmCardState.validateLabel(null),
        'Enter a delivery area or address label.',
      );
      expect(
        HandoverLocationConfirmCardState.validateLabel('  '),
        'Enter a delivery area or address label.',
      );
    });

    test('validateLabel enforces minimum length', () {
      expect(
        HandoverLocationConfirmCardState.validateLabel('ab'),
        'Use at least 3 characters for the area label.',
      );
      expect(HandoverLocationConfirmCardState.validateLabel('Gate'), isNull);
    });
  });
}
