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
}
