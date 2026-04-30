import 'dart:convert';

import '../models/peer_deal_receipt.dart';
import '../models/receipt_export_artifact.dart';

class OpaqueExportEncoder {
  const OpaqueExportEncoder();

  ReceiptExportArtifact encode(PeerDealReceipt receipt) {
    final body = jsonEncode(<String, Object?>{
      'receipt_id': receipt.receiptId,
      'opaque_payload': receipt.opaquePayload,
      'payload_hash': receipt.payloadHash,
    });

    return ReceiptExportArtifact(
      artifactType: 'file',
      encodedBody: base64Encode(utf8.encode(body)),
      minimalMetadata: <String, Object?>{
        'receipt_id': receipt.receiptId,
        'mode_type': receipt.modeType,
        'table_id': receipt.tableId,
      },
    );
  }
}
