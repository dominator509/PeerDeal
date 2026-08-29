import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(LocalNetworkChannelContract.channelName);
  final log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          if (call.method == LocalNetworkChannelContract.getCapabilityMethod) {
            return {
              'discoverySupported': true,
              'permissionPromptSupported': true,
              'broadcastSupported': true,
              'notes': 'starter-capability',
            };
          }
          if (call.method == LocalNetworkChannelContract.discoverPeersMethod) {
            return {
              'permissionGranted': true,
              'foundEndpoints': ['peer_a@192.168.1.10'],
              'interfaceHints': ['wifi'],
              'warning': null,
            };
          }
          if (call.method == LocalNetworkChannelContract.announcePeerMethod) {
            return {'published': true, 'warning': null};
          }
          return null;
        });
  });

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads capability over the method channel', () async {
    final bridge = MethodChannelLocalNetworkBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.discoverySupported, isTrue);
    expect(capability.warning, isNull);
    expect(log.single.method, 'getCapability');
  });

  test('reads discovery snapshot over the method channel', () async {
    final bridge = MethodChannelLocalNetworkBridge(channel: channel);
    final snapshot = await bridge.discoverPeers();

    expect(snapshot.permissionGranted, isTrue);
    expect(snapshot.foundEndpoints, ['peer_a@192.168.1.10']);
    expect(snapshot.interfaceHints, ['wifi']);
    expect(snapshot.warning, isNull);
    expect(log.single.method, 'discoverPeers');
  });

  test('announces a peer over the method channel', () async {
    final bridge = MethodChannelLocalNetworkBridge(channel: channel);
    final announcement = await bridge.announcePeer(
      peerId: 'peer_a',
      port: 40442,
    );

    expect(announcement.published, isTrue);
    expect(announcement.warning, isNull);
    expect(log.single.method, 'announcePeer');
    expect(log.single.arguments, {'peerId': 'peer_a', 'port': 40442});
  });

  test('rejects invalid peer announcements before native dispatch', () async {
    final bridge = MethodChannelLocalNetworkBridge(channel: channel);
    final announcement = await bridge.announcePeer(peerId: 'none', port: 40442);

    expect(announcement.published, isFalse);
    expect(
      announcement.warning,
      'Local network announcement request is invalid.',
    );
    expect(log, isEmpty);
  });

  test('returns unavailable capability when platform lookup throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          throw PlatformException(
            code: 'local_network_failed',
            message: 'permission API failed',
          );
        });

    final bridge = MethodChannelLocalNetworkBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.discoverySupported, isFalse);
    expect(capability.permissionPromptSupported, isFalse);
    expect(capability.broadcastSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, contains('local_network_failed'));
    expect(capability.warning, contains('permission API failed'));
    expect(log.single.method, 'getCapability');
  });

  test(
    'returns unavailable discovery snapshot when platform lookup throws',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            throw PlatformException(
              code: 'discovery_failed',
              message: 'discovery API failed',
            );
          });

      final bridge = MethodChannelLocalNetworkBridge(channel: channel);
      final snapshot = await bridge.discoverPeers();

      expect(snapshot.permissionGranted, isFalse);
      expect(snapshot.foundEndpoints, isEmpty);
      expect(snapshot.interfaceHints, isEmpty);
      expect(snapshot.warning, contains('discovery_failed'));
      expect(snapshot.warning, contains('discovery API failed'));
      expect(log.single.method, 'discoverPeers');
    },
  );

  test(
    'returns unavailable capability for malformed platform payload',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            return <Object?>['not-a-map'];
          });

      final bridge = MethodChannelLocalNetworkBridge(channel: channel);
      final capability = await bridge.getCapability();

      expect(capability.discoverySupported, isFalse);
      expect(capability.permissionPromptSupported, isFalse);
      expect(capability.broadcastSupported, isFalse);
      expect(capability.notes, 'unavailable');
      expect(capability.warning, contains('decode failed'));
      expect(log.single.method, 'getCapability');
    },
  );

  test(
    'returns unavailable discovery for malformed platform payload',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            return <Object?>['not-a-map'];
          });

      final bridge = MethodChannelLocalNetworkBridge(channel: channel);
      final snapshot = await bridge.discoverPeers();

      expect(snapshot.permissionGranted, isFalse);
      expect(snapshot.foundEndpoints, isEmpty);
      expect(snapshot.interfaceHints, isEmpty);
      expect(snapshot.warning, contains('decode failed'));
      expect(log.single.method, 'discoverPeers');
    },
  );

  test('bounds a pending capability lookup', () async {
    final pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return pending.future;
        });

    final capability = await MethodChannelLocalNetworkBridge(
      channel: channel,
      timeout: const Duration(milliseconds: 1),
    ).getCapability();

    expect(capability.warning, 'Local network call timed out.');
    expect(log.single.method, 'getCapability');
    pending.complete(null);
  });

  test('bounds a pending discovery lookup', () async {
    final pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return pending.future;
        });

    final snapshot = await MethodChannelLocalNetworkBridge(
      channel: channel,
      timeout: const Duration(milliseconds: 1),
    ).discoverPeers();

    expect(snapshot.warning, 'Local network call timed out.');
    expect(log.single.method, 'discoverPeers');
    pending.complete(null);
  });

  test('cancels an in-flight capability lookup', () async {
    final pending = Completer<Object?>();
    final cancellation = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return pending.future;
        });

    final lookup = MethodChannelLocalNetworkBridge(
      channel: channel,
      cancellation: cancellation.future,
    ).getCapability();
    cancellation.complete();

    final capability = await lookup;

    expect(capability.warning, 'Local network call cancelled.');
    expect(log.single.method, 'getCapability');
    pending.complete(null);
  });

  test(
    'cancels an in-flight capability lookup through per-call signal',
    () async {
      final pending = Completer<Object?>();
      final cancellation = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            return pending.future;
          });

      final lookup = MethodChannelLocalNetworkBridge(
        channel: channel,
      ).getCapability(cancellation: cancellation.future);
      cancellation.complete();

      final capability = await lookup;

      expect(capability.warning, 'Local network call cancelled.');
      expect(log.single.method, 'getCapability');
      pending.complete(null);
    },
  );

  test(
    'cancellation wins over an immediately completing capability lookup',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            log.add(call);
            return <String, Object?>{
              'discoverySupported': true,
              'permissionPromptSupported': true,
              'broadcastSupported': true,
              'notes': 'should-not-be-read',
            };
          });
      final capability = await MethodChannelLocalNetworkBridge(
        channel: channel,
      ).getCapability(cancellation: Future<void>.value());

      expect(capability.discoverySupported, isFalse);
      expect(capability.warning, 'Local network call cancelled.');
      expect(log, isEmpty);
    },
  );

  test('rejects a non-positive call timeout', () {
    expect(
      () => MethodChannelLocalNetworkBridge(
        channel: channel,
        timeout: Duration.zero,
      ),
      throwsArgumentError,
    );
  });
}
