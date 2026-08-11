class ReceiptExportLimits {
  const ReceiptExportLimits({
    this.maxEncodedBodyLength = 1024 * 1024,
    this.maxDecodedBodyBytes = 768 * 1024,
    this.maxPayloadBytes = 512 * 1024,
    this.maxCiphertextLength = 768 * 1024,
    this.maxNonceBytes = 64,
  });

  final int maxEncodedBodyLength;
  final int maxDecodedBodyBytes;
  final int maxPayloadBytes;
  final int maxCiphertextLength;
  final int maxNonceBytes;

  void validate() {
    if (maxEncodedBodyLength <= 0 ||
        maxDecodedBodyBytes <= 0 ||
        maxPayloadBytes <= 0 ||
        maxCiphertextLength <= 0 ||
        maxNonceBytes <= 0) {
      throw ArgumentError.value(
        this,
        'limits',
        'All receipt limits must be positive.',
      );
    }
  }
}
