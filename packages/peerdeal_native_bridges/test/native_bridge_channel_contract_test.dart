import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test('local network discovery snapshot owns and freezes collections', () {
    final endpoints = <String>['peer_a'];
    final interfaces = <String>['wifi'];
    final snapshot = LocalNetworkDiscoverySnapshot(
      permissionGranted: true,
      foundEndpoints: endpoints,
      interfaceHints: interfaces,
    );

    endpoints.add('peer_b');
    interfaces.add('ethernet');

    expect(snapshot.foundEndpoints, <String>['peer_a']);
    expect(snapshot.interfaceHints, <String>['wifi']);
    expect(() => snapshot.foundEndpoints.add('peer_c'), throwsUnsupportedError);
    expect(() => snapshot.interfaceHints.clear(), throwsUnsupportedError);
  });

  test('transport frame and receive snapshot own and freeze collections', () {
    final payload = <int>[1, 2, 3];
    final frame = NativeTransportFrame(
      sessionId: 'session_1',
      senderPeerId: 'peer_a',
      recipientPeerId: 'peer_b',
      sequence: 1,
      payloadBytes: payload,
    );
    final frames = <NativeTransportFrame>[frame];
    final snapshot = NativeTransportReceiveSnapshot(
      available: true,
      frames: frames,
    );

    payload.add(4);
    frames.clear();

    expect(frame.payloadBytes, <int>[1, 2, 3]);
    expect(snapshot.frames, <NativeTransportFrame>[frame]);
    expect(() => frame.payloadBytes.add(4), throwsUnsupportedError);
    expect(() => snapshot.frames.clear(), throwsUnsupportedError);
  });

  test('secure key snapshot owns and freezes key collections', () {
    final keys = <SecureKeyRecord>[
      const SecureKeyRecord(
        keyId: 'receipt_v1',
        purpose: 'receipt-signing',
        algorithm: 'hmac-sha256',
        secret: 'secret',
        active: true,
      ),
    ];
    final snapshot = SecureKeyStorageSnapshot(available: true, keys: keys);

    keys.clear();

    expect(snapshot.keys, hasLength(1));
    expect(() => snapshot.keys.clear(), throwsUnsupportedError);
  });

  test('app storage directory channel contract decodes fixture payload', () {
    final fixture = _loadFixture('app_storage_directory_bridge_contract.json');
    final methods = fixture['methods'] as Map<String, Object?>;
    final payload =
        methods[AppStorageDirectoryChannelContract.getAppSupportDirectoryMethod]
            as Map<String, Object?>;

    final snapshot =
        AppStorageDirectoryChannelContract.decodeAppSupportDirectory(payload);

    expect(fixture['channel'], AppStorageDirectoryChannelContract.channelName);
    expect(snapshot.available, isTrue);
    expect(snapshot.directoryPath, r'C:\Users\peerdeal\AppData\Local');
    expect(snapshot.warning, isNull);
  });

  test('app storage directory channel contract fails closed on bad paths', () {
    final padded = AppStorageDirectoryChannelContract.decodeAppSupportDirectory(
      const <String, Object?>{
        'available': true,
        'directoryPath': ' C:\\recovery ',
      },
    );
    final missing =
        AppStorageDirectoryChannelContract.decodeAppSupportDirectory(null);

    expect(padded.available, isFalse);
    expect(padded.directoryPath, isNull);
    expect(padded.warning, 'Native app storage directory is unavailable.');
    expect(missing.available, isFalse);
  });

  test('app storage directory channel contract bounds paths and warnings', () {
    final oversizedPath =
        AppStorageDirectoryChannelContract.decodeAppSupportDirectory(
          <String, Object?>{
            'available': true,
            'directoryPath': String.fromCharCodes(
              List<int>.filled(
                NativeBridgePayloadLimits.maxAppStoragePathBytes + 1,
                97,
              ),
            ),
            'warning': String.fromCharCodes(
              List<int>.filled(
                NativeBridgePayloadLimits.maxDiagnosticBytes + 1,
                98,
              ),
            ),
          },
        );

    expect(oversizedPath.available, isFalse);
    expect(oversizedPath.directoryPath, isNull);
    expect(
      oversizedPath.warning,
      'Native app storage directory is unavailable.',
    );

    final controlBearingPath =
        AppStorageDirectoryChannelContract.decodeAppSupportDirectory(
          <String, Object?>{
            'available': true,
            'directoryPath': 'C:\\PeerDeal\\data\u0085',
            'warning': 'storage\nwarning',
          },
        );

    expect(controlBearingPath.available, isFalse);
    expect(controlBearingPath.directoryPath, isNull);
    expect(
      controlBearingPath.warning,
      'Native app storage directory is unavailable.',
    );
  });

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

    final action = CaptureProtectionChannelContract.decodeActionResult(
      methods[CaptureProtectionChannelContract.setBlockingMethod]
          as Map<String, Object?>,
    );
    expect(action.isSuccess, isTrue);
    expect(action.blockingEnabled, isTrue);
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

    final action = CaptureProtectionChannelContract.decodeActionResult(
      const <String, Object?>{
        'success': 'true',
        'blockingEnabled': 1,
        'warning': <String>['bad'],
      },
    );
    expect(action.isSuccess, isFalse);
    expect(action.blockingEnabled, isFalse);
    expect(action.warning, isNull);
  });

  test('capture protection channel contract bounds diagnostics', () {
    final oversized = String.fromCharCodes(
      List<int>.filled(NativeBridgePayloadLimits.maxDiagnosticBytes + 1, 97),
    );
    final capability =
        CaptureProtectionChannelContract.decodeCapability(<String, Object?>{
          'blockingSupported': true,
          'obscuringSupported': true,
          'notes': oversized,
          'warning': oversized,
        });
    final action = CaptureProtectionChannelContract.decodeActionResult(
      <String, Object?>{
        'success': false,
        'blockingEnabled': false,
        'warning': oversized,
      },
    );

    expect(capability.notes, 'unavailable');
    expect(capability.warning, isNull);
    expect(action.warning, isNull);

    final controlCapability =
        CaptureProtectionChannelContract.decodeCapability(<String, Object?>{
          'blockingSupported': true,
          'obscuringSupported': true,
          'notes': 'capture\nnote',
          'warning': 'capture\u0085warning',
        });
    final controlAction = CaptureProtectionChannelContract.decodeActionResult(
      <String, Object?>{
        'success': false,
        'blockingEnabled': false,
        'warning': 'capture\u0001warning',
      },
    );

    expect(controlCapability.notes, 'unavailable');
    expect(controlCapability.warning, isNull);
    expect(controlAction.warning, isNull);
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
        'foundEndpoints': <Object?>['peer_a', 12, false, ''],
        'interfaceHints': <Object?>[
          'wifi',
          <String>['bad'],
          '',
        ],
        'warning': <String>['bad'],
      },
    );

    expect(capability.discoverySupported, isFalse);
    expect(capability.permissionPromptSupported, isFalse);
    expect(capability.broadcastSupported, isFalse);
    expect(capability.notes, 'unavailable');
    expect(capability.warning, isNull);

    expect(snapshot.permissionGranted, isFalse);
    expect(snapshot.foundEndpoints, ['peer_a']);
    expect(snapshot.interfaceHints, ['wifi']);
    expect(snapshot.warning, isNull);
  });

  test('local network channel contract bounds discovery collections', () {
    final snapshot = LocalNetworkChannelContract.decodeDiscoverySnapshot(
      <String, Object?>{
        'permissionGranted': true,
        'foundEndpoints': List<Object?>.filled(
          NativeBridgePayloadLimits.maxDiscoveryEntries + 1,
          'peer_a',
        ),
        'interfaceHints': <Object?>[
          String.fromCharCodes(
            List<int>.filled(
              NativeBridgePayloadLimits.maxDiscoveryValueBytes + 1,
              97,
            ),
          ),
          'wifi',
        ],
      },
    );

    expect(snapshot.permissionGranted, isTrue);
    expect(snapshot.foundEndpoints, isEmpty);
    expect(snapshot.interfaceHints, ['wifi']);

    final controlSnapshot = LocalNetworkChannelContract.decodeDiscoverySnapshot(
      <String, Object?>{
        'permissionGranted': true,
        'foundEndpoints': <Object?>['peer_a\nendpoint', 'peer_b'],
        'interfaceHints': <Object?>['wifi\u0085', 'ethernet'],
        'warning': 'network\nwarning',
      },
    );

    expect(controlSnapshot.permissionGranted, isTrue);
    expect(controlSnapshot.foundEndpoints, ['peer_b']);
    expect(controlSnapshot.interfaceHints, ['ethernet']);
    expect(controlSnapshot.warning, isNull);
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

  test('secure key storage channel contract rejects malformed fields', () {
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

    expect(snapshot.available, isFalse);
    expect(snapshot.warning, 'Secure key storage snapshot is invalid.');
    expect(snapshot.keys, isEmpty);
  });

  test('secure key storage channel contract bounds records and key fields', () {
    final tooManyRecords = SecureKeyStorageChannelContract.decodeSnapshot(
      <String, Object?>{
        'available': true,
        'revision': 1,
        'keys': List<Object?>.filled(
          NativeBridgePayloadLimits.maxSecureKeyRecords + 1,
          <String, Object?>{
            'keyId': 'key',
            'purpose': 'purpose',
            'algorithm': 'algorithm',
            'secret': 'secret',
            'active': true,
          },
        ),
      },
    );
    final oversizedKey = SecureKeyStorageChannelContract.decodeSnapshot(
      <String, Object?>{
        'available': true,
        'revision': 1,
        'keys': <Object?>[
          <String, Object?>{
            'keyId': 'key',
            'purpose': 'purpose',
            'algorithm': 'algorithm',
            'secret': String.fromCharCodes(
              List<int>.filled(
                NativeBridgePayloadLimits.maxSecureKeySecretBytes + 1,
                97,
              ),
            ),
            'active': true,
          },
        ],
      },
    );
    final oversizedUtf8Key = SecureKeyStorageChannelContract.decodeSnapshot(
      <String, Object?>{
        'available': true,
        'revision': 1,
        'keys': <Object?>[
          <String, Object?>{
            'keyId': 'key',
            'purpose': 'purpose',
            'algorithm': 'algorithm',
            'secret': String.fromCharCodes(
              List<int>.filled(
                NativeBridgePayloadLimits.maxSecureKeySecretBytes ~/ 4 + 1,
                0x1F600,
              ),
            ),
            'active': true,
          },
        ],
      },
    );

    expect(tooManyRecords.available, isFalse);
    expect(tooManyRecords.keys, isEmpty);
    expect(oversizedKey.available, isFalse);
    expect(oversizedKey.keys, isEmpty);
    expect(oversizedUtf8Key.available, isFalse);
    expect(oversizedUtf8Key.keys, isEmpty);
  });

  test('secure key storage channel contract rejects duplicate key ids', () {
    final snapshot = SecureKeyStorageChannelContract.decodeSnapshot(
      <String, Object?>{
        'available': true,
        'revision': 1,
        'keys': <Object?>[
          <String, Object?>{
            'keyId': 'receipt_signing_1',
            'purpose': 'receipt_signing',
            'algorithm': 'hmac-sha256',
            'secret': 'signing_secret_1',
            'active': true,
          },
          <String, Object?>{
            'keyId': 'receipt_signing_1',
            'purpose': 'receipt_signing',
            'algorithm': 'hmac-sha256',
            'secret': 'replacement_secret',
            'active': false,
          },
        ],
      },
    );

    expect(snapshot.available, isFalse);
    expect(snapshot.warning, 'Secure key storage snapshot is invalid.');
    expect(snapshot.keys, isEmpty);
  });

  test('secure key storage channel contract rejects unusable records', () {
    final snapshot = SecureKeyStorageChannelContract.decodeSnapshot(
      const <String, Object?>{
        'available': true,
        'revision': 1,
        'keys': <Object?>[
          <String, Object?>{
            'keyId': 'bad:key',
            'purpose': 'receipt_signing',
            'algorithm': 'hmac-sha256',
            'secret': 'signing_secret_1',
            'active': true,
          },
        ],
      },
    );

    expect(snapshot.available, isFalse);
    expect(snapshot.warning, 'Secure key storage snapshot is invalid.');
    expect(snapshot.keys, isEmpty);
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

  test(
    'secure key storage mutation result rejects malformed successful revisions',
    () {
      for (final revision in <Object?>[-1, 'bad']) {
        final result = SecureKeyStorageChannelContract.decodeMutationResult(
          <String, Object?>{'success': true, 'revision': revision},
        );

        expect(result.isSuccess, isFalse, reason: '$revision');
        expect(
          result.warning,
          'Secure key storage mutation result is invalid.',
          reason: '$revision',
        );
      }
    },
  );

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
            'sequence': 0,
            'payloadBytes': <int>[1],
          },
          <String, Object?>{
            'sessionId': 'session_1',
            'senderPeerId': 'peer_a',
            'recipientPeerId': 'peer_b',
            'sequence': 2,
            'payloadBytes': <Object?>[1, 'bad', 300],
          },
          <Object?, Object?>{
            _StringifyingKey('sessionId'): 'session_1',
            _StringifyingKey('senderPeerId'): 'peer_a',
            _StringifyingKey('recipientPeerId'): 'peer_b',
            _StringifyingKey('sequence'): 3,
            _StringifyingKey('payloadBytes'): <int>[1],
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

  test('native transport channel contract bounds frames and payloads', () {
    final tooManyFrames =
        NativeTransportChannelContract.decodeReceiveSnapshot(<String, Object?>{
          'available': true,
          'frames': List<Object?>.filled(
            NativeBridgePayloadLimits.maxTransportFrames + 1,
            <String, Object?>{},
          ),
        });
    final oversizedPayload =
        NativeTransportChannelContract.decodeReceiveSnapshot(<String, Object?>{
          'available': true,
          'frames': <Object?>[
            <String, Object?>{
              'sessionId': 'session_1',
              'senderPeerId': 'peer_a',
              'recipientPeerId': 'peer_b',
              'sequence': 1,
              'payloadBytes': List<int>.filled(
                NativeBridgePayloadLimits.maxTransportPayloadBytes + 1,
                1,
              ),
            },
          ],
        });
    final oversizedFrame = NativeTransportFrame(
      sessionId: 'session_1',
      senderPeerId: 'peer_a',
      recipientPeerId: 'peer_b',
      sequence: 1,
      payloadBytes: List<int>.filled(
        NativeBridgePayloadLimits.maxTransportPayloadBytes + 1,
        1,
      ),
    );

    expect(tooManyFrames.available, isFalse);
    expect(tooManyFrames.frames, isEmpty);
    expect(oversizedPayload.available, isTrue);
    expect(oversizedPayload.frames, isEmpty);
    expect(oversizedFrame.isUsable, isFalse);
    expect(NativeTransportChannelContract.encodeFrame(oversizedFrame), isEmpty);

    final controlFrame = NativeTransportChannelContract.decodeReceiveSnapshot(
      <String, Object?>{
        'available': true,
        'frames': <Object?>[
          <String, Object?>{
            'sessionId': 'session\n_1',
            'senderPeerId': 'peer_a',
            'recipientPeerId': 'peer_b',
            'sequence': 1,
            'payloadBytes': <int>[1],
          },
        ],
        'warning': 'transport\u0085warning',
      },
    );

    expect(controlFrame.available, isTrue);
    expect(controlFrame.frames, isEmpty);
    expect(controlFrame.warning, isNull);
    expect(
      NativeTransportFrame(
        sessionId: 'session\u0001_1',
        senderPeerId: 'peer_a',
        recipientPeerId: 'peer_b',
        sequence: 1,
        payloadBytes: <int>[1],
      ).isUsable,
      isFalse,
    );
  });

  test('native transport channel contract encodes frames', () {
    final payload = NativeTransportChannelContract.encodeFrame(
      NativeTransportFrame(
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

class _StringifyingKey {
  const _StringifyingKey(this.value);

  final String value;

  @override
  String toString() => value;
}
