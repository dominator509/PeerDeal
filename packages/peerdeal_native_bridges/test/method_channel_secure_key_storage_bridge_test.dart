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
}
