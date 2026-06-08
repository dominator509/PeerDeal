import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

import 'native_transport_frame_adapter.dart';

class NativeTransportSessionFactory {
  const NativeTransportSessionFactory({
    NativeTransportBridge? bridge,
    TransportFrameValidator validator = const BasicTransportFrameValidator(),
  }) : _bridge = bridge,
       _validator = validator;

  final NativeTransportBridge? _bridge;
  final TransportFrameValidator _validator;

  TransportFrameSender createSender() {
    return ValidatingTransportFrameSender(
      sink: NativeTransportFrameSink(bridge: _resolvedBridge),
      validator: _validator,
    );
  }

  NativeTransportFrameDrain createDrain({
    required TransportFrameHandler handler,
  }) {
    return NativeTransportFrameDrain(
      bridge: _resolvedBridge,
      receiver: ValidatingTransportFrameReceiver(
        handler: handler,
        validator: _validator,
      ),
    );
  }

  NativeTransportBridge get _resolvedBridge {
    return _bridge ?? MethodChannelNativeTransportBridge();
  }
}
