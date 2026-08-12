import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

Map<String, Object?> demoFixtureJson(String fixtureName) {
  final workspaceLocal = File('tools/demo_slice_fixtures/$fixtureName');
  final appLocal = File('../../tools/demo_slice_fixtures/$fixtureName');
  final file = workspaceLocal.existsSync() ? workspaceLocal : appLocal;
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

RecoveryResult<Object?> demoRecoveryResult() {
  return const RecoveryResult<Object?>(
    isSuccess: false,
    reconciliation: ReconciliationResult(
      canResume: false,
      requiresRecovery: true,
      recommendedAction: 'safe_close',
    ),
    conflicts: [
      SyncConflict(
        code: 'ERR_FINAL_EVENT_HASH_MISMATCH',
        message: 'Final event hash does not match expected recovery baseline.',
        severity: SyncConflictSeverity.fatal,
        expected: 'expected_hash',
        actual: 'actual_hash',
      ),
    ],
    safeCloseRecommended: true,
  );
}

class RecordingCaptureProtectionBridge implements CaptureProtectionBridge {
  int requestCount = 0;

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    requestCount += 1;
    return const CaptureProtectionCapability(
      blockingSupported: true,
      obscuringSupported: true,
      notes: 'screen-protection-supported',
      warning: 'best-effort',
    );
  }
}

class RecordingReceiptKeyStorageBridge implements SecureKeyStorageBridge {
  final List<String> namespaces = <String>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    namespaces.add(namespace);
    return SecureKeyStorageSnapshot(
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
  }
}

ReceiptExportArtifact signedDemoReceiptArtifact() {
  return OpaqueExportEncoder(
    signer: const HmacSha256ReceiptSigner(keyProvider: _receiptKeyRing),
  ).encode(_receipt);
}

const _receiptKeyRing = ReceiptKeyRingSnapshot(
  activeSigning: ReceiptSigningKey(
    keyId: 'receipt_key_1',
    secret: 'test_secret_1',
  ),
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
