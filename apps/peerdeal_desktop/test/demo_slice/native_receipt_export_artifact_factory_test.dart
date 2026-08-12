import 'dart:async';

import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_export_artifact_factory.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_provisioner.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_writer.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  test(
    'provisions native-backed keys before signed encrypted export',
    () async {
      final bridge = _ExportBridge();
      final factory = _factory(bridge);

      final artifact = await factory.exportSignedEncrypted(_receipt);

      expect(artifact.artifactType, 'encrypted_file');
      expect(artifact.reason, isNull);
      expect(artifact.minimalMetadata['signed'], isTrue);
      expect(artifact.minimalMetadata['encrypted'], isTrue);
      expect(bridge.savedKeys.map((saved) => saved.key.purpose), <String>[
        'receipt_signing',
        'receipt_encryption',
      ]);

      final keyRing = ReceiptKeyRingSnapshot(
        activeSigning: ReceiptSigningKey(
          keyId: bridge.savedKeys[0].key.keyId,
          secret: bridge.savedKeys[0].key.secret,
        ),
        activeEncryption: ReceiptEncryptionKey(
          keyId: bridge.savedKeys[1].key.keyId,
          secret: bridge.savedKeys[1].key.secret,
        ),
      );
      final inspection = OpaqueExportDecoder(
        signer: HmacSha256ReceiptSigner(keyProvider: keyRing),
        cipher: HmacSha256ReceiptCipher(keyProvider: keyRing),
      ).inspect(artifact);

      expect(inspection.status, 'ok');
      expect(inspection.message, 'Receipt artifact verified.');
    },
  );

  test(
    'uses existing native-backed keys without provisioning writes',
    () async {
      final bridge = _ExportBridge(
        snapshot: SecureKeyStorageSnapshot(
          available: true,
          keys: <SecureKeyRecord>[
            SecureKeyRecord(
              keyId: 'receipt_signing_existing',
              purpose: 'receipt_signing',
              algorithm: 'hmac-sha256',
              secret: 'signing_existing',
              active: true,
            ),
            SecureKeyRecord(
              keyId: 'receipt_encryption_existing',
              purpose: 'receipt_encryption',
              algorithm: 'external',
              secret: 'encryption_existing',
              active: true,
            ),
          ],
        ),
      );
      final factory = _factory(bridge);

      final artifact = await factory.exportSignedEncrypted(_receipt);

      expect(artifact.artifactType, 'encrypted_file');
      expect(bridge.savedKeys, isEmpty);
    },
  );

  test('fails closed when secure key storage cannot load', () async {
    final bridge = _ExportBridge(
      snapshot: const SecureKeyStorageSnapshot.unavailable(
        warning: 'secure storage locked',
      ),
    );
    final factory = _factory(bridge);

    final artifact = await factory.exportSignedEncrypted(_receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.reason, 'Receipt key provisioning failed.');
    expect(artifact.reason, isNot(contains('locked')));
    expect(bridge.savedKeys, isEmpty);
  });

  test('fails closed when key provisioning write fails', () async {
    final bridge = _ExportBridge(
      saveResult: const SecureKeyStorageMutationResult.failure(
        warning: 'secure key save denied',
      ),
    );
    final factory = _factory(bridge);

    final artifact = await factory.exportSignedEncrypted(_receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.reason, 'Receipt key provisioning failed.');
    expect(artifact.reason, isNot(contains('denied')));
    expect(bridge.savedKeys.single.key.purpose, 'receipt_signing');
  });

  test('fails closed when key provisioning throws', () async {
    final factory = NativeReceiptExportArtifactFactory(
      keyRingProvisioner: _ThrowingProvisioner(),
      nonceFactory: () => List<int>.filled(32, 7),
    );

    final artifact = await factory.exportSignedEncrypted(_receipt);

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.reason, 'Receipt key provisioning failed.');
    expect(artifact.reason, isNot(contains('native exception')));
  });

  test('forwards route cancellation into key provisioning', () async {
    final cancellation = Completer<void>();
    final provisioner = _CancellationRecordingProvisioner();
    final factory = NativeReceiptExportArtifactFactory(
      keyRingProvisioner: provisioner,
    );

    final artifactFuture = factory.exportSignedEncrypted(
      _receipt,
      cancellation: cancellation.future,
    );

    expect(provisioner.receivedCancellation, same(cancellation.future));
    cancellation.complete();
    final artifact = await artifactFuture;

    expect(artifact.artifactType, 'unavailable');
    expect(artifact.reason, 'Receipt key provisioning failed.');
  });
}

