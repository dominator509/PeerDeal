import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('peerdeal/native_bridges/local_network');
  final log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      if (call.method == 'getCapability') {
        return {
          'discoverySupported': true,
          'permissionPromptSupported': true,
          'broadcastSupported': true,
          'notes': 'starter-capability',
        };
      }
      if (call.method == 'discoverPeers') {
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

  tearDown(() async {
    log.clear();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads capability over the method channel', () async {
    final bridge = MethodChannelLocalNetworkBridge(channel: channel);
    final capability = await bridge.getCapability();

    expect(capability.discoverySupported, isTrue);
    expect(log.single.method, 'getCapability');
  });
}
