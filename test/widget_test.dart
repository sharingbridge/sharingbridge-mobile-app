import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/main.dart';

void main() {
  testWidgets('app boots with home hub', (WidgetTester tester) async {
    await tester.pumpWidget(const SharingBridgeApp());
    expect(find.text('SharingBridge'), findsOneWidget);
    expect(find.textContaining('Vendor presets'), findsWidgets);
    expect(find.textContaining('Help a seeker'), findsWidgets);
    expect(find.textContaining('Order initiation history'), findsWidgets);
  });
}
