import 'dart:async';
import 'dart:io';

import 'package:peerdeal_mobile/recovery/app_recovery_persistence_store_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  const scope = RecoveryPersistenceScope(
    tableId: 'table_1',
    sessionId: 'session_1',
    protocolVersion: '1.0.0',
  );

  test('creates durable JSON recovery store from app-provided root', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_mobile_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final factory = AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => directory,
    );
    final first = factory.create();
    final append = first.store!.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    final second = factory.create();
    final window = second.store!.loadWindow(scope);

    expect(first.isAvailable, isTrue);
    expect(first.warnings, isEmpty);
    expect(append.isSuccess, isTrue);
    expect(second.isAvailable, isTrue);
    expect(window.events.single.eventHash, 'hash_1');
  });

  test(
    'creates durable JSON recovery store from configured environment root',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'peerdeal_mobile_env_recovery_store_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final factory = AppRecoveryPersistenceStoreFactory.fromEnvironment(
        environment: <String, String>{
          peerDealRecoveryRootEnvironmentVariable: directory.path,
        },
      );
      final result = factory!.create();
      final append = result.store!.appendEvents(
        scope: scope,
        events: <EventEnvelope>[
          _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
        ],
      );

      expect(result.isAvailable, isTrue);
      expect(result.warnings, isEmpty);
      expect(append.isSuccess, isTrue);
    },
  );

  test('fails closed when environment provides padded recovery root', () {
    final factory = AppRecoveryPersistenceStoreFactory.fromEnvironment(
      environment: const <String, String>{
        peerDealRecoveryRootEnvironmentVariable: ' C:\\recovery ',
      },
    );

    final result = factory!.create();

    expect(result.isAvailable, isFalse);
    expect(result.store, isNull);
    expect(result.warnings, <String>['Recovery persistence root is invalid.']);
  });

  test(
    'returns no default factory when configured environment root is absent',
    () {
      expect(
        AppRecoveryPersistenceStoreFactory.fromEnvironment(
          environment: const <String, String>{},
        ),
        isNull,
      );
      expect(
        AppRecoveryPersistenceStoreFactory.fromEnvironment(
          environment: const <String, String>{
            peerDealRecoveryRootEnvironmentVariable: ' ',
          },
        ),
        isNull,
      );
    },
  );

  test('creates recovery storage below native app support directory', () async {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_mobile_native_support_',
    );
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final factory =
        await AppRecoveryPersistenceStoreFactory.fromNativeAppSupport(
          bridge: _FakeAppStorageDirectoryBridge(directory.path),
        );
    final result = factory!.create();
    final append = result.store!.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    expect(result.isAvailable, isTrue);
    expect(append.isSuccess, isTrue);
    expect(
      Directory(
        '${directory.path}${Platform.pathSeparator}PeerDeal${Platform.pathSeparator}recovery',
      ).existsSync(),
      isTrue,
    );
  });

  test('returns no factory when native app support is unavailable', () async {
    final factory =
        await AppRecoveryPersistenceStoreFactory.fromNativeAppSupport(
          bridge: const _UnavailableAppStorageDirectoryBridge(),
        );

    expect(factory, isNull);
  });

  test(
    'forwards cancellation to cancellable native app support lookup',
    () async {
      final cancellation = Completer<void>();
      final bridge = _CancellableAppStorageDirectoryBridge();
      final factoryFuture =
          AppRecoveryPersistenceStoreFactory.fromNativeAppSupport(
            bridge: bridge,
            cancellation: cancellation.future,
          );
      cancellation.complete();

      expect(await factoryFuture, isNull);
      expect(bridge.cancellation, same(cancellation.future));
    },
  );

  test('fails closed when app cannot provide recovery root', () {
    final factory = AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => throw StateError('root unavailable'),
    );

    final result = factory.create();

    expect(result.isAvailable, isFalse);
    expect(result.store, isNull);
    expect(result.warnings, <String>[
      'Recovery persistence root is unavailable.',
    ]);
  });

  test('fails closed when app provides invalid recovery root', () {
    final factory = AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => Directory(' '),
    );

    final result = factory.create();

    expect(result.isAvailable, isFalse);
    expect(result.store, isNull);
    expect(result.warnings, <String>['Recovery persistence root is invalid.']);
  });

  test('fails closed when app provides padded recovery root', () {
    final factory = AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => Directory(' C:\\recovery'),
    );

    final result = factory.create();

    expect(result.isAvailable, isFalse);
    expect(result.store, isNull);
    expect(result.warnings, <String>['Recovery persistence root is invalid.']);
  });

  test('fails closed when app provides control-character recovery root', () {
    final factory = AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => Directory('C:\\recovery\nsecret'),
    );

    final result = factory.create();

    expect(result.isAvailable, isFalse);
    expect(result.store, isNull);
    expect(result.warnings, <String>['Recovery persistence root is invalid.']);
  });

  test(
    'fails closed when environment provides control-character recovery root',
    () {
      final factory = AppRecoveryPersistenceStoreFactory.fromEnvironment(
        environment: const <String, String>{
          peerDealRecoveryRootEnvironmentVariable: 'C:\\recovery\nsecret',
        },
      );

      final result = factory!.create();

      expect(result.isAvailable, isFalse);
      expect(result.store, isNull);
      expect(result.warnings, <String>[
        'Recovery persistence root is invalid.',
      ]);
    },
  );
}

EventEnvelope _event({
  required int seq,
  required String prevHash,
  required String hash,
}) {
  return EventEnvelope(
    eventId: 'evt_$seq',
    eventType: 'RecoveryEventPersisted',
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: seq,
    tableId: 'table_1',
    sessionId: 'session_1',
    handId: null,
    emittedAt: '2026-06-08T00:00:00Z',
    actorRef: 'system',
    payload: const <String, Object?>{},
    prevEventHash: prevHash,
    eventHash: hash,
  );
}

class _FakeAppStorageDirectoryBridge implements AppStorageDirectoryBridge {
  const _FakeAppStorageDirectoryBridge(this.path);

  final String path;

  @override
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory() async {
    return AppStorageDirectorySnapshot(available: true, directoryPath: path);
  }
}

class _UnavailableAppStorageDirectoryBridge
    implements AppStorageDirectoryBridge {
  const _UnavailableAppStorageDirectoryBridge();

  @override
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory() async {
    return const AppStorageDirectorySnapshot.unavailable();
  }
}

class _CancellableAppStorageDirectoryBridge
    implements AppStorageDirectoryBridge, CancellableAppStorageDirectoryBridge {
  Future<void>? cancellation;

  @override
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory({
    Future<void>? cancellation,
  }) async {
    this.cancellation = cancellation;
    await cancellation;
    return const AppStorageDirectorySnapshot.unavailable();
  }
}
