import 'dart:convert';
import 'dart:math';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import 'native_receipt_key_ring_loader.dart';
import 'native_receipt_key_ring_writer.dart';

typedef ReceiptKeySecretFactory = String Function();
typedef ReceiptKeyIdFactory = String Function(String purpose);

class ReceiptKeyRingProvisionResult {
  const ReceiptKeyRingProvisionResult({
    required this.keyRing,
    this.warnings = const <String>[],
    this.keysCreated = 0,
  });

  final ReceiptKeyRingSnapshot keyRing;
  final List<String> warnings;
  final int keysCreated;

  bool get isSuccess =>
      warnings.isEmpty &&
      keyRing.activeSigningKey() != null &&
      keyRing.activeEncryptionKey() != null;
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

  Future<ReceiptKeyRingProvisionResult> ensureActiveKeys() async {
    final loadResult = await _loader.load();
    if (loadResult.warnings.isNotEmpty) {
      return ReceiptKeyRingProvisionResult(
        keyRing: loadResult.keyRing,
        warnings: loadResult.warnings,
      );
    }

    var keyRing = loadResult.keyRing;
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
          warnings: const <String>['Receipt signing key provisioning failed.'],
        );
      }
      final result = await _writer.saveSigningKey(key, active: true);
      if (!result.isSuccess) {
        warnings.add(
          result.warning ?? 'Receipt signing key provisioning failed.',
        );
      } else {
        keysCreated += 1;
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
      final result = await _writer.saveEncryptionKey(key, active: true);
      if (!result.isSuccess) {
        warnings.add(
          result.warning ?? 'Receipt encryption key provisioning failed.',
        );
      } else {
        keysCreated += 1;
        keyRing = ReceiptKeyRingSnapshot(
          activeSigning: keyRing.activeSigning,
          verificationSigningKeys: keyRing.verificationSigningKeys,
          activeEncryption: key,
          decryptionKeys: keyRing.decryptionKeys,
        );
      }
    }

    return ReceiptKeyRingProvisionResult(
      keyRing: keyRing,
      warnings: warnings,
      keysCreated: keysCreated,
    );
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
