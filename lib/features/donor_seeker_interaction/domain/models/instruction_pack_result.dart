/// Result from integration-service instruction-pack (and local stub fallback).
class InstructionPackResult {
  const InstructionPackResult({
    required this.deliveryInstructions,
    this.packId,
    this.locationDescription,
    this.imageDescription,
    this.seekerAppearanceHints,
    this.seekerHandoverHints,
  });

  final String deliveryInstructions;
  final String? packId;
  final String? locationDescription;
  final String? imageDescription;
  final String? seekerAppearanceHints;
  final String? seekerHandoverHints;
}
