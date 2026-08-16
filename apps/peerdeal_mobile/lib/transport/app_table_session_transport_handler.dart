import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../session/app_holdem_table_session_runtime.dart';
import '../session/app_table_session_runtime.dart';

typedef AppTableSessionEventObserver =
    void Function(AppTableSessionEventResult result);

class AppTableSessionTransportHandler implements TransportFrameHandler {
  AppTableSessionTransportHandler({
    required AppTableSessionRuntime runtime,
    AppHoldemTableSessionRuntime? holdemRuntime,
    AppTableSessionEventObserver? onEventAccepted,
    EventEnvelopeCodec codec = const EventEnvelopeCodec(),
    TransportFrameValidator? validator,
    String? expectedRemotePeerId,
    String? expectedLocalPeerId,
  }) : _runtime = runtime,
       _holdemRuntime = holdemRuntime,
       _onEventAccepted = onEventAccepted,
       _codec = codec,
       _expectedRemotePeerId = expectedRemotePeerId,
       _expectedLocalPeerId = expectedLocalPeerId,
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
  final AppTableSessionEventObserver? _onEventAccepted;
  final EventEnvelopeCodec _codec;
  final String? _expectedRemotePeerId;
  final String? _expectedLocalPeerId;
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
    final expectedRemotePeerId = _expectedRemotePeerId;
    if (expectedRemotePeerId != null &&
        frame.fromPeerId != expectedRemotePeerId) {
      throw StateError('Transport frame sender does not match remote peer.');
    }
    final expectedLocalPeerId = _expectedLocalPeerId;
    if (expectedLocalPeerId != null && frame.toPeerId != expectedLocalPeerId) {
      throw StateError('Transport frame recipient does not match local peer.');
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
      _notifyAccepted(result.sessionResult);
      return;
    }

    _lastHoldemResult = null;
    final result = _runtime.applyEvent(event);
    _lastResult = result;
    if (!result.isApplied) {
      throw StateError('Transport event rejected by session runtime.');
    }
    _notifyAccepted(result);
  }

  void _notifyAccepted(AppTableSessionEventResult? result) {
    final observer = _onEventAccepted;
    if (observer == null || result == null) return;
    try {
      observer(result);
    } on Object {
      // Observers must not turn an already-committed event into a transport
      // rejection or roll back deterministic session state.
    }
  }
}
