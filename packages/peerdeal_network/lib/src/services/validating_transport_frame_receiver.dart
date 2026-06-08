import '../contracts/transport_frame_handler.dart';
import '../contracts/transport_frame_receiver.dart';
import '../contracts/transport_frame_validator.dart';
import '../models/transport_frame.dart';
import '../models/transport_frame_receive_result.dart';
import 'basic_transport_frame_validator.dart';

class ValidatingTransportFrameReceiver implements TransportFrameReceiver {
  const ValidatingTransportFrameReceiver({
    required TransportFrameHandler handler,
    TransportFrameValidator validator = const BasicTransportFrameValidator(),
  }) : _handler = handler,
       _validator = validator;

  final TransportFrameHandler _handler;
  final TransportFrameValidator _validator;

  @override
  Future<TransportFrameReceiveResult> receive(TransportFrame frame) async {
    final validation = _validator.validate(frame);
    if (!validation.isValid) {
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_REJECTED',
        warnings: validation.warnings,
      );
    }

    try {
      await _handler.handleFrame(frame);
    } on Object {
      return const TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_RECEIVE_FAILED',
        warnings: <String>['transport_frame_handler_failed'],
      );
    }

    return const TransportFrameReceiveResult.accepted();
  }
}
