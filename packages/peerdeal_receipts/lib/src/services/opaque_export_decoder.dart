import 'dart:convert';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/receipt_cipher.dart';
import '../contracts/receipt_signer.dart';
import '../models/receipt_export_artifact.dart';
import '../models/receipt_export_inspection_result.dart';
import '../models/receipt_export_limits.dart';

class OpaqueExportDecoder {
  const OpaqueExportDecoder({
    ReceiptCipher? cipher,
    ReceiptSigner? signer,
    bool requireSignature = true,
    ReceiptExportLimits limits = const ReceiptExportLimits(),
  }) : _cipher = cipher,
       _signer = signer,
       _requireSignature = requireSignature,
       _limits = limits;

  final ReceiptCipher? _cipher;
  final ReceiptSigner? _signer;
  final bool _requireSignature;
  final ReceiptExportLimits _limits;

  ReceiptExportInspectionResult inspect(ReceiptExportArtifact artifact) {
    if (artifact.artifactType == 'unavailable') {
      return ReceiptExportInspectionResult.rejected(
        message: artifact.reason ?? 'Receipt artifact is unavailable.',
      );
    }

    final body = _decodeArtifactBody(artifact.encodedBody);
    if (body == null) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact body is malformed.',
      );
    }

    if (body['format_version'] != '1.0') {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact format is unsupported.',
        diagnostics: <String>['format_version:${body['format_version']}'],
      );
    }

    final payload = body['payload'];
    if (payload is! String || payload.isEmpty) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact payload is malformed.',
      );
    }
    final payloadBytes = utf8.encode(payload).length;
    final payloadLimit = body['cipher'] == 'external'
        ? _limits.maxCiphertextLength
        : _limits.maxPayloadBytes;
    if (payloadBytes > payloadLimit) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact payload is malformed.',
      );
    }

    final signature = body['signature'];
    if (signature == null && _requireSignature) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact is unsigned.',
      );
    }

    if (signature != null) {
      final signer = _signer;
      if (signer == null || signature is! String || signature.isEmpty) {
        return ReceiptExportInspectionResult.rejected(
          message: 'Receipt artifact signature cannot be verified.',
        );
      }
      final isVerified = _verifySignature(
        signer: signer,
        payload: payload,
        signature: signature,
      );
      if (!isVerified) {
        return ReceiptExportInspectionResult.rejected(
          message: 'Receipt artifact signature verification failed.',
        );
      }
    }

    final plaintextPayload = _decodePayload(
      cipherLabel: body['cipher'],
      payload: payload,
    );
    if (plaintextPayload == null) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact payload cannot be decoded.',
      );
    }

    final payloadShape = _decodePayloadShape(plaintextPayload);
    if (payloadShape == null || !_hasRequiredPayloadFields(payloadShape)) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact payload shape is unsupported.',
      );
    }

    return ReceiptExportInspectionResult(
      status: 'ok',
      message: 'Receipt artifact verified.',
      payload: payloadShape,
    );
  }

  Map<String, Object?>? _decodeArtifactBody(String encodedBody) {
    try {
      _limits.validate();
      if (encodedBody.length > _limits.maxEncodedBodyLength) return null;
      final decodedBytes = base64Decode(encodedBody);
      if (decodedBytes.length > _limits.maxDecodedBodyBytes) return null;
      final decoded = jsonDecode(utf8.decode(decodedBytes));
      if (decoded is! Map<String, Object?>) return null;
      canonicalJsonEncode(
        decoded,
        limits: CanonicalJsonLimits(
          maxTextBytes: _limits.maxDecodedBodyBytes,
          maxEncodedBytes: _limits.maxDecodedBodyBytes,
        ),
      );
      return decoded;
    } on Object {
      return null;
    }
  }

  String? _decodePayload({
    required Object? cipherLabel,
    required String payload,
  }) {
    if (cipherLabel == 'none') return payload;
    if (cipherLabel == 'external') {
      final cipher = _cipher;
      if (cipher == null) return null;
      try {
        return cipher.decrypt(payload);
      } on Object {
        return null;
      }
    }
    return null;
  }

  bool _verifySignature({
    required ReceiptSigner signer,
    required String payload,
    required String signature,
  }) {
    try {
      return signer.verify(payload: payload, signature: signature);
    } on Object {
      return false;
    }
  }

  Map<String, Object?>? _decodePayloadShape(String payload) {
    try {
      if (utf8.encode(payload).length > _limits.maxPayloadBytes) return null;
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?>) return null;
      canonicalJsonEncode(
        decoded,
        limits: CanonicalJsonLimits(
          maxTextBytes: _limits.maxPayloadBytes,
          maxEncodedBytes: _limits.maxPayloadBytes,
        ),
      );
      return decoded;
    } on Object {
      return null;
    }
  }

  bool _hasRequiredPayloadFields(Map<String, Object?> payload) {
    return _safeRequiredText(payload['receipt_id']) &&
        _safeRequiredText(payload['receipt_version']) &&
        _safeRequiredText(payload['protocol_version']) &&
        _safeRequiredText(payload['mode_type']) &&
        _safeRequiredText(payload['payload_hash']) &&
        _nonEmpty(payload['opaque_payload']) &&
        !payload.containsKey('table_id');
  }

  bool _nonEmpty(Object? value) => value is String && value.trim().isNotEmpty;

  bool _safeRequiredText(Object? value) {
    if (!_nonEmpty(value)) return false;
    final text = value! as String;
    if (text.trim() != text) return false;
    final bytes = utf8.encode(text);
    if (bytes.length > _limits.maxPayloadBytes) return false;
    try {
      if (utf8.decode(bytes) != text) return false;
    } on FormatException {
      return false;
    }
    return !text.codeUnits.any(
      (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
    );
  }
}
