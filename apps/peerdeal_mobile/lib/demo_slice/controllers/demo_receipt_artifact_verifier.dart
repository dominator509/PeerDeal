import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';

/// Optional cancellation capability for a verifier owned by a route.
abstract interface class CancellableDemoReceiptArtifactVerifier {
  Future<ReceiptExportInspectionResult> inspectCancellable(
    ReceiptExportArtifact artifact, {
    Future<void>? cancellation,
  });
}

class DemoReceiptArtifactVerifier
    implements CancellableDemoReceiptArtifactVerifier {
  const DemoReceiptArtifactVerifier({
    required NativeReceiptKeyRingLoader keyRingLoader,
  }) : _keyRingLoader = keyRingLoader;

  final NativeReceiptKeyRingLoader _keyRingLoader;

  Future<ReceiptExportInspectionResult> inspect(
    ReceiptExportArtifact artifact,
  ) {
    return _inspect(artifact);
  }

  @override
  Future<ReceiptExportInspectionResult> inspectCancellable(
    ReceiptExportArtifact artifact, {
    Future<void>? cancellation,
  }) {
    return _inspect(artifact, cancellation: cancellation);
  }

  Future<ReceiptExportInspectionResult> _inspect(
    ReceiptExportArtifact artifact, {
    Future<void>? cancellation,
  }) async {
    final ReceiptKeyRingLoadResult loadResult;
    try {
      loadResult = await _keyRingLoader.loadCancellable(
        cancellation: cancellation,
      );
    } catch (_) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt signing key is unavailable.',
        diagnostics: <String>['Secure receipt key storage is unavailable.'],
      );
    }

    if (!loadResult.hasSigningKey) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt signing key is unavailable.',
        diagnostics: _safeDiagnostics(loadResult.warnings),
      );
    }

    final signer = HmacSha256ReceiptSigner(keyProvider: loadResult.keyRing);
    final encrypted = artifact.minimalMetadata['encrypted'] == true;
    if (encrypted && !loadResult.hasEncryptionKey) {
      return ReceiptExportInspectionResult.rejected(
        message: 'Receipt encryption key is unavailable.',
        diagnostics: _safeDiagnostics(loadResult.warnings),
      );
    }

    final cipher = loadResult.hasEncryptionKey
        ? HmacSha256ReceiptCipher(keyProvider: loadResult.keyRing)
        : null;
    return _safeInspectionResult(
      OpaqueExportDecoder(cipher: cipher, signer: signer).inspect(artifact),
    );
  }
}

ReceiptExportInspectionResult _safeInspectionResult(
  ReceiptExportInspectionResult result,
) {
  if (result.isAccepted) {
    return result;
  }
  return ReceiptExportInspectionResult.rejected(
    message: result.message,
    diagnostics: _safeDiagnostics(result.diagnostics, fallbackOnEmpty: false),
  );
}

List<String> _safeDiagnostics(
  List<String> warnings, {
  bool fallbackOnEmpty = true,
}) {
  const fallback = 'Secure receipt key storage is unavailable.';
  const lowerLayerFallback = 'Secure receipt key warning unavailable.';
  const lowerLayerTruncation = 'Secure receipt key warnings truncated.';
  const truncation = 'Secure receipt key diagnostics truncated.';
  const maxDiagnostics = 4;
  const maxDiagnosticLength = 160;
  if (warnings.isEmpty) {
    return fallbackOnEmpty ? const <String>[fallback] : const <String>[];
  }
  final sanitized = <String>[];
  var lowerLayerTruncated = false;
  for (final warning in warnings.take(maxDiagnostics)) {
    final trimmed = warning.trim();
    if (trimmed == lowerLayerTruncation) {
      lowerLayerTruncated = true;
      continue;
    }
    if (trimmed == lowerLayerFallback) {
      sanitized.add(fallback);
      continue;
    }
    if (trimmed.isEmpty ||
        trimmed.length > maxDiagnosticLength ||
        !_isSafeDiagnostic(trimmed)) {
      sanitized.add(fallback);
    } else {
      sanitized.add(trimmed);
    }
  }
  if (warnings.length > maxDiagnostics || lowerLayerTruncated) {
    sanitized.add(truncation);
  }
  return sanitized;
}

bool _isSafeDiagnostic(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('secret') ||
      lower.contains('token') ||
      lower.contains('password') ||
      lower.contains('credential')) {
    return false;
  }
  for (final unit in value.codeUnits) {
    if (unit < 0x20 || (unit >= 0x7f && unit <= 0x9f)) {
      return false;
    }
  }
  return true;
}
