import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharingbridge_mobile_app/features/auth/data/auth_session_holder.dart';
import 'package:sharingbridge_mobile_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AuthSessionHolder.clear();
  });

  testWidgets('app boots to donor sign-in when no session', (WidgetTester tester) async {
    await tester.pumpWidget(const SharingBridgeApp());
    await tester.pumpAndSettle();
    expect(find.text('SharingBridge'), findsOneWidget);
    expect(find.text('Donor sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
