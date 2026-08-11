class CanonicalJsonLimits {
  const CanonicalJsonLimits({
    this.maxMapEntries = 256,
    this.maxListItems = 256,
    this.maxDepth = 16,
    this.maxTextBytes = 4096,
    this.maxNodes = 16384,
    this.maxEncodedBytes = 4 * 1024 * 1024,
  });

  final int maxMapEntries;
  final int maxListItems;
  final int maxDepth;
  final int maxTextBytes;
  final int maxNodes;
  final int maxEncodedBytes;

  void validate() {
    _requirePositive(maxMapEntries, 'maxMapEntries');
    _requirePositive(maxListItems, 'maxListItems');
    _requirePositive(maxDepth, 'maxDepth');
    _requirePositive(maxTextBytes, 'maxTextBytes');
    _requirePositive(maxNodes, 'maxNodes');
    _requirePositive(maxEncodedBytes, 'maxEncodedBytes');
  }

  static void _requirePositive(int value, String name) {
    if (value < 1) {
      throw ArgumentError.value(value, name, 'must be positive');
    }
  }
}
