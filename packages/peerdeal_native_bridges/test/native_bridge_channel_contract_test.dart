import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('capture protection channel contract decodes fixture payload', () {
    final fixture = _loadFixture('capture_protection_bridge_contract.json');
    final methods = fixture['methods'] as Map<String, Object?>;
    final payload =
        methods[CaptureProtectionChannelContract.getCapabilityMethod]
            as Map<String, Object?>;

    expect(fixture['channel'], CaptureProtectionChannelContract.channelName);

    final capability = CaptureProtectionChannelContract.decodeCapability(
      payload,
    );

    expect(capability.blockingSupported, isTrue);
    expect(capability.obscuringSupported, isTrue);
    expect(capability.notes, 'screen-protection-supported');
    expect(capability.warning, 'best-effort');
  });

  test('capture protection channel contract fails closed on null payload', () {
    final capability = CaptureProtectionChannelContract.decodeCapability(null);

    expect(capability.blockingSupported, isFalse);
    expect(capability.obscuringSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, contains('unavailable'));
  });

  test('capture protection channel contract tolerates malformed fields', () {
    final capability = CaptureProtectionChannelContract.decodeCapability(
      const <String, Object?>{
        'blockingSupported': 'true',
        'obscuringSupported': 1,
        'notes': false,
        'warning': <String>['bad'],
      },
    );

    expect(capability.blockingSupported, isFalse);
    expect(capability.obscuringSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, isNull);
  });

  test('local network channel contract decodes fixture payloads', () {
    final fixture = _loadFixture('local_network_bridge_requests.json');
    final methods = fixture['methods'] as Map<String, Object?>;
    final capabilityPayload =
        methods[LocalNetworkChannelContract.getCapabilityMethod]
            as Map<String, Object?>;
    final discoveryPayload =
        methods[LocalNetworkChannelContract.discoverPeersMethod]
            as Map<String, Object?>;

    expect(fixture['channel'], LocalNetworkChannelContract.channelName);

    final capability = LocalNetworkChannelContract.decodeCapability(
      capabilityPayload,
    );
    final snapshot = LocalNetworkChannelContract.decodeDiscoverySnapshot(
      discoveryPayload,
    );

    expect(capability.discoverySupported, isTrue);
    expect(capability.permissionPromptSupported, isTrue);
    expect(capability.broadcastSupported, isTrue);
    expect(capability.notes, 'starter-capability');
    expect(capability.warning, isNull);

    expect(snapshot.permissionGranted, isTrue);
    expect(snapshot.foundEndpoints, ['peer_a@192.168.1.10']);
    expect(snapshot.interfaceHints, ['wifi']);
    expect(snapshot.warning, isNull);
  });

  test('local network channel contract fails closed on null payloads', () {
    final capability = LocalNetworkChannelContract.decodeCapability(null);
    final snapshot = LocalNetworkChannelContract.decodeDiscoverySnapshot(null);

    expect(capability.discoverySupported, isFalse);
    expect(capability.permissionPromptSupported, isFalse);
    expect(capability.broadcastSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, contains('unavailable'));

    expect(snapshot.permissionGranted, isFalse);
    expect(snapshot.foundEndpoints, isEmpty);
    expect(snapshot.interfaceHints, isEmpty);
    expect(snapshot.warning, contains('unavailable'));
  });

  test('local network channel contract tolerates malformed fields', () {
    final capability = LocalNetworkChannelContract.decodeCapability(
      const <String, Object?>{
        'discoverySupported': 'true',
        'permissionPromptSupported': 1,
        'broadcastSupported': 'false',
        'notes': false,
        'warning': <String>['bad'],
      },
    );
    final snapshot = LocalNetworkChannelContract.decodeDiscoverySnapshot(
      const <String, Object?>{
        'permissionGranted': 'true',
        'foundEndpoints': 'peer_a',
        'interfaceHints': false,
        'warning': <String>['bad'],
      },
    );

    expect(capability.discoverySupported, isFalse);
    expect(capability.permissionPromptSupported, isFalse);
    expect(capability.broadcastSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, isNull);

    expect(snapshot.permissionGranted, isFalse);
    expect(snapshot.foundEndpoints, isEmpty);
    expect(snapshot.interfaceHints, isEmpty);
    expect(snapshot.warning, isNull);
  });

  test('secure key storage channel contract decodes fixture payload', () {
    final fixture = _loadFixture('secure_key_storage_bridge_contract.json');
    final methods = fixture['methods'] as Map<String, Object?>;
    final payload =
        methods[SecureKeyStorageChannelContract.loadKeyRingMethod]
            as Map<String, Object?>;
    final savePayload =
        methods[SecureKeyStorageChannelContract.saveKeyMethod]
            as Map<String, Object?>;
    final deletePayload =
        methods[SecureKeyStorageChannelContract.deleteKeyMethod]
            as Map<String, Object?>;

    expect(fixture['channel'], SecureKeyStorageChannelContract.channelName);

    final snapshot = SecureKeyStorageChannelContract.decodeSnapshot(payload);
    final saveResult = SecureKeyStorageChannelContract.decodeMutationResult(
      savePayload,
    );
    final deleteResult = SecureKeyStorageChannelContract.decodeMutationResult(
      deletePayload,
    );

    expect(snapshot.available, isTrue);
    expect(snapshot.keys.map((key) => key.keyId), [
      'receipt_signing_1',
      'receipt_encryption_1',
    ]);
    expect(snapshot.keys.first.active, isTrue);
    expect(snapshot.warning, isNull);
    expect(saveResult.isSuccess, isTrue);
    expect(deleteResult.isSuccess, isTrue);
  });

  test('secure key storage channel contract fails closed on null payload', () {
    final snapshot = SecureKeyStorageChannelContract.decodeSnapshot(null);

    expect(snapshot.available, isFalse);
    expect(snapshot.keys, isEmpty);
    expect(snapshot.warning, contains('unavailable'));
  });

  test('secure key storage channel contract tolerates malformed fields', () {
    final snapshot = SecureKeyStorageChannelContract.decodeSnapshot(
      const <String, Object?>{
        'available': true,
        'warning': <String>['bad'],
        'keys': <Object?>[
          <String, Object?>{
            'keyId': 'receipt_signing_1',
            'purpose': 'receipt_signing',
            'algorithm': 'hmac-sha256',
            'secret': 'signing_secret_1',
            'active': 'true',
          },
          <String, Object?>{
            'keyId': 2,
            'purpose': 'receipt_signing',
            'algorithm': 'hmac-sha256',
            'secret': 'signing_secret_2',
            'active': true,
          },
        ],
      },
    );

    expect(snapshot.available, isTrue);
    expect(snapshot.warning, isNull);
    expect(snapshot.keys, hasLength(1));
    expect(snapshot.keys.single.keyId, 'receipt_signing_1');
    expect(snapshot.keys.single.active, isFalse);
  });

  test('secure key storage channel contract encodes key records', () {
    final payload = SecureKeyStorageChannelContract.encodeKey(
      const SecureKeyRecord(
        keyId: 'receipt_signing_1',
        purpose: 'receipt_signing',
        algorithm: 'hmac-sha256',
        secret: 'signing_secret_1',
        active: true,
      ),
    );

    expect(payload, {
      'keyId': 'receipt_signing_1',
      'purpose': 'receipt_signing',
      'algorithm': 'hmac-sha256',
      'secret': 'signing_secret_1',
      'active': true,
    });
  });

  test('secure key storage mutation result fails closed on null payload', () {
    final result = SecureKeyStorageChannelContract.decodeMutationResult(null);

    expect(result.isSuccess, isFalse);
    expect(result.warning, contains('unavailable'));
  });

  test('secure key storage mutation result tolerates malformed fields', () {
    final result = SecureKeyStorageChannelContract.decodeMutationResult(
      const <String, Object?>{
        'success': 'true',
        'warning': <String>['bad'],
      },
    );

    expect(result.isSuccess, isFalse);
    expect(result.warning, 'Secure key storage mutation failed.');
  });

  test('native transport channel contract decodes fixture payloads', () {
    final fixture = _loadFixture('native_transport_bridge_contract.json');
    final methods = fixture['methods'] as Map<String, Object?>;
    final capabilityPayload =
        methods[NativeTransportChannelContract.getCapabilityMethod]
            as Map<String, Object?>;
    final sendPayload =
        methods[NativeTransportChannelContract.sendFrameMethod]
            as Map<String, Object?>;
    final receivePayload =
        methods[NativeTransportChannelContract.receiveFramesMethod]
            as Map<String, Object?>;

    expect(fixture['channel'], NativeTransportChannelContract.channelName);

    final capability = NativeTransportChannelContract.decodeCapability(
      capabilityPayload,
    );
    final sendResult = NativeTransportChannelContract.decodeSendResult(
      sendPayload,
    );
    final snapshot = NativeTransportChannelContract.decodeReceiveSnapshot(
      receivePayload,
    );

    expect(capability.available, isTrue);
    expect(capability.sendSupported, isTrue);
    expect(capability.receiveSupported, isTrue);
    expect(capability.maxPayloadBytes, 4096);
    expect(capability.notes, 'loopback-test-transport');
    expect(capability.warning, isNull);
    expect(sendResult.isSuccess, isTrue);
    expect(snapshot.available, isTrue);
    expect(snapshot.frames.single.sessionId, 'session_1');
    expect(snapshot.frames.single.payloadBytes, [1, 2, 3, 4]);
  });

  test('native transport channel contract fails closed on null payloads', () {
    final capability = NativeTransportChannelContract.decodeCapability(null);
    final sendResult = NativeTransportChannelContract.decodeSendResult(null);
    final snapshot = NativeTransportChannelContract.decodeReceiveSnapshot(null);

    expect(capability.available, isFalse);
    expect(capability.sendSupported, isFalse);
    expect(capability.receiveSupported, isFalse);
    expect(capability.warning, contains('unavailable'));
    expect(sendResult.isSuccess, isFalse);
    expect(sendResult.warning, contains('unavailable'));
    expect(snapshot.available, isFalse);
    expect(snapshot.frames, isEmpty);
    expect(snapshot.warning, contains('unavailable'));
  });

  test('native transport channel contract tolerates malformed fields', () {
    final capability = NativeTransportChannelContract.decodeCapability(
      const <String, Object?>{
        'available': 'true',
        'sendSupported': 1,
        'receiveSupported': 'false',
        'maxPayloadBytes': -1,
        'notes': false,
        'warning': <String>['bad'],
      },
    );
    final sendResult = NativeTransportChannelContract.decodeSendResult(
      const <String, Object?>{
        'success': 'true',
        'warning': <String>['bad'],
      },
    );
    final snapshot = NativeTransportChannelContract.decodeReceiveSnapshot(
      const <String, Object?>{
        'available': true,
        'frames': <Object?>[
          <String, Object?>{
            'sessionId': 'session_1',
            'senderPeerId': 'peer_a',
            'recipientPeerId': 'peer_a',
            'sequence': 1,
            'payloadBytes': <int>[1],
          },
          <String, Object?>{
            'sessionId': 'session_1',
            'senderPeerId': 'peer_a',
            'recipientPeerId': 'peer_b',
            'sequence': 2,
            'payloadBytes': <Object?>[1, 'bad', 300],
          },
        ],
        'warning': <String>['bad'],
      },
    );

    expect(capability.available, isFalse);
    expect(capability.sendSupported, isFalse);
    expect(capability.receiveSupported, isFalse);
    expect(capability.maxPayloadBytes, 0);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, isNull);
    expect(sendResult.isSuccess, isFalse);
    expect(sendResult.warning, 'Native transport send failed.');
    expect(snapshot.available, isTrue);
    expect(snapshot.frames, isEmpty);
    expect(snapshot.warning, isNull);
  });

  test('native transport channel contract encodes frames', () {
    final payload = NativeTransportChannelContract.encodeFrame(
      const NativeTransportFrame(
        sessionId: 'session_1',
        senderPeerId: 'peer_a',
        recipientPeerId: 'peer_b',
        sequence: 7,
        payloadBytes: <int>[1, 2, 3, 4],
      ),
    );

    expect(payload, {
      'sessionId': 'session_1',
      'senderPeerId': 'peer_a',
      'recipientPeerId': 'peer_b',
      'sequence': 7,
      'payloadBytes': [1, 2, 3, 4],
    });
  });
}

Map<String, Object?> _loadFixture(String name) {
  final file = File('fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}
