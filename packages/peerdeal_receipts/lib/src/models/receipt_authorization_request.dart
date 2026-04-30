import 'receipt_access_mode.dart';

class ReceiptAuthorizationRequest {
  const ReceiptAuthorizationRequest({
    required this.requestedByUserId,
    required this.requestedSessionId,
    required this.accessMode,
  });

  final String requestedByUserId;
  final String requestedSessionId;
  final ReceiptAccessMode accessMode;
}
