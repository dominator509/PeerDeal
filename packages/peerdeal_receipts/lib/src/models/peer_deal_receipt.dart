import 'receipt_binding_mode.dart';
import 'receipt_wipe_state.dart';

class PeerDealReceipt {
  const PeerDealReceipt({
    required this.receiptId,
    required this.receiptVersion,
    required this.protocolVersion,
    required this.modeType,
    required this.sessionId,
    required this.tableId,
    required this.pseudonymousUserId,
    required this.bindingMode,
    required this.wipeState,
    required this.payloadHash,
    required this.opaquePayload,
    this.closedAt,
    this.signature,
  });

  final String receiptId;
  final String receiptVersion;
  final String protocolVersion;
  final String modeType;
  final String sessionId;
  final String tableId;
  final String pseudonymousUserId;
  final ReceiptBindingMode bindingMode;
  final ReceiptWipeState wipeState;
  final String payloadHash;
  final String opaquePayload;
  final String? closedAt;
  final String? signature;

  bool get isWiped => wipeState == ReceiptWipeState.wiped;
}
