import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeTransportChannelContract.channelName);
  final log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method ==
              NativeTransportChannelContract.getCapabilityMethod) {
            return {
              'available': true,
              'sendSupported': true,
              'receiveSupported': true,
              'maxPayloadBytes': 4096,
              'notes': 'loopback-test-transport',
            };
          }
          if (call.method == NativeTransportChannelContract.sendFrameMethod) {
            return {'success': true, 'warning': null};
          }
          if (call.method ==
              NativeTransportChannelContract.receiveFramesMethod) {
            return {
              'available': true,
              'frames': [
                {
                  'sessionId': 'session_1',
                  'senderPeerId': 'peer_a',
                  'recipientPeerId': 'peer_b',
                  'sequence': 7,
                  'payloadBytes': [1, 2, 3, 4],
                },
              ],
            };
          }
          return null;
        });
  });

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads native transport capability over the method channel', () async {
    final bridge = MethodChannelNativeTransportBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.available, isTrue);
    expect(capability.sendSupported, isTrue);
    expect(capability.receiveSupported, isTrue);
    expect(capability.maxPayloadBytes, 4096);
    expect(capability.warning, isNull);
    expect(
      log.single.method,
      NativeTransportChannelContract.getCapabilityMethod,
    );
  });

  test('sends native transport frames over the method channel', () async {
    final bridge = MethodChannelNativeTransportBridge(channel: channel);
    final result = await bridge.sendFrame(_frame());

    expect(result.isSuccess, isTrue);
    expect(result.warning, isNull);
    expect(log.single.method, NativeTransportChannelContract.sendFrameMethod);
    expect(log.single.arguments, {
      'frame': NativeTransportChannelContract.encodeFrame(_frame()),
    });
  });

  test('receives native transport frames over the method channel', () async {
    final bridge = MethodChannelNativeTransportBridge(channel: channel);
    final snapshot = await bridge.receiveFrames(
      sessionId: 'session_1',
      peerId: 'peer_b',
    );

    expect(snapshot.available, isTrue);
    expect(snapshot.frames, hasLength(1));
    expect(snapshot.frames.single.sequence, 7);
    expect(snapshot.frames.single.payloadBytes, [1, 2, 3, 4]);
    expect(
      log.single.method,
      NativeTransportChannelContract.receiveFramesMethod,
    );
  });

  test('returns unavailable capability when platform lookup throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          throw PlatformException(
            code: 'transport_failed',
            message: 'capability failed',
          );
        });

    final bridge = MethodChannelNativeTransportBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.available, isFalse);
    expect(capability.sendSupported, isFalse);
    expect(capability.receiveSupported, isFalse);
    expect(capability.warning, contains('transport_failed'));
    expect(capability.warning, contains('capability failed'));
  });

  test('fails closed when send platform call throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          throw PlatformException(
            code: 'send_failed',
            message: 'socket closed',
          );
        });

    final bridge = MethodChannelNativeTransportBridge(channel: channel);
    final result = await bridge.sendFrame(_frame());

    expect(result.isSuccess, isFalse);
    expect(result.warning, contains('send_failed'));
    expect(result.warning, contains('socket closed'));
  });

  test('fails closed when receive payload is malformed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return <Object?>['not-a-map'];
        });

    final bridge = MethodChannelNativeTransportBridge(channel: channel);
    final snapshot = await bridge.receiveFrames(
      sessionId: 'session_1',
      peerId: 'peer_b',
    );

    expect(snapshot.available, isFalse);
    expect(snapshot.frames, isEmpty);
    expect(snapshot.warning, contains('decode failed'));
  });

  test('rejects invalid requests before calling platform', () async {
    final bridge = MethodChannelNativeTransportBridge(channel: channel);

    final send = await bridge.sendFrame(
      const NativeTransportFrame(
        sessionId: 'session_1',
        senderPeerId: 'peer_a',
        recipientPeerId: 'peer_a',
        sequence: 1,
        payloadBytes: <int>[1],
      ),
    );
    final receive = await bridge.receiveFrames(sessionId: '', peerId: 'peer_b');
    final paddedSend = await bridge.sendFrame(
      const NativeTransportFrame(
        sessionId: ' session_1 ',
        senderPeerId: 'peer_a',
        recipientPeerId: 'peer_b',
        sequence: 1,
        payloadBytes: <int>[1],
      ),
    );
    final paddedReceive = await bridge.receiveFrames(
      sessionId: 'session_1',
      peerId: ' peer_b ',
    );
    final zeroSequenceSend = await bridge.sendFrame(
      const NativeTransportFrame(
        sessionId: 'session_1',
        senderPeerId: 'peer_a',
        recipientPeerId: 'peer_b',
        sequence: 0,
        payloadBytes: <int>[1],
      ),
    );
    final invalidPayloadSend = await bridge.sendFrame(
      const NativeTransportFrame(
        sessionId: 'session_1',
        senderPeerId: 'peer_a',
        recipientPeerId: 'peer_b',
        sequence: 1,
        payloadBytes: <int>[1, 256],
      ),
    );

    expect(send.isSuccess, isFalse);
    expect(receive.available, isFalse);
    expect(paddedSend.isSuccess, isFalse);
    expect(paddedReceive.available, isFalse);
    expect(zeroSequenceSend.isSuccess, isFalse);
    expect(invalidPayloadSend.isSuccess, isFalse);
    expect(log, isEmpty);
  });
}

NativeTransportFrame _frame() {
  return const NativeTransportFrame(
    sessionId: 'session_1',
    senderPeerId: 'peer_a',
    recipientPeerId: 'peer_b',
    sequence: 7,
    payloadBytes: <int>[1, 2, 3, 4],
  );
}
