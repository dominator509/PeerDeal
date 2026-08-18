import 'dart:convert';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

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
    if (!_hasSafeEnvelopeText(receipt)) {
      throw StateError('Receipt envelope text is malformed.');
    }
    final innerBody = jsonEncode(<String, Object?>{
      'receipt_id': receipt.receiptId,
      'receipt_version': receipt.receiptVersion,
      'protocol_version': receipt.protocolVersion,
      'mode_type': receipt.modeType,
      'payload_hash': receipt.payloadHash,
      'opaque_payload': receipt.opaquePayload,
    });
    if (!CanonicalJsonLimits(
      maxTextBytes: _limits.maxPayloadBytes,
    ).isWithinUtf8TextLimit(innerBody)) {
      throw StateError('Receipt payload exceeds the configured limit.');
    }

    final encrypted = _cipher != null;
    final payload = encrypted ? _cipher.encrypt(innerBody) : innerBody;
    final payloadLimit = encrypted
        ? _limits.maxCiphertextLength
        : _limits.maxPayloadBytes;
    if (!CanonicalJsonLimits(
      maxTextBytes: payloadLimit,
    ).isWithinUtf8TextLimit(payload)) {
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

  bool _hasSafeEnvelopeText(PeerDealReceipt receipt) {
    final limits = CanonicalJsonLimits(maxTextBytes: _limits.maxPayloadBytes);
    final values = <String>[
      receipt.receiptId,
      receipt.receiptVersion,
      receipt.protocolVersion,
      receipt.modeType,
      receipt.sessionId,
      receipt.tableId,
      receipt.pseudonymousUserId,
      receipt.payloadHash,
      receipt.opaquePayload,
    ];
    return receipt.hasRequiredEnvelopeFields &&
        values.every(
          (value) =>
              value.trim() == value &&
              limits.isWithinUtf8TextLimit(value) &&
              !value.codeUnits.any(
                (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
              ),
        );
  }
}
