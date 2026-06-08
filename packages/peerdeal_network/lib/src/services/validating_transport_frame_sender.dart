import '../contracts/transport_frame_sender.dart';
import '../contracts/transport_frame_sink.dart';
import '../contracts/transport_frame_validator.dart';
import '../models/transport_frame.dart';
import '../models/transport_frame_send_result.dart';
import 'basic_transport_frame_validator.dart';

class ValidatingTransportFrameSender implements TransportFrameSender {
  const ValidatingTransportFrameSender({
    required TransportFrameSink sink,
    TransportFrameValidator validator = const BasicTransportFrameValidator(),
  }) : _sink = sink,
       _validator = validator;

  final TransportFrameSink _sink;
  final TransportFrameValidator _validator;

  @override
  Future<TransportFrameSendResult> send(TransportFrame frame) async {
    final validation = _validator.validate(frame);
    if (!validation.isValid) {
      return TransportFrameSendResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_REJECTED',
        warnings: validation.warnings,
      );
    }

    try {
      await _sink.sendFrame(frame);
    } on Object {
      return const TransportFrameSendResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_SEND_FAILED',
        warnings: <String>['transport_frame_sink_failed'],
      );
    }

    return const TransportFrameSendResult.sent();
  }
}
