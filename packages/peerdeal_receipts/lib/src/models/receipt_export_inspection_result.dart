class ReceiptExportInspectionResult {
  const ReceiptExportInspectionResult({
    required this.status,
    required this.message,
    this.payload = const <String, Object?>{},
    this.diagnostics = const <String>[],
  });

  const ReceiptExportInspectionResult.rejected({
    required this.message,
    this.diagnostics = const <String>[],
  }) : status = 'rejected',
       payload = const <String, Object?>{};

  final String status;
  final String message;
  final Map<String, Object?> payload;
  final List<String> diagnostics;

  bool get isAccepted => status == 'ok';
}
