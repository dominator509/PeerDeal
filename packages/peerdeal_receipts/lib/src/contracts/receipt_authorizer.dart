import '../models/peer_deal_receipt.dart';
import '../models/receipt_authorization_request.dart';
import '../models/receipt_authorization_result.dart';

abstract class ReceiptAuthorizer {
  ReceiptAuthorizationResult authorize(
    PeerDealReceipt receipt,
    ReceiptAuthorizationRequest request,
  );
}
