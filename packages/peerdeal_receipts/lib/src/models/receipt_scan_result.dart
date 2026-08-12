import 'model_collection_ownership.dart';

class ReceiptScanResult {
  ReceiptScanResult({
    required this.status,
    required this.message,
    Map<String, Object?> shareableFields = const <String, Object?>{},
  }) : shareableFields = freezeReceiptObjectMap(shareableFields);

  final String status;
  final String message;
  final Map<String, Object?> shareableFields;
}
