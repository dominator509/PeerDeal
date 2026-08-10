import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../session/app_table_session_runtime.dart';

class AppTableSessionTransportHandler implements TransportFrameHandler {
  AppTableSessionTransportHandler({
    required AppTableSessionRuntime runtime,
    EventEnvelopeCodec codec = const EventEnvelopeCodec(),
    TransportFrameValidator? validator,
  }) : _runtime = runtime,
       _codec = codec,
       _validator =
           validator ??
           BasicTransportFrameValidator(maxPayloadBytes: codec.maxBytes);

  final AppTableSessionRuntime _runtime;
  final EventEnvelopeCodec _codec;
  final TransportFrameValidator _validator;
  AppTableSessionEventResult? _lastResult;

  AppTableSessionEventResult? get lastResult => _lastResult;

  @override
  Future<void> handleFrame(TransportFrame frame) async {
    if (!_validator.validate(frame).isValid) {
      throw StateError('Transport frame rejected.');
    }
    if (frame.sessionId != _runtime.state.sessionId) {
      throw StateError('Transport frame session does not match runtime.');
    }

    final EventEnvelope event;
    try {
      event = _codec.decode(frame.payload);
    } on FormatException {
      throw StateError('Transport frame event payload is malformed.');
    }
    if (event.sessionId != frame.sessionId) {
      throw StateError('Transport event session does not match frame.');
    }

    final result = _runtime.applyEvent(event);
    _lastResult = result;
    if (!result.isApplied) {
      throw StateError('Transport event rejected by session runtime.');
    }
  }
}
