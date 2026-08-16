import 'dart:convert';
import 'dart:math';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';
import 'native_receipt_key_ring_writer.dart';

const _maximumWarningCount = 4;
const _maximumWarningLength = 160;

typedef ReceiptKeySecretFactory = String Function();
typedef ReceiptKeyIdFactory = String Function(String purpose);

class ReceiptKeyRingProvisionResult {
  ReceiptKeyRingProvisionResult({
    required this.keyRing,
    List<String> warnings = const <String>[],
    this.keysCreated = 0,
  }) : warnings = _safeReceiptProvisionWarnings(warnings);

  final ReceiptKeyRingSnapshot keyRing;
  final List<String> warnings;
  final int keysCreated;

  bool get isSuccess =>
      warnings.isEmpty &&
      keyRing.activeSigningKey() != null &&
      keyRing.activeEncryptionKey() != null;
}

List<String> _safeReceiptProvisionWarnings(List<String> warnings) {
  final truncated = warnings.length > _maximumWarningCount;
  final valueLimit = truncated
      ? _maximumWarningCount - 1
      : _maximumWarningCount;
  final safe = <String>[];
  for (final warning in warnings) {
    if (safe.length == valueLimit) break;
    final trimmed = warning.trim();
    safe.add(
      trimmed.isEmpty ||
              trimmed != warning ||
              warning.length > _maximumWarningLength ||
              warning.codeUnits.any(
                (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
              )
          ? 'Secure receipt key provisioning warning unavailable.'
          : warning,
    );
  }
  if (truncated) {
    safe.add('Secure receipt key provisioning warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
}

class NativeReceiptKeyRingProvisioner {
  NativeReceiptKeyRingProvisioner({
    required NativeReceiptKeyRingLoader loader,
    required NativeReceiptKeyRingWriter writer,
    ReceiptKeySecretFactory? secretFactory,
    ReceiptKeyIdFactory? keyIdFactory,
  }) : _loader = loader,
       _writer = writer,
       _secretFactory = secretFactory ?? _secureSecret,
       _keyIdFactory = keyIdFactory ?? _keyId;

  factory NativeReceiptKeyRingProvisioner.methodChannel({
    String namespace = NativeReceiptKeyRingLoader.defaultNamespace,
  }) {
    final bridge = MethodChannelSecureKeyStorageBridge();
    return NativeReceiptKeyRingProvisioner(
      loader: NativeReceiptKeyRingLoader(bridge: bridge, namespace: namespace),
      writer: NativeReceiptKeyRingWriter(bridge: bridge, namespace: namespace),
    );
  }

  final NativeReceiptKeyRingLoader _loader;
  final NativeReceiptKeyRingWriter _writer;
  final ReceiptKeySecretFactory _secretFactory;
  final ReceiptKeyIdFactory _keyIdFactory;

  Future<ReceiptKeyRingProvisionResult>? _inFlight;

  Future<ReceiptKeyRingProvisionResult> ensureActiveKeys({
    Future<void>? cancellation,
  }) {
    final inFlight = _inFlight;
    if (inFlight != null && cancellation == null) return inFlight;

    final operation = _ensureActiveKeys(
      cancellation: cancellation,
      ownsInFlight: cancellation == null,
    );
    if (cancellation == null) _inFlight = operation;
    return operation;
  }

  Future<ReceiptKeyRingProvisionResult> _ensureActiveKeys({
    Future<void>? cancellation,
    required bool ownsInFlight,
  }) async {
    try {
      final loadResult = cancellation == null
          ? await _loader.load()
          : await _loader.loadCancellable(cancellation: cancellation);
      if (loadResult.warnings.isNotEmpty) {
        return ReceiptKeyRingProvisionResult(
          keyRing: loadResult.keyRing,
          warnings: loadResult.warnings,
        );
      }

      var keyRing = loadResult.keyRing;
      var revision = loadResult.revision;
      var keysCreated = 0;
      final warnings = <String>[];

      if (keyRing.activeSigningKey() == null) {
        final ReceiptSigningKey key;
        try {
          key = ReceiptSigningKey(
            keyId: _keyIdFactory('receipt_signing'),
            secret: _secretFactory(),
          );
        } on Object {
          return ReceiptKeyRingProvisionResult(
            keyRing: keyRing,
            warnings: const <String>[
              'Receipt signing key provisioning failed.',
            ],
          );
        }
        final result = await _writer.saveSigningKey(
          key,
          active: true,
          expectedRevision: revision,
          cancellation: cancellation,
        );
        if (!result.isSuccess) {
          if (result.isConflict) {
            final latest = cancellation == null
                ? await _loader.load()
                : await _loader.loadCancellable(cancellation: cancellation);
            if (latest.warnings.isEmpty &&
                latest.keyRing.activeSigningKey() != null) {
              keyRing = latest.keyRing;
              revision = latest.revision;
            } else {
              warnings.add(
                result.warning ?? 'Receipt signing key provisioning failed.',
              );
            }
          } else {
            warnings.add(
              result.warning ?? 'Receipt signing key provisioning failed.',
            );
          }
        } else {
          keysCreated += 1;
          revision = result.revision ?? revision;
          keyRing = ReceiptKeyRingSnapshot(
            activeSigning: key,
            verificationSigningKeys: keyRing.verificationSigningKeys,
            activeEncryption: keyRing.activeEncryption,
            decryptionKeys: keyRing.decryptionKeys,
          );
        }
      }

      if (warnings.isEmpty && keyRing.activeEncryptionKey() == null) {
        final ReceiptEncryptionKey key;
        try {
          key = ReceiptEncryptionKey(
            keyId: _keyIdFactory('receipt_encryption'),
            secret: _secretFactory(),
          );
        } on Object {
          return ReceiptKeyRingProvisionResult(
            keyRing: keyRing,
            warnings: const <String>[
              'Receipt encryption key provisioning failed.',
            ],
            keysCreated: keysCreated,
          );
        }
        final result = await _writer.saveEncryptionKey(
          key,
          active: true,
          expectedRevision: revision,
          cancellation: cancellation,
        );
        if (!result.isSuccess) {
          if (result.isConflict) {
            final latest = cancellation == null
                ? await _loader.load()
                : await _loader.loadCancellable(cancellation: cancellation);
            if (latest.warnings.isEmpty &&
                latest.keyRing.activeEncryptionKey() != null) {
              keyRing = latest.keyRing;
              revision = latest.revision;
            } else {
              warnings.add(
                result.warning ?? 'Receipt encryption key provisioning failed.',
              );
            }
          } else {
            warnings.add(
              result.warning ?? 'Receipt encryption key provisioning failed.',
            );
          }
        } else {
          keysCreated += 1;
          revision = result.revision ?? revision;
          keyRing = ReceiptKeyRingSnapshot(
            activeSigning: keyRing.activeSigning,
            verificationSigningKeys: keyRing.verificationSigningKeys,
            activeEncryption: key,
            decryptionKeys: keyRing.decryptionKeys,
          );
        }
      }

      if (warnings.isEmpty && keysCreated > 0) {
        final verified = cancellation == null
            ? await _loader.load()
            : await _loader.loadCancellable(cancellation: cancellation);
        if (verified.warnings.isNotEmpty ||
            !_activeKeysMatch(keyRing, verified.keyRing)) {
          return ReceiptKeyRingProvisionResult(
            keyRing: ReceiptKeyRingSnapshot(),
            warnings: const <String>[
              'Receipt key persistence could not be verified.',
            ],
            keysCreated: keysCreated,
          );
        }
        keyRing = verified.keyRing;
      }

      return ReceiptKeyRingProvisionResult(
        keyRing: keyRing,
        warnings: warnings,
        keysCreated: keysCreated,
      );
    } finally {
      if (ownsInFlight) _inFlight = null;
    }
  }

  bool _activeKeysMatch(
    ReceiptKeyRingSnapshot expected,
    ReceiptKeyRingSnapshot actual,
  ) {
    final expectedSigning = expected.activeSigningKey();
    final actualSigning = actual.activeSigningKey();
    final expectedEncryption = expected.activeEncryptionKey();
    final actualEncryption = actual.activeEncryptionKey();
    return expectedSigning?.keyId == actualSigning?.keyId &&
        expectedSigning?.secret == actualSigning?.secret &&
        expectedEncryption?.keyId == actualEncryption?.keyId &&
        expectedEncryption?.secret == actualEncryption?.secret;
  }

  static String _secureSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _keyId(String purpose) {
    final millis = DateTime.now().toUtc().millisecondsSinceEpoch;
    return '${purpose}_$millis';
  }
}
