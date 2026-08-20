import '../models/peer_deal_receipt.dart';
import '../models/receipt_authorization_request.dart';
import '../models/receipt_authorization_result.dart';
import '../models/receipt_export_artifact.dart';
import '../models/receipt_scan_result.dart';

abstract class ReceiptService {
  ReceiptAuthorizationResult authorize(
    PeerDealReceipt receipt,
    ReceiptAuthorizationRequest request,
  );

  ReceiptExportArtifact exportReceipt(
    PeerDealReceipt receipt, {
    ReceiptAuthorizationRequest? authorization,
  });

  ReceiptScanResult scanReceipt(PeerDealReceipt receipt);
}
