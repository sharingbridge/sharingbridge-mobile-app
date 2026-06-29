import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/presentation/widgets/handover_map_enabled.dart';

void main() {
  group('handoverMapEnabledFromDefine', () {
    test('true and 1 enable map', () {
      expect(handoverMapEnabledFromDefine('true'), isTrue);
      expect(handoverMapEnabledFromDefine('TRUE'), isTrue);
      expect(handoverMapEnabledFromDefine('1'), isTrue);
    });

    test('false empty and other values disable map', () {
      expect(handoverMapEnabledFromDefine('false'), isFalse);
      expect(handoverMapEnabledFromDefine(''), isFalse);
      expect(handoverMapEnabledFromDefine('AIzaSyExample'), isFalse);
    });
  });
}
