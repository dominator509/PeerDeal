import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/main.dart' as app_entrypoint;
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

void main() {
  testWidgets('production entrypoint activates native readiness', (
    tester,
  ) async {
    final channels = <MethodChannel>[
      const MethodChannel(AppStorageDirectoryChannelContract.channelName),
      const MethodChannel(CaptureProtectionChannelContract.channelName),
      const MethodChannel(LocalNetworkChannelContract.channelName),
      const MethodChannel(NativeTransportChannelContract.channelName),
      const MethodChannel(SecureKeyStorageChannelContract.channelName),
    ];
    final binaryMessenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in channels) {
      binaryMessenger.setMockMethodCallHandler(channel, (_) async => null);
    }
    addTearDown(() {
      for (final channel in channels) {
        binaryMessenger.setMockMethodCallHandler(channel, null);
      }
    });

    await app_entrypoint.main();
    await tester.pumpAndSettle();

    expect(find.byType(app_entrypoint.PeerDealMobileApp), findsOneWidget);
    expect(find.text('Native unavailable'), findsOneWidget);
  });
}
