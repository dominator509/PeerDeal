import 'native_transport_bridge_models.dart';

abstract interface class NativeTransportBridge {
  Future<NativeTransportCapability> getCapability();

  Future<NativeTransportSendResult> sendFrame(NativeTransportFrame frame);

  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  });
}

/// Optional per-call cancellation capability for app-owned lifecycles.
abstract interface class CancellableNativeTransportBridge {
  Future<NativeTransportCapability> getCapability({Future<void>? cancellation});

  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame, {
    Future<void>? cancellation,
  });

  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
    Future<void>? cancellation,
  });
}
