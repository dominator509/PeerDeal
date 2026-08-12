import 'dart:async';
import 'dart:convert';

import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  test('verifies signed artifacts using native-loaded receipt keys', () async {
    final keyRingLoader = NativeReceiptKeyRingLoader(
      bridge: _FakeSecureKeyStorageBridge(snapshot: _availableSnapshot),
    );
    final verifier = DemoReceiptArtifactVerifier(keyRingLoader: keyRingLoader);
    final signer = HmacSha256ReceiptSigner(
      keyProvider: (await keyRingLoader.load()).keyRing,
    );

    final result = await verifier.inspect(
      OpaqueExportEncoder(signer: signer).encode(_receipt),
    );

    expect(result.status, 'ok');
    expect(result.payload['receipt_id'], 'r_1');
  });

  test('decrypts signed artifacts using native-loaded receipt keys', () async {
    final keyRingLoader = NativeReceiptKeyRingLoader(
      bridge: _FakeSecureKeyStorageBridge(snapshot: _availableSnapshot),
    );
    final keyRing = (await keyRingLoader.load()).keyRing;
    final verifier = DemoReceiptArtifactVerifier(keyRingLoader: keyRingLoader);
    final signer = HmacSha256ReceiptSigner(keyProvider: keyRing);
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: keyRing,
      nonceFactory: () => List<int>.filled(32, 4),
    );

    final result = await verifier.inspect(
      OpaqueExportEncoder(cipher: cipher, signer: signer).encode(_receipt),
    );

    expect(result.status, 'ok');
    expect(result.payload['receipt_id'], 'r_1');
    expect(result.payload['opaque_payload'], 'opaque_77');
  });

  test('fails closed when native encryption key is unavailable', () async {
    final keyRingLoader = NativeReceiptKeyRingLoader(
      bridge: _FakeSecureKeyStorageBridge(snapshot: _signingOnlySnapshot),
    );
    final fullKeyRing = (await NativeReceiptKeyRingLoader(
      bridge: _FakeSecureKeyStorageBridge(snapshot: _availableSnapshot),
    ).load()).keyRing;
    final signer = HmacSha256ReceiptSigner(keyProvider: fullKeyRing);
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: fullKeyRing,
      nonceFactory: () => List<int>.filled(32, 4),
    );
    final verifier = DemoReceiptArtifactVerifier(keyRingLoader: keyRingLoader);

    final result = await verifier.inspect(
      OpaqueExportEncoder(cipher: cipher, signer: signer).encode(_receipt),
    );

    expect(result.status, 'rejected');
    expect(result.message, 'Receipt encryption key is unavailable.');
  });

  test('fails closed when native signing key is unavailable', () async {
    final verifier = DemoReceiptArtifactVerifier(
      keyRingLoader: NativeReceiptKeyRingLoader(
        bridge: _FakeSecureKeyStorageBridge(
          snapshot: const SecureKeyStorageSnapshot.unavailable(
            warning: 'secure storage locked',
          ),
        ),
      ),
    );

    final result = await verifier.inspect(
      const OpaqueExportEncoder().encode(_receipt),
    );

    expect(result.status, 'rejected');
    expect(result.message, 'Receipt signing key is unavailable.');
    expect(result.diagnostics, [
      'Secure receipt key storage reported a platform warning.',
    ]);
  });

  test('fails closed when key-ring loader throws', () async {
    final verifier = DemoReceiptArtifactVerifier(
      keyRingLoader: _ThrowingKeyRingLoader(),
    );

    final result = await verifier.inspect(
      const OpaqueExportEncoder().encode(_receipt),
    );

    expect(result.status, 'rejected');
    expect(result.message, 'Receipt signing key is unavailable.');
    expect(result.diagnostics, ['Secure receipt key storage is unavailable.']);
    expect(result.diagnostics, isNot(contains('native exception')));
  });

  test('forwards cancellation to the key-ring loader', () async {
    final loader = _RecordingCancellableKeyRingLoader();
    final cancellation = Completer<void>();
    final verifier = DemoReceiptArtifactVerifier(keyRingLoader: loader);

    final result = await verifier.inspectCancellable(
      const OpaqueExportEncoder().encode(_receipt),
      cancellation: cancellation.future,
    );

    expect(result.status, 'rejected');
    expect(loader.cancellation, same(cancellation.future));
  });

  test('scrubs unsafe key-ring loader warning diagnostics', () async {
    final verifier = DemoReceiptArtifactVerifier(
      keyRingLoader: _StaticKeyRingLoader(
        result: ReceiptKeyRingLoadResult(
          keyRing: ReceiptKeyRingSnapshot(),
          warnings: <String>[
            'secret=abc123',
            'native\nexception',
            '',
            'safe warning',
            'extra warning',
          ],
        ),
      ),
    );

    final result = await verifier.inspect(
      const OpaqueExportEncoder().encode(_receipt),
    );

    expect(result.status, 'rejected');
    expect(result.diagnostics, <String>[
      'Secure receipt key storage is unavailable.',
      'Secure receipt key storage is unavailable.',
      'Secure receipt key storage is unavailable.',
      'safe warning',
      'Secure receipt key diagnostics truncated.',
    ]);
  });

  test(
    'scrubs unsafe decoder diagnostics before returning rejection',
    () async {
      final keyRingLoader = NativeReceiptKeyRingLoader(
        bridge: _FakeSecureKeyStorageBridge(snapshot: _availableSnapshot),
      );
      final verifier = DemoReceiptArtifactVerifier(
        keyRingLoader: keyRingLoader,
      );

      final result = await verifier.inspect(
        _artifactWithFormatVersion('secret\nformat'),
      );

      expect(result.status, 'rejected');
      expect(result.message, 'Receipt artifact format is unsupported.');
      expect(result.diagnostics, <String>[
        'Secure receipt key storage is unavailable.',
      ]);
    },
  );
}

