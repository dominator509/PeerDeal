import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_artifact_verifier_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  test('creates verifier backed by the provided secure key bridge', () async {
    final bridge = _FakeSecureKeyStorageBridge(snapshot: _availableSnapshot);
    final verifier = DemoReceiptArtifactVerifierFactory(
      bridge: bridge,
      namespace: 'peerdeal.receipts.test',
    ).create();

    final result = await verifier.inspect(
      OpaqueExportEncoder(signer: _signer).encode(_receipt),
    );

    expect(bridge.namespaces, <String>['peerdeal.receipts.test']);
    expect(result.status, 'ok');
    expect(result.payload['receipt_id'], 'r_1');
  });
}

const _keyRing = ReceiptKeyRingSnapshot(
  activeSigning: ReceiptSigningKey(
    keyId: 'receipt_key_1',
    secret: 'test_secret_1',
  ),
);

const _signer = HmacSha256ReceiptSigner(keyProvider: _keyRing);

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
  _FakeSecureKeyStorageBridge({required this.snapshot});

  final SecureKeyStorageSnapshot snapshot;
  final List<String> namespaces = <String>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    namespaces.add(namespace);
    return snapshot;
  }
}
