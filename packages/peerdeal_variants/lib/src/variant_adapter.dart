abstract interface class VariantAdapter {
  String get variantId;
  int get holeCardCount;
  int get boardCardCount;
  Map<String, Object?> getCapabilities();
}
