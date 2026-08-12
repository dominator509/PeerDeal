import 'model_collection_ownership.dart';

class ReceiptExportInspectionResult {
  ReceiptExportInspectionResult({
    required this.status,
    required this.message,
    Map<String, Object?> payload = const <String, Object?>{},
    List<String> diagnostics = const <String>[],
  }) : payload = freezeReceiptObjectMap(payload),
       diagnostics = List<String>.unmodifiable(diagnostics);

  ReceiptExportInspectionResult.rejected({
    required this.message,
    List<String> diagnostics = const <String>[],
  }) : status = 'rejected',
       payload = const <String, Object?>{},
       diagnostics = List<String>.unmodifiable(diagnostics);

  final String status;
  final String message;
  final Map<String, Object?> payload;
  final List<String> diagnostics;

  bool get isAccepted => status == 'ok';
}
