import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

const _secureKeyNamespace = 'peerdeal.runtime_smoke';
const _secureKeyId = 'windows_host_smoke';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var captureWasEnabled = false;
  Object? failure;

  try {
    await _runSmoke(onCaptureEnabled: () => captureWasEnabled = true);
  } on Object catch (error) {
    failure = error;
    stderr.writeln('PEERDEAL_NATIVE_HOST_SMOKE_FAIL $error');
  } finally {
    if (captureWasEnabled) {
      try {
        final result = await MethodChannelCaptureProtectionBridge().setBlocking(
          enabled: false,
        );
        _require(
          result.isSuccess && !result.blockingEnabled,
          'capture release failed',
        );
        _pass('capture.release');
      } on Object catch (error) {
        failure ??= error;
        stderr.writeln('PEERDEAL_NATIVE_HOST_SMOKE_CLEANUP_FAIL $error');
      }
    }
  }

  if (failure != null) {
    await stderr.flush();
    exit(1);
  }
  stdout.writeln('PEERDEAL_NATIVE_HOST_SMOKE_PASS');
  await stdout.flush();
  exit(0);
}

Future<void> _runSmoke({required void Function() onCaptureEnabled}) async {
  final appStorage = MethodChannelAppStorageDirectoryBridge();
  final appStorageSnapshot = await appStorage.getAppSupportDirectory();
  _require(
    appStorageSnapshot.available &&
        (appStorageSnapshot.directoryPath?.trim().isNotEmpty ?? false),
    'app storage directory unavailable',
  );
  _pass('app_storage.lookup');

  final capture = MethodChannelCaptureProtectionBridge();
  final captureCapability = await capture.getCapability();
  _require(
    captureCapability.blockingSupported && captureCapability.obscuringSupported,
    'capture protection unavailable',
  );
  _pass('capture.capability');
  final captureResult = await capture.setBlocking(enabled: true);
  _require(
    captureResult.isSuccess && captureResult.blockingEnabled,
    'capture enable failed',
  );
  onCaptureEnabled();
  _pass('capture.enable');

  final localNetwork = MethodChannelLocalNetworkBridge();
  final localNetworkCapability = await localNetwork.getCapability();
  _require(
    localNetworkCapability.notes == 'windows-network-interface-ready',
    'local network interface capability unavailable',
  );
  _pass('local_network.capability');
  final discovery = await localNetwork.discoverPeers();
  _require(
    discovery.permissionGranted && discovery.foundEndpoints.isEmpty,
    'local network discovery contract failed',
  );
  _pass('local_network.discovery');

  final transport = MethodChannelNativeTransportBridge();
  final transportCapability = await transport.getCapability();
  _require(
    transportCapability.available &&
        transportCapability.sendSupported &&
        transportCapability.receiveSupported,
    'native transport capability unavailable',
  );
  _pass('transport.capability');
  final sendResult = await transport.sendFrame(
    const NativeTransportFrame(
      sessionId: 'windows_runtime_smoke',
      senderPeerId: 'peer_runtime_smoke_sender',
      recipientPeerId: 'peer_runtime_smoke_recipient',
      sequence: 1,
      payloadBytes: <int>[1, 2, 3],
    ),
  );
  if (sendResult.isSuccess) {
    _pass('transport.send');
  } else {
    _warn('transport.send', 'host network send unavailable');
  }
  final receiveSnapshot = await transport.receiveFrames(
    sessionId: 'windows_runtime_smoke',
    peerId: 'peer_runtime_smoke_recipient',
  );
  _require(receiveSnapshot.available, 'native transport receive failed');
  _pass('transport.receive');

  final keyStorage = MethodChannelSecureKeyStorageBridge();
  final conditionalStorage =
      keyStorage as ConditionalSecureKeyStorageMutationBridge;
  var snapshot = await keyStorage.loadKeyRing(namespace: _secureKeyNamespace);
  _require(snapshot.available, 'secure key storage unavailable');

  if (snapshot.keys.any((key) => key.keyId == _secureKeyId)) {
    final cleanup = await keyStorage.deleteKey(
      namespace: _secureKeyNamespace,
      keyId: _secureKeyId,
    );
    _require(cleanup.isSuccess, 'secure key smoke cleanup failed');
    snapshot = await keyStorage.loadKeyRing(namespace: _secureKeyNamespace);
    _require(snapshot.available, 'secure key storage reload unavailable');
  }
  _pass('secure_key.baseline');

  const record = SecureKeyRecord(
    keyId: _secureKeyId,
    purpose: 'runtime_smoke',
    algorithm: 'opaque',
    secret: 'windows-runtime-smoke-secret',
    active: true,
  );
  final saveResult = await keyStorage.saveKey(
    namespace: _secureKeyNamespace,
    key: record,
  );
  _require(saveResult.isSuccess, 'secure key save failed');
  final savedRevision = saveResult.revision;
  _require(
    savedRevision != null && savedRevision > snapshot.revision,
    'secure key save did not advance revision',
  );
  _pass('secure_key.save');

  final savedSnapshot = await keyStorage.loadKeyRing(
    namespace: _secureKeyNamespace,
  );
  _require(
    savedSnapshot.available &&
        savedSnapshot.revision == savedRevision &&
        savedSnapshot.keys.any(
          (key) =>
              key.keyId == record.keyId &&
              key.secret == record.secret &&
              key.active,
        ),
    'secure key read-back failed',
  );
  _pass('secure_key.read_back');

  final staleResult = await conditionalStorage.saveKeyIfRevision(
    namespace: _secureKeyNamespace,
    key: record,
    expectedRevision: snapshot.revision,
  );
  _require(
    staleResult.isConflict && !staleResult.isSuccess,
    'CAS conflict missing',
  );
  _pass('secure_key.stale_writer_conflict');

  const replacement = SecureKeyRecord(
    keyId: _secureKeyId,
    purpose: 'runtime_smoke',
    algorithm: 'opaque',
    secret: 'windows-runtime-smoke-replacement',
    active: true,
  );
  final replacementResult = await conditionalStorage.saveKeyIfRevision(
    namespace: _secureKeyNamespace,
    key: replacement,
    expectedRevision: savedSnapshot.revision,
  );
  _require(replacementResult.isSuccess, 'conditional secure key save failed');
  final replacementRevisionValue = replacementResult.revision;
  _require(
    replacementRevisionValue != null &&
        replacementRevisionValue > savedSnapshot.revision,
    'conditional secure key save did not advance revision',
  );
  final replacementRevision = replacementRevisionValue!;
  _pass('secure_key.conditional_save');

  final deleteResult = await conditionalStorage.deleteKeyIfRevision(
    namespace: _secureKeyNamespace,
    keyId: _secureKeyId,
    expectedRevision: replacementRevision,
  );
  _require(deleteResult.isSuccess, 'conditional secure key delete failed');
  _pass('secure_key.conditional_delete');
  final finalSnapshot = await keyStorage.loadKeyRing(
    namespace: _secureKeyNamespace,
  );
  _require(
    finalSnapshot.available &&
        finalSnapshot.keys.every((key) => key.keyId != _secureKeyId),
    'secure key delete read-back failed',
  );
  _pass('secure_key.delete_read_back');
}

void _pass(String checkpoint) {
  stdout.writeln('PEERDEAL_NATIVE_HOST_SMOKE_PASS $checkpoint');
}

void _warn(String checkpoint, String message) {
  stdout.writeln('PEERDEAL_NATIVE_HOST_SMOKE_WARN $checkpoint $message');
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