final _availableSnapshot = SecureKeyStorageSnapshot(
  available: true,
  keys: <SecureKeyRecord>[
    SecureKeyRecord(
      keyId: 'receipt_key_1',
      purpose: 'receipt_signing',
      algorithm: 'hmac-sha256',
      secret: 'test_secret_1',
      active: true,
    ),
    SecureKeyRecord(
      keyId: 'receipt_encryption_1',
      purpose: 'receipt_encryption',
      algorithm: 'external',
      secret: 'encryption_secret_1',
      active: true,
    ),
  ],
);

final _signingOnlySnapshot = SecureKeyStorageSnapshot(
  available: true,
  keys: <SecureKeyRecord>[
    SecureKeyRecord(
      keyId: 'receipt_key_1',
      purpose: 'receipt_signing',
      algorithm: 'hmac-sha256',
      secret: 'test_secret_1',
      active: true,
    ),
  ],
);

const _receipt = PeerDealReceipt(
  receiptId: 'r_1',
  receiptVersion: '1.0',
  protocolVersion: '1.x',
  modeType: 'tournament',
  sessionId: 'sess_77',
  tableId: 'table_7',
  pseudonymousUserId: 'user_7',
  bindingMode: ReceiptBindingMode.sessionBound,
  wipeState: ReceiptWipeState.live,
  payloadHash: 'hash_77',
  opaquePayload: 'opaque_77',
);

ReceiptExportArtifact _artifactWithFormatVersion(String formatVersion) {
  final body = <String, Object?>{
    'format_version': formatVersion,
    'payload': '{}',
  };
  return ReceiptExportArtifact(
    artifactType: 'opaque',
    encodedBody: base64Encode(utf8.encode(jsonEncode(body))),
    minimalMetadata: const <String, Object?>{},
  );
}

class _FakeSecureKeyStorageBridge implements SecureKeyStorageBridge {
  const _FakeSecureKeyStorageBridge({required this.snapshot});

  final SecureKeyStorageSnapshot snapshot;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    return snapshot;
  }
}

class _ThrowingKeyRingLoader implements NativeReceiptKeyRingLoader {
  @override
  final int maxKeyIdLength = 96;

  @override
  final int maxKeyRecords = 64;

  @override
  final int maxKeySecretLength = 256;

  @override
  final String namespace = NativeReceiptKeyRingLoader.defaultNamespace;

  @override
  Future<ReceiptKeyRingLoadResult> load() async {
    throw StateError('native exception');
  }

  @override
  Future<ReceiptKeyRingLoadResult> loadCancellable({
    Future<void>? cancellation,
  }) => load();
}

class _StaticKeyRingLoader implements NativeReceiptKeyRingLoader {
  const _StaticKeyRingLoader({required this.result});

  final ReceiptKeyRingLoadResult result;

  @override
  final int maxKeyIdLength = 96;

  @override
  final int maxKeyRecords = 64;

  @override
  final int maxKeySecretLength = 256;

  @override
  final String namespace = NativeReceiptKeyRingLoader.defaultNamespace;

  @override
  Future<ReceiptKeyRingLoadResult> load() async {
    return result;
  }

  @override
  Future<ReceiptKeyRingLoadResult> loadCancellable({
    Future<void>? cancellation,
  }) => load();
}

class _RecordingCancellableKeyRingLoader implements NativeReceiptKeyRingLoader {
  Future<void>? cancellation;

  @override
  final int maxKeyIdLength = 96;

  @override
  final int maxKeyRecords = 64;

  @override
  final int maxKeySecretLength = 256;

  @override
  final String namespace = NativeReceiptKeyRingLoader.defaultNamespace;

  @override
  Future<ReceiptKeyRingLoadResult> load() async {
    return ReceiptKeyRingLoadResult(keyRing: ReceiptKeyRingSnapshot());
  }

  @override
  Future<ReceiptKeyRingLoadResult> loadCancellable({
    Future<void>? cancellation,
  }) async {
    this.cancellation = cancellation;
    return load();
  }
}
