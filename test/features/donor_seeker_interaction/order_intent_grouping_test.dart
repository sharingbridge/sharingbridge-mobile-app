import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/domain/models/donation_intent.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/presentation/order_intent_grouping.dart';

void main() {
  test('groupDonationIntents groups by calendar day', () {
    final intents = <DonationIntent>[
      DonationIntent(
        orderIntentId: 'a',
        packId: 'p',
        status: 'instructions_copied',
        hasReferencePhoto: false,
        verbalHandoverNotes: '',
        presetsSnapshot: const <Map<String, dynamic>>[],
        createdAt: DateTime.parse('2026-06-02T10:00:00.000Z'),
      ),
      DonationIntent(
        orderIntentId: 'b',
        packId: 'p',
        status: 'instructions_copied',
        hasReferencePhoto: false,
        verbalHandoverNotes: '',
        presetsSnapshot: const <Map<String, dynamic>>[],
        createdAt: DateTime.parse('2026-06-01T10:00:00.000Z'),
      ),
    ];

    final groups = groupDonationIntents(intents);
    expect(groups.length, 2);
    expect(groups.first.intents.first.orderIntentId, 'a');
  });
}
