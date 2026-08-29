import 'dart:async';

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

  test('rejects a non-positive method-channel timeout', () {
    expect(
      () => MethodChannelAppStorageDirectoryBridge(
        channel: channel,
        timeout: Duration.zero,
      ),
      throwsArgumentError,
    );
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

  test('fails closed when the platform call times out', () async {
    final pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => pending.future);

    final snapshot = await MethodChannelAppStorageDirectoryBridge(
      channel: channel,
      timeout: const Duration(milliseconds: 1),
    ).getAppSupportDirectory();

    expect(snapshot.available, isFalse);
    expect(snapshot.warning, 'Native app storage directory lookup timed out.');
    pending.complete(null);
  });

  test('cancels an in-flight platform lookup', () async {
    final pending = Completer<Object?>();
    final cancellation = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => pending.future);

    final lookup = MethodChannelAppStorageDirectoryBridge(
      channel: channel,
    ).getAppSupportDirectory(cancellation: cancellation.future);
    cancellation.complete();

    final snapshot = await lookup;

    expect(snapshot.available, isFalse);
    expect(snapshot.warning, 'Native app storage directory lookup cancelled.');
    pending.complete(null);
  });

  test(
    'cancellation wins over an immediately completing platform lookup',
    () async {
      var invocationCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            invocationCount++;
            return <String, Object?>{
              'available': true,
              'directoryPath': r'C:\Users\peerdeal\AppData\Local',
            };
          });

      final snapshot = await MethodChannelAppStorageDirectoryBridge(
        channel: channel,
      ).getAppSupportDirectory(cancellation: Future<void>.value());

      expect(snapshot.available, isFalse);
      expect(
        snapshot.warning,
        'Native app storage directory lookup cancelled.',
      );
      expect(invocationCount, 0);
    },
  );
}
