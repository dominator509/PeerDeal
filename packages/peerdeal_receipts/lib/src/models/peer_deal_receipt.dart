import 'package:peerdeal_protocol/peerdeal_protocol.dart';

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

  bool get hasRequiredEnvelopeFields => <String>[
    receiptId,
    receiptVersion,
    protocolVersion,
    modeType,
    sessionId,
    tableId,
    pseudonymousUserId,
    payloadHash,
    opaquePayload,
  ].every(_isSafeRequiredText);

  static bool _isSafeRequiredText(String value) {
    if (value.trim().isEmpty || value.trim() != value) return false;
    if (!const CanonicalJsonLimits().isWithinUtf8TextLimit(value)) {
      return false;
    }
    return !value.codeUnits.any(
      (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
    );
  }
}
