import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AppStorageDirectoryChannelContract.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads an available app support directory', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return <String, Object?>{
            'available': true,
            'directoryPath': 'C:\\Users\\peerdeal\\AppData\\Local',
          };
        });

    final snapshot = await MethodChannelAppStorageDirectoryBridge(
      channel: channel,
    ).getAppSupportDirectory();

    expect(snapshot.available, isTrue);
    expect(snapshot.directoryPath, r'C:\Users\peerdeal\AppData\Local');
    expect(calls.single.method, 'getAppSupportDirectory');
  });

  test('fails closed when the platform call throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'storage_unavailable');
        });

    final snapshot = await MethodChannelAppStorageDirectoryBridge(
      channel: channel,
    ).getAppSupportDirectory();

    expect(snapshot.available, isFalse);
    expect(snapshot.directoryPath, isNull);
    expect(snapshot.warning, 'Native app storage directory lookup failed.');
  });

  test('fails closed when the platform payload is malformed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <String, Object?>{
            'available': true,
            'directoryPath': <String>['not-a-path'],
          };
        });

    final snapshot = await MethodChannelAppStorageDirectoryBridge(
      channel: channel,
    ).getAppSupportDirectory();

    expect(snapshot.available, isFalse);
    expect(snapshot.directoryPath, isNull);
  });
}
