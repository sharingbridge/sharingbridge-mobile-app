/// API `source` field from integration / ai-orchestration.
///
/// Live: [groq], [groqGemini], [gemini].
/// Non-live (template/mock): [deterministic], [mock], [mockFallback], [fallback], [localStub].
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
    if (normalized == 'deterministic') {
      return 'Sample/template mode — suggestions or instructions are not from '
          'Groq or Gemini. Set AI_LLM_MODE=live on ai-orchestration with API keys.';
    }
    if (normalized == 'mock' || normalized == 'mock_fallback') {
      return 'Demo catalog — vendor suggestions are fixed sample data, not live AI.';
    }
    if (normalized == 'fallback' || normalized == 'fallback_error') {
      return 'Server template — live AI was unavailable. This is not Groq/Gemini output.';
    }
    return 'Not live AI — output source: $value.';
  }

  static AiContentSource parse(String? raw) => AiContentSource(raw?.trim());
}
