import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/ai_content_source.dart';

void main() {
  test('live sources hide notice', () {
    expect(const AiContentSource('groq').userNotice, isNull);
    expect(const AiContentSource('groq+gemini').isLive, isTrue);
  });

  test('passthrough and legacy deterministic show no-AI notice', () {
    final passthrough = const AiContentSource('passthrough');
    expect(passthrough.isLive, isFalse);
    expect(passthrough.userNotice, contains('No AI enrichment'));

    final deterministic = const AiContentSource('deterministic');
    expect(deterministic.isLive, isFalse);
    expect(deterministic.userNotice, contains('No AI enrichment'));
  });

  test('legacy mock source shows unexpected-demo notice', () {
    final mock = const AiContentSource('mock');
    expect(mock.isLive, isFalse);
    expect(mock.userNotice, contains('Unexpected demo source'));
  });
}
