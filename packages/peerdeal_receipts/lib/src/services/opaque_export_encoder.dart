import 'dart:convert';

import '../contracts/receipt_cipher.dart';
import '../contracts/receipt_signer.dart';
import '../models/peer_deal_receipt.dart';
import '../models/receipt_export_artifact.dart';
import '../models/receipt_export_limits.dart';

class OpaqueExportEncoder {
  const OpaqueExportEncoder({
    ReceiptCipher? cipher,
    ReceiptSigner? signer,
    ReceiptExportLimits limits = const ReceiptExportLimits(),
  }) : _cipher = cipher,
       _signer = signer,
       _limits = limits;

  final ReceiptCipher? _cipher;
  final ReceiptSigner? _signer;
  final ReceiptExportLimits _limits;

  ReceiptExportArtifact encode(PeerDealReceipt receipt) {
    try {
      return _encode(receipt);
    } on Object {
      return ReceiptExportArtifact.unavailable(
        reason: 'Receipt export failed.',
      );
    }
  }

  ReceiptExportArtifact _encode(PeerDealReceipt receipt) {
    _limits.validate();
    final innerBody = jsonEncode(<String, Object?>{
      'receipt_id': receipt.receiptId,
      'receipt_version': receipt.receiptVersion,
      'protocol_version': receipt.protocolVersion,
      'mode_type': receipt.modeType,
      'payload_hash': receipt.payloadHash,
      'opaque_payload': receipt.opaquePayload,
    });
    if (utf8.encode(innerBody).length > _limits.maxPayloadBytes) {
      throw StateError('Receipt payload exceeds the configured limit.');
    }

    final encrypted = _cipher != null;
    final payload = encrypted ? _cipher.encrypt(innerBody) : innerBody;
    final payloadLimit = encrypted
        ? _limits.maxCiphertextLength
        : _limits.maxPayloadBytes;
    if (utf8.encode(payload).length > payloadLimit) {
      throw StateError('Receipt export payload exceeds the configured limit.');
    }
    final signature = _signer?.sign(payload);
    final body = jsonEncode(<String, Object?>{
      'format_version': '1.0',
      'cipher': encrypted ? 'external' : 'none',
      'payload': payload,
      'signature': ?signature,
    });

    final encodedBody = base64Encode(utf8.encode(body));
    if (encodedBody.length > _limits.maxEncodedBodyLength) {
      throw StateError('Receipt artifact exceeds the configured limit.');
    }

    return ReceiptExportArtifact(
      artifactType: encrypted ? 'encrypted_file' : 'file',
      encodedBody: encodedBody,
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
