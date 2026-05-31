import 'dart:convert';

import '../contracts/receipt_cipher.dart';
import '../contracts/receipt_signer.dart';
import '../models/receipt_export_artifact.dart';
import '../models/receipt_export_inspection_result.dart';

class OpaqueExportDecoder {
  const OpaqueExportDecoder({
    ReceiptCipher? cipher,
    ReceiptSigner? signer,
    bool requireSignature = true,
  }) : _cipher = cipher,
       _signer = signer,
       _requireSignature = requireSignature;

  final ReceiptCipher? _cipher;
  final ReceiptSigner? _signer;
  final bool _requireSignature;

  ReceiptExportInspectionResult inspect(ReceiptExportArtifact artifact) {
    if (artifact.artifactType == 'unavailable') {
      return ReceiptExportInspectionResult.rejected(
        message: artifact.reason ?? 'Receipt artifact is unavailable.',
      );
    }

    final body = _decodeArtifactBody(artifact.encodedBody);
    if (body == null) {
      return const ReceiptExportInspectionResult.rejected(
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
      return const ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact payload is malformed.',
      );
    }

    final signature = body['signature'];
    if (signature == null && _requireSignature) {
      return const ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact is unsigned.',
      );
    }

    if (signature != null) {
      final signer = _signer;
      if (signer == null || signature is! String || signature.isEmpty) {
        return const ReceiptExportInspectionResult.rejected(
          message: 'Receipt artifact signature cannot be verified.',
        );
      }
      if (!signer.verify(payload: payload, signature: signature)) {
        return const ReceiptExportInspectionResult.rejected(
          message: 'Receipt artifact signature verification failed.',
        );
      }
    }

    final plaintextPayload = _decodePayload(
      cipherLabel: body['cipher'],
      payload: payload,
    );
    if (plaintextPayload == null) {
      return const ReceiptExportInspectionResult.rejected(
        message: 'Receipt artifact payload cannot be decoded.',
      );
    }

    final payloadShape = _decodePayloadShape(plaintextPayload);
    if (payloadShape == null || !_hasRequiredPayloadFields(payloadShape)) {
      return const ReceiptExportInspectionResult.rejected(
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
      final decoded = jsonDecode(utf8.decode(base64Decode(encodedBody)));
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
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

  Map<String, Object?>? _decodePayloadShape(String payload) {
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  bool _hasRequiredPayloadFields(Map<String, Object?> payload) {
    return _nonEmpty(payload['receipt_id']) &&
        _nonEmpty(payload['receipt_version']) &&
        _nonEmpty(payload['protocol_version']) &&
        _nonEmpty(payload['mode_type']) &&
        _nonEmpty(payload['payload_hash']) &&
        _nonEmpty(payload['opaque_payload']) &&
        !payload.containsKey('table_id');
  }

  bool _nonEmpty(Object? value) => value is String && value.trim().isNotEmpty;
}
