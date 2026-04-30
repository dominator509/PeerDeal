class ReceiptAuthorizationResult {
  const ReceiptAuthorizationResult({
    required this.allowed,
    required this.normalizedResultCode,
    required this.message,
  });

  final bool allowed;
  final String normalizedResultCode;
  final String message;
}
