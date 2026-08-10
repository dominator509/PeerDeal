import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_table_session_runtime.dart';
import 'package:peerdeal_mobile/transport/app_table_session_transport_provisioner.dart';
import 'package:peerdeal_mobile/transport/native_transport_session_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  test(
    'provisions a handler and scoped source from a loaded session',
    () async {
      final bridge = _FakeNativeTransportBridge(
        receiveFrames: <NativeTransportFrame>[_nativeFrame()],
      );
      final runtime = _runtime();
      final result = await AppTableSessionTransportProvisioner(
        runtime: runtime,
        nativeSessionFactory: NativeTransportSessionFactory(bridge: bridge),
        pollInterval: const Duration(milliseconds: 100),
      ).load(peerId: 'peer_b');

      expect(result.available, isTrue);
      expect(result.runtime, same(runtime));
      expect(result.handler, isNotNull);
      expect(result.session, isNotNull);
      expect(result.source, isNotNull);

      final poll = await result.source!.pollNow();
      expect(poll.available, isTrue);
      expect(poll.rejectedFrameCount, 1);
      expect(bridge.receiveLookups, 1);
    },
  );

  test(
    'rejects invalid peer identity before native capability lookup',
    () async {
      final bridge = _FakeNativeTransportBridge();
      final result = await AppTableSessionTransportProvisioner(
        runtime: _runtime(),
        nativeSessionFactory: NativeTransportSessionFactory(bridge: bridge),
      ).load(peerId: ' peer_b');

      expect(result.available, isFalse);
      expect(result.source, isNull);
      expect(result.warnings, ['Native transport peer identity is invalid.']);
      expect(bridge.capabilityLookups, 0);
    },
  );

  test(
    'fails closed when native transport capability is unavailable',
    () async {
      final bridge = _FakeNativeTransportBridge(
        capability: const NativeTransportCapability.unavailable(
          warning: 'native transport locked',
        ),
      );
      final result = await AppTableSessionTransportProvisioner(
        runtime: _runtime(),
        nativeSessionFactory: NativeTransportSessionFactory(bridge: bridge),
      ).load(peerId: 'peer_b');

      expect(result.available, isFalse);
      expect(result.source, isNull);
      expect(result.warnings, [
        'Native transport reported a platform warning.',
      ]);
    },
  );

  test('normalizes capability lookup failures', () async {
    final result = await AppTableSessionTransportProvisioner(
      runtime: _runtime(),
      nativeSessionFactory: NativeTransportSessionFactory(
        bridge: _ThrowingCapabilityTransportBridge(),
      ),
    ).load(peerId: 'peer_b');

    expect(result.available, isFalse);
    expect(result.warnings, [
      'Native transport capability could not be loaded.',
    ]);
  });
}

AppTableSessionRuntime _runtime() {
  const scope = RecoveryPersistenceScope(
    tableId: 'table_1',
    sessionId: 'session_1',
    protocolVersion: '1.0.0',
  );
  return AppTableSessionRuntime(
    initialState: TableState.initial(
      tableId: scope.tableId,
      sessionId: scope.sessionId,
      protocolVersion: scope.protocolVersion,
    ),
    closeEventAdapter: AppRecoverySessionCloseEventAdapter(
      sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
        retentionCoordinator: AppRecoveryRetentionCoordinator(
          store: InMemoryRecoveryPersistenceStore(),
        ),
        scope: scope,
        policy: _policy(),
      ),
    ),
  );
}

RetentionPolicy _policy() {
  return RetentionPolicy(
    mode: RetentionMode.timedSandbox,
    wipeSchedule: WipeSchedule(
      mode: 'timed_sandbox',
      timedWipeSeconds: 0,
      durableExportAllowed: true,
      ephemeralExportOnly: false,
    ),
    manualWipeConfirmation: const ManualWipeConfirmation(
      requiresSecondConfirmation: true,
      confirmationPhrase: 'WIPE RECEIPT',
    ),
    allowSessionRestore: true,
    allowUserRestore: false,
    disappearingPolicy: const DisappearingPolicy(
      disappearingChatEnabled: false,
      disappearingSessionMode: false,
      messageRetentionPolicy: MessageRetentionPolicy.standard,
    ),
    metadataProfile: const MetadataMinimizationProfile(
      minimizeMetadata: true,
      exportMinimalIdentity: true,
      allowPseudonymousAliases: true,
      allowDeviceIdentifiers: false,
      allowIpAddressCapture: false,
    ),
  );
}

NativeTransportFrame _nativeFrame() {
  return const NativeTransportFrame(
    sessionId: 'session_1',
    senderPeerId: 'peer_a',
    recipientPeerId: 'peer_b',
    sequence: 1,
    payloadBytes: <int>[1, 2, 3],
  );
}

class _FakeNativeTransportBridge implements NativeTransportBridge {
  _FakeNativeTransportBridge({
    this.capability = const NativeTransportCapability(
      available: true,
      sendSupported: true,
      receiveSupported: true,
      maxPayloadBytes: 4096,
      notes: 'test',
    ),
    List<NativeTransportFrame> receiveFrames = const <NativeTransportFrame>[],
  }) : _receiveFrames = receiveFrames;

  final NativeTransportCapability capability;
  final List<NativeTransportFrame> _receiveFrames;
  int capabilityLookups = 0;
  int receiveLookups = 0;

  @override
  Future<NativeTransportCapability> getCapability() async {
    capabilityLookups += 1;
    return capability;
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    receiveLookups += 1;
    return NativeTransportReceiveSnapshot(
      available: true,
      frames: _receiveFrames,
    );
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult(isSuccess: true);
  }
}

class _ThrowingCapabilityTransportBridge implements NativeTransportBridge {
  @override
  Future<NativeTransportCapability> getCapability() async {
    throw StateError('capability failed');
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    return const NativeTransportReceiveSnapshot.unavailable();
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult.failure(warning: 'unavailable');
  }
}
