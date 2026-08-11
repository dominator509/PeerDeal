import 'dart:async';

import 'package:peerdeal_mobile/session/native_local_peer_identity_loader.dart';
import 'package:peerdeal_mobile/session/native_local_peer_identity_provisioner.dart';
import 'package:peerdeal_mobile/session/native_local_peer_identity_writer.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('loads one active local peer identity record', () async {
    final bridge = _MemorySecureKeyBridge(
      keys: const <SecureKeyRecord>[
        SecureKeyRecord(
          keyId: 'local_peer_id',
          purpose: 'peer_identity',
          algorithm: 'opaque-peer-id',
          secret: 'peer_existing',
          active: true,
        ),
      ],
    );

    final result = await NativeLocalPeerIdentityLoader(bridge: bridge).load();

    expect(result.isAvailable, isTrue);
    expect(result.identity?.peerId, 'peer_existing');
    expect(bridge.loadCalls, 1);
  });

  test('reports a missing identity without inventing one', () async {
    final bridge = _MemorySecureKeyBridge();

    final result = await NativeLocalPeerIdentityLoader(bridge: bridge).load();

    expect(result.isMissing, isTrue);
    expect(result.warnings, isEmpty);
  });

  test('fails closed when secure identity storage is unavailable', () async {
    final result = await NativeLocalPeerIdentityLoader(
      bridge: _MemorySecureKeyBridge(available: false),
    ).load();

    expect(result.isAvailable, isFalse);
    expect(result.warnings, <String>[
      'Local peer identity storage is unavailable.',
    ]);
  });

  test('fails closed on ambiguous active identity records', () async {
    final bridge = _MemorySecureKeyBridge(
      keys: const <SecureKeyRecord>[
        SecureKeyRecord(
          keyId: 'local_peer_id',
          purpose: 'peer_identity',
          algorithm: 'opaque-peer-id',
          secret: 'peer_one',
          active: true,
        ),
        SecureKeyRecord(
          keyId: 'local_peer_id',
          purpose: 'peer_identity',
          algorithm: 'opaque-peer-id',
          secret: 'peer_two',
          active: true,
        ),
      ],
    );

    final result = await NativeLocalPeerIdentityLoader(bridge: bridge).load();

    expect(result.isAvailable, isFalse);
    expect(result.warnings, <String>[
      'Local peer identity records are ambiguous.',
    ]);
  });

  test('provisions once and reuses the persisted identity', () async {
    final bridge = _MemorySecureKeyBridge();
    final provisioner = NativeLocalPeerIdentityProvisioner(
      loader: NativeLocalPeerIdentityLoader(bridge: bridge),
      writer: NativeLocalPeerIdentityWriter(bridge: bridge),
      identityFactory: () => 'peer_generated',
    );

    final first = await provisioner.ensureIdentity();
    final second = await provisioner.ensureIdentity();

    expect(first.isSuccess, isTrue);
    expect(first.created, isTrue);
    expect(first.identity?.peerId, 'peer_generated');
    expect(second.isSuccess, isTrue);
    expect(second.created, isFalse);
    expect(second.identity?.peerId, 'peer_generated');
    expect(bridge.savedKeys, hasLength(1));
  });

  test('single-flights concurrent identity provisioning', () async {
    final loadGate = Completer<void>();
    final bridge = _MemorySecureKeyBridge(loadGate: loadGate);
    var generated = 0;
    final provisioner = NativeLocalPeerIdentityProvisioner(
      loader: NativeLocalPeerIdentityLoader(bridge: bridge),
      writer: NativeLocalPeerIdentityWriter(bridge: bridge),
      identityFactory: () {
        generated += 1;
        return 'peer_concurrent';
      },
    );

    final first = provisioner.ensureIdentity();
    final second = provisioner.ensureIdentity();
    loadGate.complete();
    final results = await Future.wait(
      <Future<AppLocalPeerIdentityProvisionResult>>[first, second],
    );

    expect(results, hasLength(2));
    expect(results.every((result) => result.isSuccess), isTrue);
    expect(results.map((result) => result.identity?.peerId), <String?>[
      'peer_concurrent',
      'peer_concurrent',
    ]);
    expect(generated, 1);
    expect(bridge.loadCalls, 1);
    expect(bridge.savedKeys, hasLength(1));
  });
}

class _MemorySecureKeyBridge implements SecureKeyStorageMutationBridge {
  _MemorySecureKeyBridge({
    List<SecureKeyRecord> keys = const <SecureKeyRecord>[],
    this.available = true,
    this.loadGate,
  }) : keys = List<SecureKeyRecord>.from(keys);

  final bool available;
  final Completer<void>? loadGate;
  final List<SecureKeyRecord> keys;
  final List<SecureKeyRecord> savedKeys = <SecureKeyRecord>[];
  int loadCalls = 0;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    loadCalls += 1;
    await loadGate?.future;
    return Future<SecureKeyStorageSnapshot>.value(
      SecureKeyStorageSnapshot(
        available: available,
        keys: List<SecureKeyRecord>.unmodifiable(keys),
      ),
    );
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  }) async {
    keys.removeWhere((record) => record.keyId == key.keyId);
    keys.add(key);
    savedKeys.add(key);
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
  }) async {
    keys.removeWhere((record) => record.keyId == keyId);
    return const SecureKeyStorageMutationResult(isSuccess: true);
  }
}
