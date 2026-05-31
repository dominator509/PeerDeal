import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
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
    expect(result.diagnostics, ['secure storage locked']);
  });
}

const _availableSnapshot = SecureKeyStorageSnapshot(
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
