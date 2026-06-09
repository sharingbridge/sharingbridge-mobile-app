import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/ai_content_source.dart';

void main() {
  test('live sources hide notice', () {
    expect(const AiContentSource('groq').userNotice, isNull);
    expect(const AiContentSource('groq+gemini').isLive, isTrue);
  });

  test('deterministic and mock sources show notice', () {
    final deterministic = const AiContentSource('deterministic');
    expect(deterministic.isLive, isFalse);
    expect(deterministic.userNotice, contains('Sample/template'));

    final mock = const AiContentSource('mock');
    expect(mock.userNotice, contains('Demo catalog'));
  });
}
