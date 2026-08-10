import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(CaptureProtectionChannelContract.channelName);
  final log = <MethodCall>[];

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads capture capability over the method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method ==
              CaptureProtectionChannelContract.getCapabilityMethod) {
            return {
              'blockingSupported': true,
              'obscuringSupported': true,
              'notes': 'screen-protection-supported',
              'warning': 'best-effort',
            };
          }
          return null;
        });

    final bridge = MethodChannelCaptureProtectionBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.blockingSupported, isTrue);
    expect(capability.obscuringSupported, isTrue);
    expect(capability.notes, 'screen-protection-supported');
    expect(capability.warning, 'best-effort');
    expect(log.single.method, 'getCapability');
  });

  test('applies capture blocking over the method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method ==
              CaptureProtectionChannelContract.setBlockingMethod) {
            expect(call.arguments, {'enabled': true});
            return {'success': true, 'blockingEnabled': true};
          }
          return null;
        });

    final bridge = MethodChannelCaptureProtectionBridge(channel: channel);
    final action = await bridge.setBlocking(enabled: true);

    expect(action.isSuccess, isTrue);
    expect(action.blockingEnabled, isTrue);
    expect(log.single.method, 'setBlocking');
  });

  test(
    'fails closed when capture blocking action payload is malformed',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            return <Object?>['not-a-map'];
          });

      final bridge = MethodChannelCaptureProtectionBridge(channel: channel);
      final action = await bridge.setBlocking(enabled: true);

      expect(action.isSuccess, isFalse);
      expect(action.blockingEnabled, isFalse);
      expect(action.warning, contains('decode failed'));
      expect(log.single.method, 'setBlocking');
    },
  );

  test('returns unavailable capability for missing platform payload', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return null;
        });

    final bridge = MethodChannelCaptureProtectionBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.blockingSupported, isFalse);
    expect(capability.obscuringSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, contains('unavailable'));
    expect(log.single.method, 'getCapability');
  });

  test('returns unavailable capability when platform lookup throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          throw PlatformException(
            code: 'capture_failed',
            message: 'screen API failed',
          );
        });

    final bridge = MethodChannelCaptureProtectionBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.blockingSupported, isFalse);
    expect(capability.obscuringSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, contains('capture_failed'));
    expect(capability.warning, contains('screen API failed'));
    expect(log.single.method, 'getCapability');
  });

  test(
    'returns unavailable capability for malformed platform payload',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            return <Object?>['not-a-map'];
          });

      final bridge = MethodChannelCaptureProtectionBridge(channel: channel);
      final capability = await bridge.getCapability();

      expect(capability.blockingSupported, isFalse);
      expect(capability.obscuringSupported, isFalse);
      expect(capability.notes, 'unavailable');
      expect(capability.warning, contains('decode failed'));
      expect(log.single.method, 'getCapability');
    },
  );
}
