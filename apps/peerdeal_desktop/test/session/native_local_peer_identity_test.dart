import 'dart:async';

import 'package:peerdeal_desktop/session/native_local_peer_identity_loader.dart';
import 'package:peerdeal_desktop/session/native_local_peer_identity_provisioner.dart';
import 'package:peerdeal_desktop/session/native_local_peer_identity_writer.dart';
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
    expect(bridge.loadCalls, 3);
    expect(bridge.savedKeys, hasLength(1));
  });

  test('fails closed when native storage changes the saved identity', () async {
    final bridge = _MemorySecureKeyBridge(
      savedPeerIdOverride: 'peer_competing_writer',
    );
    final provisioner = NativeLocalPeerIdentityProvisioner(
      loader: NativeLocalPeerIdentityLoader(bridge: bridge),
      writer: NativeLocalPeerIdentityWriter(bridge: bridge),
      identityFactory: () => 'peer_generated',
    );

    final result = await provisioner.ensureIdentity();

    expect(result.isSuccess, isFalse);
    expect(result.identity, isNull);
    expect(result.warnings, <String>[
      'Local peer identity persistence could not be verified.',
    ]);
    expect(bridge.loadCalls, 2);
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
    expect(bridge.loadCalls, 2);
    expect(bridge.savedKeys, hasLength(1));
  });

  test('propagates caller cancellation through the identity bridge', () async {
    final bridge = _CancellableMemorySecureKeyBridge();
    final cancellation = Completer<void>();
    final provisioner = NativeLocalPeerIdentityProvisioner(
      loader: NativeLocalPeerIdentityLoader(bridge: bridge),
      writer: NativeLocalPeerIdentityWriter(bridge: bridge),
      identityFactory: () => 'peer_cancel_aware',
    );

    final result = await provisioner.ensureIdentity(
      cancellation: cancellation.future,
    );

    expect(result.isSuccess, isTrue);
    expect(bridge.loadCancellation, same(cancellation.future));
    expect(bridge.saveCancellation, same(cancellation.future));
  });
}

class _MemorySecureKeyBridge implements SecureKeyStorageMutationBridge {
  _MemorySecureKeyBridge({
    List<SecureKeyRecord> keys = const <SecureKeyRecord>[],
    this.available = true,
    this.loadGate,
    this.savedPeerIdOverride,
  }) : keys = List<SecureKeyRecord>.from(keys);

  final bool available;
  final Completer<void>? loadGate;
  final String? savedPeerIdOverride;
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
    keys.add(
      SecureKeyRecord(
        keyId: key.keyId,
        purpose: key.purpose,
        algorithm: key.algorithm,
        secret: savedPeerIdOverride ?? key.secret,
        active: key.active,
      ),
    );
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

class _CancellableMemorySecureKeyBridge extends _MemorySecureKeyBridge
    implements CancellableSecureKeyStorageMutationBridge {
  Future<void>? loadCancellation;
  Future<void>? saveCancellation;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
    Future<void>? cancellation,
  }) {
    loadCancellation = cancellation;
    return super.loadKeyRing(namespace: namespace);
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
    Future<void>? cancellation,
  }) {
    saveCancellation = cancellation;
    return super.saveKey(namespace: namespace, key: key);
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
    Future<void>? cancellation,
  }) {
    return super.deleteKey(namespace: namespace, keyId: keyId);
  }
}
