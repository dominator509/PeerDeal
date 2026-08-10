import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../session/app_holdem_table_session_runtime.dart';
import '../session/app_table_session_runtime.dart';

class AppTableSessionTransportHandler implements TransportFrameHandler {
  AppTableSessionTransportHandler({
    required AppTableSessionRuntime runtime,
    AppHoldemTableSessionRuntime? holdemRuntime,
    EventEnvelopeCodec codec = const EventEnvelopeCodec(),
    TransportFrameValidator? validator,
  }) : _runtime = runtime,
       _holdemRuntime = holdemRuntime,
       _codec = codec,
       _validator =
           validator ??
           BasicTransportFrameValidator(maxPayloadBytes: codec.maxBytes) {
    if (holdemRuntime != null &&
        !identical(holdemRuntime.sessionRuntime, runtime)) {
      throw ArgumentError(
        'Holdem transport runtime must use the supplied app session runtime.',
      );
    }
  }

  final AppTableSessionRuntime _runtime;
  final AppHoldemTableSessionRuntime? _holdemRuntime;
  final EventEnvelopeCodec _codec;
  final TransportFrameValidator _validator;
  AppTableSessionEventResult? _lastResult;

  AppTableSessionEventResult? get lastResult => _lastResult;
  AppHoldemInboundEventResult? _lastHoldemResult;

  AppHoldemInboundEventResult? get lastHoldemResult => _lastHoldemResult;

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

    final holdemRuntime = _holdemRuntime;
    if (holdemRuntime != null) {
      final result = holdemRuntime.applyRemoteEvent(event);
      _lastHoldemResult = result;
      _lastResult = result.sessionResult;
      if (!result.isApplied) {
        throw StateError('Transport event rejected by Holdem runtime.');
      }
      return;
    }

    _lastHoldemResult = null;
    final result = _runtime.applyEvent(event);
    _lastResult = result;
    if (!result.isApplied) {
      throw StateError('Transport event rejected by session runtime.');
    }
  }
}
