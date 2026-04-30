class ReceiptScanResult {
  const ReceiptScanResult({
    required this.status,
    required this.message,
    this.shareableFields = const <String, Object?>{},
  });

  final String status;
  final String message;
  final Map<String, Object?> shareableFields;
}
