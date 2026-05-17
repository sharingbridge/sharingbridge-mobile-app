import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/domain/models/donation_intent.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/presentation/pages/donation_history_page.dart';
import 'package:sharingbridge_mobile_app/presentation/app_home_page.dart';

void main() {
  final sampleIntents = <DonationIntent>[
    DonationIntent(
      orderIntentId: 'oi-test-1',
      packId: 'pack-1',
      status: 'instructions_copied',
      hasReferencePhoto: true,
      verbalHandoverNotes: 'Near blue gate',
      presetsSnapshot: <Map<String, dynamic>>[
        <String, dynamic>{
          'restaurant_name': 'A2B',
          'app_name': 'Zomato',
        },
      ],
      createdAt: DateTime.parse('2026-05-15T10:00:00.000Z'),
      updatedAt: DateTime.parse('2026-05-15T11:00:00.000Z'),
    ),
  ];

  testWidgets('home hub opens donation history', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_donation_history')));
    await tester.pumpAndSettle();

    expect(find.text('Order initiation history'), findsOneWidget);
  });

  testWidgets('history lists intents and opens detail', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DonationHistoryPage(
          listDonationIntents: () async => sampleIntents,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('oi-test-1'), findsOneWidget);
    expect(find.textContaining('A2B'), findsOneWidget);

    await tester.tap(find.byKey(const Key('donation_history_row_0')));
    await tester.pumpAndSettle();

    expect(find.text('Order initiation'), findsOneWidget);
    expect(find.text('Near blue gate'), findsOneWidget);
    expect(find.text('A2B'), findsWidgets);
  });

  testWidgets('empty history shows guidance', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DonationHistoryPage(
          listDonationIntents: () async => <DonationIntent>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No order initiations yet'), findsOneWidget);
  });
}
