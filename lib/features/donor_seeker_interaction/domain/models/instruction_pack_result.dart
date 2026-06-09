/// Result from integration-service instruction-pack (and local stub fallback).
class InstructionPackResult {
  const InstructionPackResult({
    required this.deliveryInstructions,
    this.packId,
    this.source,
    this.locationDescription,
    this.imageDescription,
    this.seekerAppearanceHints,
    this.seekerHandoverHints,
  });

  final String deliveryInstructions;
  final String? packId;
  /// API `source` (e.g. groq+gemini, deterministic, fallback, local_stub).
  final String? source;
  final String? locationDescription;
  final String? imageDescription;
  final String? seekerAppearanceHints;
  final String? seekerHandoverHints;
}
