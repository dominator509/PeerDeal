import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(SecureKeyStorageChannelContract.channelName);
  final log = <MethodCall>[];

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    log.clear();
  });

  test('loads secure key ring over the method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method ==
              SecureKeyStorageChannelContract.loadKeyRingMethod) {
            return <String, Object?>{
              'available': true,
              'keys': <Map<String, Object?>>[
                <String, Object?>{
                  'keyId': 'receipt_signing_1',
                  'purpose': 'receipt_signing',
                  'algorithm': 'hmac-sha256',
                  'secret': 'signing_secret_1',
                  'active': true,
                },
              ],
            };
          }
          return null;
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final snapshot = await bridge.loadKeyRing(namespace: 'peerdeal.receipts');

    expect(snapshot.available, isTrue);
    expect(snapshot.keys.single.keyId, 'receipt_signing_1');
    expect(log.single.method, 'loadKeyRing');
    expect(log.single.arguments, {'namespace': 'peerdeal.receipts'});
  });

  test('loads a secure key ring revision when the host provides one', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <String, Object?>{
            'available': true,
            'revision': 7,
            'keys': <Object?>[],
          };
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final snapshot = await bridge.loadKeyRing(namespace: 'peerdeal.receipts');

    expect(snapshot.available, isTrue);
    expect(snapshot.revision, 7);
  });

  test('returns unavailable snapshot when platform lookup throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(
            code: 'locked',
            message: 'secure storage locked',
          );
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final snapshot = await bridge.loadKeyRing(namespace: 'peerdeal.receipts');

    expect(snapshot.available, isFalse);
    expect(snapshot.keys, isEmpty);
    expect(snapshot.warning, contains('locked'));
  });

  test('returns unavailable snapshot when platform lookup times out', () async {
    final pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => pending.future);

    final bridge = MethodChannelSecureKeyStorageBridge(
      channel: channel,
      timeout: const Duration(milliseconds: 1),
    );
    final snapshot = await bridge.loadKeyRing(namespace: 'peerdeal.receipts');

    expect(snapshot.available, isFalse);
    expect(snapshot.keys, isEmpty);
    expect(snapshot.warning, 'Secure key storage call timed out.');
  });

  test('cancels an in-flight secure key load before the deadline', () async {
    final pending = Completer<Object?>();
    final cancellation = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => pending.future);

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final request = bridge.loadKeyRing(
      namespace: 'peerdeal.receipts',
      cancellation: cancellation.future,
    );
    await Future<void>.delayed(Duration.zero);
    cancellation.complete();
    final snapshot = await request;

    expect(snapshot.available, isFalse);
    expect(snapshot.warning, 'Secure key storage call cancelled.');
  });

  test('returns unavailable snapshot for malformed platform payload', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return <Object?>['not-a-map'];
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final snapshot = await bridge.loadKeyRing(namespace: 'peerdeal.receipts');

    expect(snapshot.available, isFalse);
    expect(snapshot.keys, isEmpty);
    expect(snapshot.warning, contains('decode failed'));
    expect(log.single.method, 'loadKeyRing');
  });

  test('rejects invalid load requests before calling platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return <String, Object?>{'available': true, 'keys': <Object?>[]};
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final snapshot = await bridge.loadKeyRing(namespace: ' peerdeal.receipts ');

    expect(snapshot.available, isFalse);
    expect(snapshot.keys, isEmpty);
    expect(snapshot.warning, 'Secure key storage load request is invalid.');
    expect(log, isEmpty);
  });

  test('rejects oversized UTF-8 namespaces before calling platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return <String, Object?>{'available': true, 'keys': <Object?>[]};
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final snapshot = await bridge.loadKeyRing(
      namespace: String.fromCharCodes(List<int>.filled(33, 0x1F600)),
    );

    expect(snapshot.available, isFalse);
    expect(snapshot.keys, isEmpty);
    expect(snapshot.warning, 'Secure key storage load request is invalid.');
    expect(log, isEmpty);
  });

  test('rejects oversized UTF-8 delete key IDs before calling platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return <String, Object?>{'success': true};
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final result = await bridge.deleteKey(
      namespace: 'peerdeal.receipts',
      keyId: String.fromCharCodes(List<int>.filled(65, 0x1F600)),
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Secure key storage delete request is invalid.');
    expect(log, isEmpty);
  });

  test('saves secure key records over the method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method == SecureKeyStorageChannelContract.saveKeyMethod) {
            return <String, Object?>{'success': true};
          }
          return null;
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final result = await bridge.saveKey(
      namespace: 'peerdeal.receipts',
      key: const SecureKeyRecord(
        keyId: 'receipt_signing_1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(log.single.method, 'saveKey');
    expect(log.single.arguments, {
      'namespace': 'peerdeal.receipts',
      'key': {
        'keyId': 'receipt_signing_1',
        'purpose': 'receipt_signing',
        'algorithm': 'hmac-sha256',
        'secret': 'signing_secret_1',
        'active': true,
      },
    });
  });

  test('deletes secure key records over the method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method == SecureKeyStorageChannelContract.deleteKeyMethod) {
            return <String, Object?>{'success': true};
          }
          return null;
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final result = await bridge.deleteKey(
      namespace: 'peerdeal.receipts',
      keyId: 'receipt_signing_1',
    );

    expect(result.isSuccess, isTrue);
    expect(log.single.method, 'deleteKey');
    expect(log.single.arguments, {
      'namespace': 'peerdeal.receipts',
      'keyId': 'receipt_signing_1',
    });
  });

  test('conditionally saves against a revision and decodes the new revision',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method ==
              SecureKeyStorageChannelContract.saveKeyIfRevisionMethod) {
            return <String, Object?>{'success': true, 'revision': 8};
          }
          return null;
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final result = await bridge.saveKeyIfRevision(
      namespace: 'peerdeal.receipts',
      expectedRevision: 7,
      key: const SecureKeyRecord(
        keyId: 'receipt_signing_1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.revision, 8);
    expect(log.single.method, 'saveKeyIfRevision');
    expect(log.single.arguments, {
      'namespace': 'peerdeal.receipts',
      'expectedRevision': 7,
      'key': {
        'keyId': 'receipt_signing_1',
        'purpose': 'receipt_signing',
        'algorithm': 'hmac-sha256',
        'secret': 'signing_secret_1',
        'active': true,
      },
    });
  });

  test('rejects an oversized expected revision before invoking the host',
      () async {
    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final result = await bridge.saveKeyIfRevision(
      namespace: 'peerdeal.receipts',
      expectedRevision: NativeBridgePayloadLimits.maxSecureKeyRevision + 1,
      key: const SecureKeyRecord(
        keyId: 'receipt_signing_1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Secure key storage revision is invalid.');
    expect(log, isEmpty);
  });

  test('surfaces a conditional mutation conflict', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <String, Object?>{
            'success': false,
            'conflict': true,
            'revision': 8,
            'warning': 'stale',
          };
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final result = await bridge.deleteKeyIfRevision(
      namespace: 'peerdeal.receipts',
      keyId: 'receipt_signing_1',
      expectedRevision: 7,
    );

    expect(result.isSuccess, isFalse);
    expect(result.isConflict, isTrue);
    expect(result.revision, 8);
    expect(result.warning, 'stale');
  });

  test('fails closed when save platform call throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'locked', message: 'storage locked');
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final result = await bridge.saveKey(
      namespace: 'peerdeal.receipts',
      key: const SecureKeyRecord(
        keyId: 'receipt_signing_1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, contains('locked'));
  });

  test('fails closed when save platform call times out', () async {
    final pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => pending.future);

    final bridge = MethodChannelSecureKeyStorageBridge(
      channel: channel,
      timeout: const Duration(milliseconds: 1),
    );
    final result = await bridge.saveKey(
      namespace: 'peerdeal.receipts',
      key: const SecureKeyRecord(
        keyId: 'receipt_signing_1',
        purpose: 'receipt-signing',
        algorithm: 'HMAC-SHA256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Secure key storage call timed out.');
  });

  test('cancels in-flight secure key mutations before the deadline', () async {
    final cancellation = Completer<void>();
    final pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => pending.future);

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final save = bridge.saveKey(
      namespace: 'peerdeal.receipts',
      key: const SecureKeyRecord(
        keyId: 'receipt_signing_1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
      cancellation: cancellation.future,
    );
    final delete = bridge.deleteKey(
      namespace: 'peerdeal.receipts',
      keyId: 'receipt_signing_1',
      cancellation: cancellation.future,
    );
    await Future<void>.delayed(Duration.zero);
    cancellation.complete();

    final results = await Future.wait(<Future<SecureKeyStorageMutationResult>>[
      save,
      delete,
    ]);

    expect(results.map((result) => result.warning), [
      'Secure key storage call cancelled.',
      'Secure key storage call cancelled.',
    ]);
  });

  test(
    'fails closed when delete platform call returns malformed payload',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            return <Object?>['not-a-map'];
          });

      final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
      final result = await bridge.deleteKey(
        namespace: 'peerdeal.receipts',
        keyId: 'receipt_signing_1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.warning, contains('decode failed'));
      expect(log.single.method, 'deleteKey');
    },
  );

  test('rejects invalid mutation requests before calling platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return <String, Object?>{'success': true};
        });

    final bridge = MethodChannelSecureKeyStorageBridge(channel: channel);
    final saveResult = await bridge.saveKey(
      namespace: 'peerdeal.receipts',
      key: const SecureKeyRecord(
        keyId: 'receipt:signing:1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );
    final deleteResult = await bridge.deleteKey(
      namespace: '',
      keyId: 'receipt_signing_1',
    );
    final paddedSaveResult = await bridge.saveKey(
      namespace: 'peerdeal.receipts',
      key: const SecureKeyRecord(
        keyId: ' receipt_signing_1 ',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );
    final paddedDeleteResult = await bridge.deleteKey(
      namespace: 'peerdeal.receipts',
      keyId: ' receipt_signing_1 ',
    );
    final controlSaveResult = await bridge.saveKey(
      namespace: 'peerdeal.receipts',
      key: const SecureKeyRecord(
        keyId: 'receipt\n_signing_1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );
    final controlDeleteResult = await bridge.deleteKey(
      namespace: 'peerdeal.receipts',
      keyId: 'receipt\u0001_signing_1',
    );

    expect(saveResult.isSuccess, isFalse);
    expect(deleteResult.isSuccess, isFalse);
    expect(paddedSaveResult.isSuccess, isFalse);
    expect(paddedDeleteResult.isSuccess, isFalse);
    expect(controlSaveResult.isSuccess, isFalse);
    expect(controlDeleteResult.isSuccess, isFalse);
    expect(log, isEmpty);
  });
}
