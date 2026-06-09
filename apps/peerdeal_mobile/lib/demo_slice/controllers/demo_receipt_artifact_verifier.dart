import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';

class DemoReceiptArtifactVerifier {
  const DemoReceiptArtifactVerifier({
    required NativeReceiptKeyRingLoader keyRingLoader,
  }) : _keyRingLoader = keyRingLoader;

  final NativeReceiptKeyRingLoader _keyRingLoader;

  Future<ReceiptExportInspectionResult> inspect(
    ReceiptExportArtifact artifact,
  ) async {
    final ReceiptKeyRingLoadResult loadResult;
    try {
      loadResult = await _keyRingLoader.load();
    } catch (_) {
      return const ReceiptExportInspectionResult.rejected(
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
  const maxDiagnostics = 4;
  const maxDiagnosticLength = 160;
  if (warnings.isEmpty) {
    return fallbackOnEmpty ? const <String>[fallback] : const <String>[];
  }
  final sanitized = <String>[];
  for (final warning in warnings.take(maxDiagnostics)) {
    final trimmed = warning.trim();
    if (trimmed.isEmpty ||
        trimmed.length > maxDiagnosticLength ||
        !_isSafeDiagnostic(trimmed)) {
      sanitized.add(fallback);
    } else {
      sanitized.add(trimmed);
    }
  }
  if (warnings.length > maxDiagnostics) {
    sanitized.add('Secure receipt key diagnostics truncated.');
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
    if (unit < 0x20 || unit == 0x7f) {
      return false;
    }
  }
  return true;
}
