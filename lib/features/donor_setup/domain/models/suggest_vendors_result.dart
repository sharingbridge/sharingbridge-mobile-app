import 'ai_content_source.dart';
import 'vendor_suggestion.dart';

class SuggestVendorsResult {
  const SuggestVendorsResult({
    required this.suggestions,
    required this.source,
  });

  final List<VendorSuggestion> suggestions;
  final AiContentSource source;
}
