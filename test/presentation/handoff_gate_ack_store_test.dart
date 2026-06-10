import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharingbridge_mobile_app/presentation/handoff_gate_ack_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('markAcknowledgedForUser is per user until clear', () async {
    final store = HandoffGateAckStore();
    expect(await store.hasAcknowledgedForUser('alice'), isFalse);
    await store.markAcknowledgedForUser('alice');
    expect(await store.hasAcknowledgedForUser('alice'), isTrue);
    expect(await store.hasAcknowledgedForUser('bob'), isFalse);
    await store.clear();
    expect(await store.hasAcknowledgedForUser('alice'), isFalse);
  });
}