const _receipt = PeerDealReceipt(
  receiptId: 'r_export_1',
  receiptVersion: '1.0',
  protocolVersion: '1.x',
  modeType: 'tournament',
  sessionId: 'sess_export_1',
  tableId: 'table_export_1',
  pseudonymousUserId: 'user_export_1',
  bindingMode: ReceiptBindingMode.sessionBound,
  wipeState: ReceiptWipeState.live,
  payloadHash: 'hash_export_1',
  opaquePayload: 'opaque_export_1',
);

NativeReceiptExportArtifactFactory _factory(_ExportBridge bridge) {
  var secretIndex = 0;
  return NativeReceiptExportArtifactFactory(
    keyRingProvisioner: NativeReceiptKeyRingProvisioner(
      loader: NativeReceiptKeyRingLoader(bridge: bridge),
      writer: NativeReceiptKeyRingWriter(bridge: bridge),
      secretFactory: () => 'secret_${secretIndex++}',
      keyIdFactory: (purpose) => '${purpose}_test',
    ),
    nonceFactory: () => List<int>.filled(32, 7),
  );
}

class _ExportBridge implements SecureKeyStorageMutationBridge {
  _ExportBridge({
    SecureKeyStorageSnapshot? snapshot,
    this.saveResult = const SecureKeyStorageMutationResult(isSuccess: true),
  }) : snapshot =
           snapshot ?? SecureKeyStorageSnapshot(available: true, keys: []),
       _currentSnapshot =
           snapshot ?? SecureKeyStorageSnapshot(available: true, keys: []);

  final SecureKeyStorageSnapshot snapshot;
  final SecureKeyStorageMutationResult saveResult;
  final List<_SavedKey> savedKeys = <_SavedKey>[];
  SecureKeyStorageSnapshot _currentSnapshot;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    return _currentSnapshot;
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  }) async {
    savedKeys.add(_SavedKey(namespace: namespace, key: key));
    if (saveResult.isSuccess) {
      _currentSnapshot = SecureKeyStorageSnapshot(
        available: true,
        keys: <SecureKeyRecord>[
          ..._currentSnapshot.keys.where((record) => record.keyId != key.keyId),
          key,
        ],
      );
    }
    return saveResult;
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
  }) async {
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }
}

class _SavedKey {
  const _SavedKey({required this.namespace, required this.key});

  final String namespace;
  final SecureKeyRecord key;
}

class _ThrowingProvisioner implements NativeReceiptKeyRingProvisioner {
  @override
  Future<ReceiptKeyRingProvisionResult> ensureActiveKeys({
    Future<void>? cancellation,
  }) async {
    throw StateError('native exception');
  }
}

class _CancellationRecordingProvisioner
    implements NativeReceiptKeyRingProvisioner {
  Future<void>? receivedCancellation;

  @override
  Future<ReceiptKeyRingProvisionResult> ensureActiveKeys({
    Future<void>? cancellation,
  }) async {
    receivedCancellation = cancellation;
    if (cancellation != null) await cancellation;
    return ReceiptKeyRingProvisionResult(
      keyRing: ReceiptKeyRingSnapshot(),
      warnings: <String>['cancelled'],
    );
  }
}
