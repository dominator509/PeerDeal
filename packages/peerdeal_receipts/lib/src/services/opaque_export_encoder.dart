import 'dart:convert';

import '../contracts/receipt_cipher.dart';
import '../contracts/receipt_signer.dart';
import '../models/peer_deal_receipt.dart';
import '../models/receipt_export_artifact.dart';

class OpaqueExportEncoder {
  const OpaqueExportEncoder({ReceiptCipher? cipher, ReceiptSigner? signer})
    : _cipher = cipher,
      _signer = signer;

  final ReceiptCipher? _cipher;
  final ReceiptSigner? _signer;

  ReceiptExportArtifact encode(PeerDealReceipt receipt) {
    try {
      return _encode(receipt);
    } on Object {
      return const ReceiptExportArtifact.unavailable(
        reason: 'Receipt export failed.',
      );
    }
  }

  ReceiptExportArtifact _encode(PeerDealReceipt receipt) {
    final innerBody = jsonEncode(<String, Object?>{
      'receipt_id': receipt.receiptId,
      'receipt_version': receipt.receiptVersion,
      'protocol_version': receipt.protocolVersion,
      'mode_type': receipt.modeType,
      'payload_hash': receipt.payloadHash,
      'opaque_payload': receipt.opaquePayload,
    });

    final encrypted = _cipher != null;
    final payload = encrypted ? _cipher.encrypt(innerBody) : innerBody;
    final signature = _signer?.sign(payload);
    final body = jsonEncode(<String, Object?>{
      'format_version': '1.0',
      'cipher': encrypted ? 'external' : 'none',
      'payload': payload,
      'signature': ?signature,
    });

    return ReceiptExportArtifact(
      artifactType: encrypted ? 'encrypted_file' : 'file',
      encodedBody: base64Encode(utf8.encode(body)),
      minimalMetadata: <String, Object?>{
        'receipt_id': receipt.receiptId,
        'receipt_version': receipt.receiptVersion,
        'protocol_version': receipt.protocolVersion,
        'mode_type': receipt.modeType,
        'encrypted': encrypted,
        'signed': signature != null,
      },
    );
  }
}
