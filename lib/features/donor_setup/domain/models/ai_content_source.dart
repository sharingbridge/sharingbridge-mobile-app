/// API `source` field from integration / ai-orchestration.
///
/// Live: [groq], [groqGemini], [gemini].
/// Non-live: [passthrough] (user input echoed/assembled), [fallback], [localStub].
/// Legacy: [deterministic], [mock], [mockFallback] — treated as non-live notices.
class AiContentSource {
  const AiContentSource(this.value);

  final String? value;

  static const Set<String> _live = {
    'groq',
    'groq+gemini',
    'gemini',
    'orchestration',
  };

  bool get isLive =>
      value != null && _live.contains(value!.trim().toLowerCase());

  /// User-visible notice when content is not from live AI providers.
  String? get userNotice {
    if (isLive || value == null || value!.trim().isEmpty) {
      return null;
    }
    final normalized = value!.trim().toLowerCase();
    if (normalized == 'local_stub') {
      return 'Offline template — integration-service was unreachable. '
          'This is not live AI output.';
    }
    if (normalized == 'passthrough' || normalized == 'deterministic') {
      return 'No AI enrichment — showing your typed input (or a template from it). '
          'Set AI_LLM_MODE=live on ai-orchestration with API keys for Groq/Gemini.';
    }
    if (normalized == 'mock' || normalized == 'mock_fallback') {
      return 'Unexpected demo source — contact support. Vendor lists should not be sample data.';
    }
    if (normalized == 'fallback' || normalized == 'fallback_error') {
      return 'Server template from your notes — live AI was unavailable.';
    }
    return 'Not live AI — output source: $value.';
  }

  static AiContentSource parse(String? raw) => AiContentSource(raw?.trim());
}
