import '../contracts/receipt_authorizer.dart';
import '../contracts/receipt_service.dart';
import '../models/peer_deal_receipt.dart';
import '../models/receipt_authorization_request.dart';
import '../models/receipt_authorization_result.dart';
import '../models/receipt_export_artifact.dart';
import '../models/receipt_scan_result.dart';
import '../models/receipt_wipe_state.dart';
import 'opaque_export_encoder.dart';

class DefaultReceiptService implements ReceiptService {
  const DefaultReceiptService({
    required ReceiptAuthorizer authorizer,
    OpaqueExportEncoder exportEncoder = const OpaqueExportEncoder(),
  }) : _authorizer = authorizer,
       _exportEncoder = exportEncoder;

  final ReceiptAuthorizer _authorizer;
  final OpaqueExportEncoder _exportEncoder;

  @override
  ReceiptAuthorizationResult authorize(
    PeerDealReceipt receipt,
    ReceiptAuthorizationRequest request,
  ) => _authorizer.authorize(receipt, request);

  @override
  ReceiptExportArtifact exportReceipt(PeerDealReceipt receipt) {
    if (!receipt.hasRequiredEnvelopeFields) {
      return const ReceiptExportArtifact.unavailable(
        reason: 'Receipt envelope is malformed.',
      );
    }

    if (receipt.wipeState == ReceiptWipeState.wiped) {
      return const ReceiptExportArtifact.unavailable(
        reason: 'Receipt unavailable.',
      );
    }

    return _exportEncoder.encode(receipt);
  }

  @override
  ReceiptScanResult scanReceipt(PeerDealReceipt receipt) {
    if (!receipt.hasRequiredEnvelopeFields) {
      return const ReceiptScanResult(
        status: 'rejected',
        message: 'Receipt envelope is malformed.',
      );
    }

    if (receipt.wipeState == ReceiptWipeState.wiped) {
      return const ReceiptScanResult(
        status: 'wiped',
        message: 'Receipt unavailable.',
      );
    }

    return ReceiptScanResult(
      status: 'ok',
      message: 'Receipt resolved for supported client view.',
      shareableFields: <String, Object?>{
        'receipt_id': receipt.receiptId,
        'mode_type': receipt.modeType,
      },
    );
  }
}
