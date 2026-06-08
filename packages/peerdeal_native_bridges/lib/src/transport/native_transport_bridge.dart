import 'native_transport_bridge_models.dart';

abstract interface class NativeTransportBridge {
  Future<NativeTransportCapability> getCapability();

  Future<NativeTransportSendResult> sendFrame(NativeTransportFrame frame);

  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  });
}
