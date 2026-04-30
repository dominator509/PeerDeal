import 'package:peerdeal_protocol/peerdeal_protocol.dart';

abstract interface class ReplayStateProjector<TState> {
  TState createBaseState({
    required String tableId,
    required String sessionId,
    required String protocolVersion,
  });

  TState applyEvent({
    required TState state,
    required EventEnvelope event,
  });
}
