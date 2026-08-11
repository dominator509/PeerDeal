class DealProofLimits {
  const DealProofLimits({
    this.maxProviderIdBytes = 128,
    this.maxProviderVersionBytes = 64,
    this.maxProofReferenceBytes = 256,
    this.maxMapEntries = 64,
    this.maxListItems = 64,
    this.maxDepth = 8,
    this.maxTextBytes = 512,
    this.maxNodes = 4096,
    this.maxProofBytes = 512 * 1024,
  });

  final int maxProviderIdBytes;
  final int maxProviderVersionBytes;
  final int maxProofReferenceBytes;
  final int maxMapEntries;
  final int maxListItems;
  final int maxDepth;
  final int maxTextBytes;
  final int maxNodes;
  final int maxProofBytes;

  void validate() {
    _requirePositive(maxProviderIdBytes, 'maxProviderIdBytes');
    _requirePositive(maxProviderVersionBytes, 'maxProviderVersionBytes');
    _requirePositive(maxProofReferenceBytes, 'maxProofReferenceBytes');
    _requirePositive(maxMapEntries, 'maxMapEntries');
    _requirePositive(maxListItems, 'maxListItems');
    _requirePositive(maxDepth, 'maxDepth');
    _requirePositive(maxTextBytes, 'maxTextBytes');
    _requirePositive(maxNodes, 'maxNodes');
    _requirePositive(maxProofBytes, 'maxProofBytes');
  }

  static void _requirePositive(int value, String name) {
    if (value < 1) {
      throw ArgumentError.value(value, name, 'must be positive');
    }
  }
}
