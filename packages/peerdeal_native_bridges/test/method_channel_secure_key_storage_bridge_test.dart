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

    expect(saveResult.isSuccess, isFalse);
    expect(deleteResult.isSuccess, isFalse);
    expect(log, isEmpty);
  });
}
