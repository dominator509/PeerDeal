import 'dart:async';

import 'package:peerdeal_mobile/session/native_local_peer_identity_loader.dart';
import 'package:peerdeal_mobile/session/native_local_peer_identity_provisioner.dart';
import 'package:peerdeal_mobile/session/native_local_peer_identity_writer.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes local identity load warnings', () {
    final warnings = <String>['warning_1'];
    final result = AppLocalPeerIdentityLoadResult(warnings: warnings);

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('copies and freezes local identity provision warnings', () {
    final warnings = <String>['warning_1'];
    final result = AppLocalPeerIdentityProvisionResult(warnings: warnings);

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('bounds and scrubs direct local identity warnings', () {
    final load = AppLocalPeerIdentityLoadResult(
      warnings: <String>[
        'warning_1',
        ' warning_2',
        'line\n${String.fromCharCode(0x85)}feed',
        'warning_4',
        'warning_5',
      ],
    );
    final provision = AppLocalPeerIdentityProvisionResult(
      warnings: <String>[
        'warning_1',
        ' warning_2',
        'line\nfeed',
        'warning_4',
        'warning_5',
      ],
    );

    expect(load.warnings, [
      'warning_1',
      'Local peer identity warning unavailable.',
      'Local peer identity warning unavailable.',
      'Local peer identity warnings truncated.',
    ]);
    expect(provision.warnings, [
      'warning_1',
      'Local peer identity provisioning warning unavailable.',
      'Local peer identity provisioning warning unavailable.',
      'Local peer identity provisioning warnings truncated.',
    ]);
  });

  test('scrubs non-round-tripping local identity warnings', () {
    final malformed = 'warning${String.fromCharCode(0xD800)}';
    final load = AppLocalPeerIdentityLoadResult(warnings: <String>[malformed]);
    final provision = AppLocalPeerIdentityProvisionResult(
      warnings: <String>[malformed],
    );

    expect(load.warnings, <String>['Local peer identity warning unavailable.']);
    expect(provision.warnings, <String>[
      'Local peer identity provisioning warning unavailable.',
    ]);
  });

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

  test(
    'announces a verified local identity through the optional network seam',
    () async {
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
      final announcer = _RecordingLocalNetworkPeerAnnouncer();
      final provisioner = NativeLocalPeerIdentityProvisioner(
        loader: NativeLocalPeerIdentityLoader(bridge: bridge),
        writer: NativeLocalPeerIdentityWriter(bridge: bridge),
        networkAnnouncer: announcer,
      );

      final result = await provisioner.ensureIdentity();

      expect(result.isSuccess, isTrue);
      expect(announcer.peerId, 'peer_existing');
      expect(announcer.port, LocalNetworkChannelContract.defaultAdvertisedPort);
      expect(announcer.calls, 1);
    },
  );

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

  test(
    'fails closed when secure identity records exceed native limits',
    () async {
      final result = await NativeLocalPeerIdentityLoader(
        bridge: _MemorySecureKeyBridge(
          keys: <SecureKeyRecord>[
            const SecureKeyRecord(
              keyId: 'local_peer_id',
              purpose: 'peer_identity',
              algorithm: 'opaque-peer-id',
              secret: 'peer_existing',
              active: true,
            ),
            for (
              var index = 0;
              index < NativeBridgePayloadLimits.maxSecureKeyRecords;
              index++
            )
              SecureKeyRecord(
                keyId: 'other_$index',
                purpose: 'other',
                algorithm: 'opaque',
                secret: 'value_$index',
                active: false,
              ),
          ],
        ),
      ).load();

      expect(result.isAvailable, isFalse);
      expect(result.identity, isNull);
      expect(result.warnings, <String>[
        'Local peer identity record limit reached.',
      ]);
    },
  );

  test(
    'fails closed on invalid identity snapshot revisions and records',
    () async {
      final invalidSnapshots = <SecureKeyStorageSnapshot>[
        SecureKeyStorageSnapshot(available: true, revision: -1, keys: const []),
        SecureKeyStorageSnapshot(
          available: true,
          keys: const <SecureKeyRecord>[
            SecureKeyRecord(
              keyId: 'unusable:key',
              purpose: 'other',
              algorithm: 'opaque',
              secret: 'value',
              active: false,
            ),
          ],
        ),
      ];

      for (final snapshot in invalidSnapshots) {
        final result = await NativeLocalPeerIdentityLoader(
          bridge: _MemorySecureKeyBridge(snapshot: snapshot),
        ).load();

        expect(result.isAvailable, isFalse);
        expect(result.identity, isNull);
        expect(result.warnings, <String>[
          snapshot.revision < 0
              ? 'Local peer identity storage revision is invalid.'
              : 'Local peer identity records are invalid.',
        ]);
      }
    },
  );

  test(
    'fails closed on duplicate secure-key ids before identity selection',
    () async {
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
        'Local peer identity storage contains duplicate key IDs.',
      ]);
    },
  );

  test('fails closed on duplicate secure-key ids across purposes', () async {
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
          purpose: 'other-purpose',
          algorithm: 'opaque',
          secret: 'other-value',
          active: false,
        ),
      ],
    );

    final result = await NativeLocalPeerIdentityLoader(bridge: bridge).load();

    expect(result.isAvailable, isFalse);
    expect(result.warnings, <String>[
      'Local peer identity storage contains duplicate key IDs.',
    ]);
  });

  test('rejects C1 and byte-oversized persisted peer identities', () async {
    for (final peerId in <String>[
      'none',
      'unresolved',
      'peer::reserved',
      'peer_${String.fromCharCode(0x85)}',
      'x' * 257,
    ]) {
      final result = await NativeLocalPeerIdentityLoader(
        bridge: _MemorySecureKeyBridge(
          keys: <SecureKeyRecord>[
            SecureKeyRecord(
              keyId: 'local_peer_id',
              purpose: 'peer_identity',
              algorithm: 'opaque-peer-id',
              secret: peerId,
              active: true,
            ),
          ],
        ),
      ).load();

      expect(result.isAvailable, isFalse);
      expect(result.warnings, <String>[
        'Persisted local peer identity is invalid.',
      ]);
    }
  });

  test('rejects C1 and byte-oversized identities before native save', () async {
    for (final peerId in <String>[
      'none',
      'unresolved',
      'peer::reserved',
      'peer_${String.fromCharCode(0x85)}',
      'x' * 257,
    ]) {
      final bridge = _MemorySecureKeyBridge();
      final result = await NativeLocalPeerIdentityWriter(
        bridge: bridge,
      ).save(AppLocalPeerIdentity(peerId: peerId));

      expect(result.isSuccess, isFalse);
      expect(result.warning, 'Local peer identity save request is invalid.');
      expect(bridge.savedKeys, isEmpty);
    }
  });

  test(
    'does not invoke a legacy identity load after pre-cancellation',
    () async {
      final cancellation = Completer<void>()..complete();
      final bridge = _MemorySecureKeyBridge();

      final result = await NativeLocalPeerIdentityLoader(
        bridge: bridge,
      ).load(cancellation: cancellation.future);

      expect(result.isAvailable, isFalse);
      expect(result.warnings, <String>['Local peer identity load cancelled.']);
      expect(bridge.loadCalls, 0);
    },
  );

  test(
    'discards a legacy identity load result when cancellation wins',
    () async {
      final cancellation = Completer<void>();
      final bridge = _CancellingLegacySecureKeyBridge(
        onLoad: cancellation,
        keys: const <SecureKeyRecord>[
          SecureKeyRecord(
            keyId: 'local_peer_id',
            purpose: 'peer_identity',
            algorithm: 'opaque-peer-id',
            secret: 'peer_late',
            active: true,
          ),
        ],
      );

      final result = await NativeLocalPeerIdentityLoader(
        bridge: bridge,
      ).load(cancellation: cancellation.future);

      expect(result.isAvailable, isFalse);
      expect(result.warnings, <String>['Local peer identity load cancelled.']);
      expect(bridge.loadCalls, 1);
    },
  );

  test(
    'does not invoke a legacy identity save after pre-cancellation',
    () async {
      final cancellation = Completer<void>()..complete();
      final bridge = _MemorySecureKeyBridge();

      final result = await NativeLocalPeerIdentityWriter(bridge: bridge).save(
        const AppLocalPeerIdentity(peerId: 'peer_cancelled'),
        cancellation: cancellation.future,
      );

      expect(result.isSuccess, isFalse);
      expect(result.warning, 'Local peer identity save cancelled.');
      expect(bridge.savedKeys, isEmpty);
    },
  );

  test(
    'discards a legacy identity save result when cancellation wins',
    () async {
      final cancellation = Completer<void>();
      final bridge = _CancellingLegacySecureKeyBridge(onSave: cancellation);

      final result = await NativeLocalPeerIdentityWriter(bridge: bridge).save(
        const AppLocalPeerIdentity(peerId: 'peer_late'),
        cancellation: cancellation.future,
      );

      expect(result.isSuccess, isFalse);
      expect(result.warning, 'Local peer identity save cancelled.');
      expect(bridge.savedKeys, hasLength(1));
    },
  );

  test(
    'rejects negative identity revisions before and after native save',
    () async {
      final invalidExpectedBridge = _MemorySecureKeyBridge();
      final invalidExpected =
          await NativeLocalPeerIdentityWriter(
            bridge: invalidExpectedBridge,
          ).save(
            const AppLocalPeerIdentity(peerId: 'peer_revision'),
            expectedRevision: -1,
          );

      expect(invalidExpected.isSuccess, isFalse);
      expect(
        invalidExpected.warning,
        'Local peer identity save request is invalid.',
      );
      expect(invalidExpectedBridge.savedKeys, isEmpty);

      final invalidResultBridge = _MemorySecureKeyBridge(
        saveResult: const SecureKeyStorageMutationResult(
          isSuccess: true,
          revision: -1,
        ),
      );
      final invalidResult = await NativeLocalPeerIdentityWriter(
        bridge: invalidResultBridge,
      ).save(const AppLocalPeerIdentity(peerId: 'peer_revision'));

      expect(invalidResult.isSuccess, isFalse);
      expect(invalidResult.warning, 'Local peer identity save failed.');
      expect(invalidResultBridge.savedKeys, hasLength(1));
    },
  );

  test('rejects a regressing conditional identity revision', () async {
    final bridge = _ConditionalMemorySecureKeyBridge(
      snapshot: SecureKeyStorageSnapshot(
        available: true,
        revision: 3,
        keys: [],
      ),
      returnedSaveRevision: 2,
    );
    final provisioner = NativeLocalPeerIdentityProvisioner(
      loader: NativeLocalPeerIdentityLoader(bridge: bridge),
      writer: NativeLocalPeerIdentityWriter(bridge: bridge),
      identityFactory: () => 'peer_regressing_revision',
    );

    final result = await provisioner.ensureIdentity();

    expect(result.isSuccess, isFalse);
    expect(result.identity, isNull);
    expect(result.warnings, <String>['Local peer identity save failed.']);
    expect(bridge.expectedSaveRevision, 3);
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

  test(
    'does not generate or save an identity after pre-cancellation',
    () async {
      final cancellation = Completer<void>()..complete();
      final bridge = _MemorySecureKeyBridge();
      var generated = 0;
      final provisioner = NativeLocalPeerIdentityProvisioner(
        loader: NativeLocalPeerIdentityLoader(bridge: bridge),
        writer: NativeLocalPeerIdentityWriter(bridge: bridge),
        identityFactory: () {
          generated++;
          return 'peer_cancelled';
        },
      );

      final result = await provisioner.ensureIdentity(
        cancellation: cancellation.future,
      );

      expect(result.isSuccess, isFalse);
      expect(result.warnings, <String>[
        'Local peer identity provisioning cancelled.',
      ]);
      expect(generated, 0);
      expect(bridge.loadCalls, 0);
      expect(bridge.savedKeys, isEmpty);
    },
  );

  test(
    'does not save an identity when generation loses to cancellation',
    () async {
      final cancellation = Completer<void>();
      final bridge = _MemorySecureKeyBridge();
      var generated = 0;
      final provisioner = NativeLocalPeerIdentityProvisioner(
        loader: NativeLocalPeerIdentityLoader(bridge: bridge),
        writer: NativeLocalPeerIdentityWriter(bridge: bridge),
        identityFactory: () {
          generated++;
          cancellation.complete();
          return 'peer_late';
        },
      );

      final result = await provisioner.ensureIdentity(
        cancellation: cancellation.future,
      );

      expect(result.isSuccess, isFalse);
      expect(result.warnings, <String>[
        'Local peer identity provisioning cancelled.',
      ]);
      expect(generated, 1);
      expect(bridge.loadCalls, 1);
      expect(bridge.savedKeys, isEmpty);
    },
  );

  test(
    'uses a conditional native mutation when a storage revision is present',
    () async {
      final bridge = _ConditionalMemorySecureKeyBridge();
      final provisioner = NativeLocalPeerIdentityProvisioner(
        loader: NativeLocalPeerIdentityLoader(bridge: bridge),
        writer: NativeLocalPeerIdentityWriter(bridge: bridge),
        identityFactory: () => 'peer_revision_aware',
      );

      final result = await provisioner.ensureIdentity();

      expect(result.isSuccess, isTrue);
      expect(result.identity?.peerId, 'peer_revision_aware');
      expect(bridge.expectedSaveRevision, 0);
      expect(bridge.revision, 1);
    },
  );

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

  test(
    'does not let a cancellable operation clear a newer tracked operation',
    () async {
      final firstLoadGate = Completer<void>();
      final secondLoadGate = Completer<void>();
      final bridge = _CancellableMemorySecureKeyBridge(
        loadGates: <Completer<void>?>[firstLoadGate, secondLoadGate, null],
      );
      final provisioner = NativeLocalPeerIdentityProvisioner(
        loader: NativeLocalPeerIdentityLoader(bridge: bridge),
        writer: NativeLocalPeerIdentityWriter(bridge: bridge),
        identityFactory: () => 'peer_mixed_cancellation',
      );
      final cancellation = Completer<void>();

      final cancellable = provisioner.ensureIdentity(
        cancellation: cancellation.future,
      );
      final tracked = provisioner.ensureIdentity();
      firstLoadGate.complete();
      final firstResult = await cancellable;
      final third = provisioner.ensureIdentity();

      expect(firstResult.isSuccess, isTrue);
      expect(bridge.loadCalls, 3);

      secondLoadGate.complete();
      final results = await Future.wait(
        <Future<AppLocalPeerIdentityProvisionResult>>[tracked, third],
      );
      expect(results.every((result) => result.isSuccess), isTrue);
      expect(bridge.loadCalls, 3);
    },
  );

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

class _RecordingLocalNetworkPeerAnnouncer implements LocalNetworkPeerAnnouncer {
  String? peerId;
  int? port;
  int calls = 0;

  @override
  Future<LocalNetworkAnnouncementResult> announcePeer({
    required String peerId,
    required int port,
  }) async {
    calls += 1;
    this.peerId = peerId;
    this.port = port;
    return const LocalNetworkAnnouncementResult(published: true);
  }
}

class _MemorySecureKeyBridge implements SecureKeyStorageMutationBridge {
  _MemorySecureKeyBridge({
    List<SecureKeyRecord> keys = const <SecureKeyRecord>[],
    SecureKeyStorageSnapshot? snapshot,
    this.available = true,
    this.loadGate,
    this.loadGates,
    this.savedPeerIdOverride,
    this.saveResult = const SecureKeyStorageMutationResult(isSuccess: true),
  }) : keys = List<SecureKeyRecord>.from(snapshot?.keys ?? keys),
       revision = snapshot?.revision ?? 0;

  final bool available;
  int revision;
  final Completer<void>? loadGate;
  final List<Completer<void>?>? loadGates;
  final String? savedPeerIdOverride;
  final SecureKeyStorageMutationResult saveResult;
  final List<SecureKeyRecord> keys;
  final List<SecureKeyRecord> savedKeys = <SecureKeyRecord>[];
  int loadCalls = 0;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    loadCalls += 1;
    final gate = loadGates != null && loadCalls <= loadGates!.length
        ? loadGates![loadCalls - 1]
        : loadGate;
    await gate?.future;
    return Future<SecureKeyStorageSnapshot>.value(
      SecureKeyStorageSnapshot(
        available: available,
        keys: List<SecureKeyRecord>.unmodifiable(keys),
        revision: revision,
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
    return saveResult;
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

class _CancellingLegacySecureKeyBridge extends _MemorySecureKeyBridge {
  _CancellingLegacySecureKeyBridge({super.keys, this.onLoad, this.onSave});

  final Completer<void>? onLoad;
  final Completer<void>? onSave;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    onLoad?.complete();
    return super.loadKeyRing(namespace: namespace);
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  }) async {
    onSave?.complete();
    return super.saveKey(namespace: namespace, key: key);
  }
}

class _CancellableMemorySecureKeyBridge extends _MemorySecureKeyBridge
    implements CancellableSecureKeyStorageMutationBridge {
  _CancellableMemorySecureKeyBridge({super.loadGates});

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

class _ConditionalMemorySecureKeyBridge extends _MemorySecureKeyBridge
    implements ConditionalSecureKeyStorageMutationBridge {
  _ConditionalMemorySecureKeyBridge({
    super.snapshot,
    this.returnedSaveRevision,
  });

  final int? returnedSaveRevision;
  int? expectedSaveRevision;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    loadCalls += 1;
    await loadGate?.future;
    return SecureKeyStorageSnapshot(
      available: available,
      keys: List<SecureKeyRecord>.unmodifiable(keys),
      revision: revision,
    );
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKeyIfRevision({
    required String namespace,
    required SecureKeyRecord key,
    required int expectedRevision,
  }) async {
    expectedSaveRevision = expectedRevision;
    if (expectedRevision != revision) {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'stale',
        isConflict: true,
      );
    }
    await super.saveKey(namespace: namespace, key: key);
    revision += 1;
    return SecureKeyStorageMutationResult(
      isSuccess: true,
      revision: returnedSaveRevision ?? revision,
    );
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKeyIfRevision({
    required String namespace,
    required String keyId,
    required int expectedRevision,
  }) async {
    if (expectedRevision != revision) {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'stale',
        isConflict: true,
      );
    }
    await super.deleteKey(namespace: namespace, keyId: keyId);
    revision += 1;
    return SecureKeyStorageMutationResult(isSuccess: true, revision: revision);
  }
}
